import json

import attr
from aioice import Candidate
from aiortc import RTCSessionDescription
from aiortc.rtcicetransport import candidate_from_aioice
from websockets import WebSocketClientProtocol

from gateway.utils import logger, AnsiEscapeSequence


class AuthenticationError(Exception):
    pass


def from_ice_candidate(candidate):
    return attr.asdict(candidate)


def to_ice_candidate(ice):
    x = Candidate.from_sdp(ice)
    candidate = candidate_from_aioice(x)
    candidate.sdpMid = 'audio'
    return candidate


async def authenticate(socket, role, username, password, gateway):
    """
    Send the authentication event to the signaling server

    :param socket: websocket client
    :param role: rule of the connection (offer, answer)
    :param username: username of the client
    :param password: password of the client
    :type socket: object
    :type role: Role
    :type username: str
    :type password: str
    :return: nothing
    """

    # Check parameter types
    if not isinstance(socket, WebSocketClientProtocol):
        error = TypeError('Socket must be of type WebSocketClientProtocol!')
        logger.info('Signaling', error.args[0])
        raise error

    # Authenticate request
    # Must contain username and password
    request = {
        'event': 'authenticate',
        'username': username,
        'password': password,
        'role': int(role),
        'gateway': gateway
    }

    # Send the request to the signaling server
    await socket.send(json.dumps(request))

    # Get the response and parse the json string
    data = await socket.recv()
    response = json.loads(data)

    # Check if the right response arrived
    if 'event' not in response or 'authenticated' not in response:
        error = KeyError('Event or authenticated is missing in response: ' + str(response))
        logger.error('Signaling', 'ArgumentError')
        raise error
    if response['event'] != 'authenticate':
        error = ValueError('Event should be authenticate! Event: ' + response['event'])
        logger.error('Signaling', 'EventError(authenticate)')
        raise error

    if not response['authenticated']:
        if 'error' in response:
            error = AuthenticationError('Authentication was not successful: ' + response['error'])
        else:
            error = AuthenticationError('Authentication was not successful: ')
        logger.error('Signaling', 'AuthenticationError')
        raise error


async def resv_ice_candidate(socket):
    """
    Waits for the socket to send an ice candidate.

    :param socket: websocket client
    :return: tuple of error and ice candidate
    """

    # Check parameter types
    if not isinstance(socket, WebSocketClientProtocol):
        raise TypeError('Socket must be of type WebSocketClientProtocol!')

    # Get the event from the server
    data = await socket.recv()
    response = json.loads(data)

    # Check if the right response arrived
    if 'event' not in response or 'ice' not in response:
        error = KeyError('Event or ice is missing in response: ' + str(response))
        logger.error('Signaling', 'ArgumentError')
        return error, None, socket
    if response['event'] != 'sendIce':
        error = ValueError('Event should be sendIce! Event: ' + response['event'])
        logger.error('Signaling', 'EventError(sendIce)')
        return error, None, socket

    logger.debug('Signaling', 'Received ice candidate:\n' + AnsiEscapeSequence.HEADER
                 + response['ice'] + AnsiEscapeSequence.DEFAULT)

    # Create a RTCIceCandidate object an return it
    return None, to_ice_candidate(response['ice']), socket


async def recv_answer(socket):
    """
    Get the ice description answer of the peer client

    :param socket: websocket client
    :type socket: object
    :return: answer RTCSessionDescription
    """

    # Check parameter types
    if not isinstance(socket, WebSocketClientProtocol):
        raise TypeError('Socket must be of type WebSocketClientProtocol!')

    # Get the answer event from the server
    data = await socket.recv()
    response = json.loads(data)

    # Check if the right response arrived
    if 'event' not in response or 'sdp' not in response:
        error = KeyError('Event or sdp is missing in response: ' + str(response))
        logger.error('Signaling', 'ArgumentError')
        raise error
    if response['event'] != 'answer':
        error = ValueError('Event should be answer! Event: ' + response['event'])
        logger.error('Signaling', 'EventError(answer)')
        raise error

    logger.debug('Signaling', 'Received answer with sdp:\n' + AnsiEscapeSequence.HEADER
                 + response['sdp'] + AnsiEscapeSequence.DEFAULT)

    # Create a RTCSessionDescription object an return it
    return RTCSessionDescription(type=response['event'], sdp=response['sdp'])


