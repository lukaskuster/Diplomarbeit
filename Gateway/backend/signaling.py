import json
from aiortc.contrib.signaling import object_from_string, object_to_string


async def authenticate(socket, rule, username, password):
    """
    Send the authentication event to the signaling server

    :param socket: websocket client
    :param rule: rule of the connection (offer, answer)
    :param username: username of the client
    :param password: password of the client
    :type socket: object
    :type rule: str
    :type username: str
    :type password: str
    :return: boolean if the authentication is successful
    """

    # Authenticate request
    # Must contain username and password
    request = {
        'event': 'authenticate',
        'username': username,
        'password': password,
        'rule': rule
    }

    # Send the request to the signaling server
    await socket.send(json.dumps(request))

    # Get the response and parse the json string
    data = await socket.recv()
    response = json.loads(data)

    # Check if the right response arrived
    if 'event' not in response or 'authenticated' not in response:
        raise KeyError()
    if response['event'] != 'authenticate':
        raise ValueError

    # return the outcome of the authentication
    return response


async def recv_answer(socket):
    """
    Get the ice description answer of the peer client

    :param socket: websocket client
    :type socket: object
    :return: answer RTCSessionDescription
    """

    # Get the answer event from the server
    data = await socket.recv()
    response = json.loads(data)

    # Check if the right response arrived
    if 'event' not in response or 'message' not in response:
        raise KeyError()
    if response['event'] != 'answer':
        raise ValueError()

    # Convert the description string to a RTCSessionDescription object an return it
    return object_from_string(response['message'])


async def recv_offer(socket):
    """
    Get the ice description offer of the peer client

    :param socket: websocket client
    :type socket: object
    :return: offer RTCSessionDescription
    """

    # Get the offer event from the server
    data = await socket.recv()
    response = json.loads(data)

    # Check if the right response arrived
    if 'event' not in response or 'message' not in response:
        raise KeyError()
    if response['event'] != 'offer':
        raise ValueError()

    # Convert the description string to a RTCSessionDescription object an return it
    return object_from_string(response['message'])


async def send_answer(socket, desc):
    """
    Send the answer ice description to the peer client.

    :param socket: websocket client
    :param desc: RTCSessionDescription answer
    :type socket: object
    :type desc: object
    :return: nothing
    """

    # Answer event request
    request = {
        'event': 'answer',
        # message contains the description object as a json string
        'message': object_to_string(desc)
    }
    # Send the request to the server
    await socket.send(json.dumps(request))


async def send_offer(socket, desc):
    """
    Send the offer ice description to the peer client.

    :param socket: websocket client
    :param desc: RTCSessionDescription offer
    :type socket: object
    :type desc: object
    :return: nothing
    """
    # Wait for the start event, that indicates the peer client connected to the server
    data = await socket.recv()
    response = json.loads(data)

    # Check if the right response arrived
    if 'event' not in response:
        raise KeyError()
    if response['event'] != 'start':
        raise ValueError()

    # Offer event request
    request = {
        'event': 'offer',
        # message contains the description object as a json string
        'message': object_to_string(desc)
    }

    # Send the request to the server
    await socket.send(json.dumps(request))