async def recv_offer(socket):
    """
    Get the ice description offer of the peer client

    :param socket: websocket client
    :type socket: object
    :return: offer RTCSessionDescription
    """

    # Check parameter type
    if not isinstance(socket, WebSocketClientProtocol):
        error = TypeError('Socket must be of type WebSocketClientProtocol!')
        logger.info('Signaling', error.args[0])
        raise error

    # Get the offer event from the server
    data = await socket.recv()

    if data == '':
        data = await socket.recv()

    response = json.loads(data)

    # Check if the right response arrived
    if 'event' not in response or 'sdp' not in response:
        error = KeyError('Event or sdp is missing in response: ' + str(response))
        logger.error('Signaling', 'ArgumentError')
        raise error
    if response['event'] != 'offer':
        error = ValueError('Event should be offer! Event: ' + response['event'])
        logger.error('Signaling', 'EventError(offer)')
        raise error

    logger.debug('Signaling', 'Received offer with sdp:\n' + AnsiEscapeSequence.HEADER
                 + response['sdp'] + AnsiEscapeSequence.DEFAULT)

    # Create a RTCSessionDescription object an return it
    return RTCSessionDescription(type=response['event'], sdp=response['sdp'])


async def send_answer(socket, desc):
    """
    Send the answer ice description to the peer client.

    :param socket: websocket client
    :param desc: RTCSessionDescription answer
    :type socket: object
    :type desc: object
    :return: nothing
    """

    # Check parameter types
    if not isinstance(desc, RTCSessionDescription):
        error = TypeError('Description must be of type RTCSessionDescription!')
        logger.info('Signaling', error.args[0])
        raise error

    if not isinstance(socket, WebSocketClientProtocol):
        error = TypeError('Socket must be of type WebSocketClientProtocol!')
        logger.info('Signaling', error.args[0])
        raise error

    # Answer event request
    request = {
        'event': 'answer',
        # message contains the description object as a json string
        'sdp': desc.sdp
    }

    # Send the request to the server
    await socket.send(json.dumps(request))

    logger.debug('Signaling', 'Send answer with sdp:\n' + AnsiEscapeSequence.HEADER
                 + desc.sdp + AnsiEscapeSequence.DEFAULT)


async def send_offer(socket, desc):
    """
    Send the offer ice description to the peer client.

    :param socket: websocket client
    :param desc: RTCSessionDescription offer
    :type socket: object
    :type desc: object
    :return: nothing
    """

    # Check parameter types
    if not isinstance(desc, RTCSessionDescription):
        error = TypeError('Description must be of type RTCSessionDescription!')
        logger.info('Signaling', error.args[0])
        raise error

    if not isinstance(socket, WebSocketClientProtocol):
        error = TypeError('Socket must be of type WebSocketClientProtocol!')
        logger.info('Signaling', error.args[0])
        raise error

    # Wait for the start event, that indicates the peer client connected to the server
    data = await socket.recv()

    if data == '':
        data = await socket.recv()

    response = json.loads(data)

    # Check if the right response arrived
    if 'event' not in response:
        error = KeyError('Event is missing in response: ' + str(response))
        logger.error('Signaling', 'ArgumentError')
        raise error

    if response['event'] != 'start':
        error = ValueError('Event should be start! Event: ' + response['event'])
        logger.error('Signaling', 'EventError(start)')
        raise error

    # Offer event request
    request = {
        'event': 'offer',
        # sdp contains the description object as a json string
        'sdp': desc.sdp
    }

    # Send the request to the server
    await socket.send(json.dumps(request))

    logger.debug('Signaling', 'Send offer with sdp:\n' + AnsiEscapeSequence.HEADER
                 + desc.sdp + AnsiEscapeSequence.DEFAULT)
