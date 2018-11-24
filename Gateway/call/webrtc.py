import asyncio
import websockets
from backend import signaling, AuthenticationError
from aiortc.mediastreams import MediaStreamError
from utils import logger, AnsiEscapeSequence
from threading import Event
from aiortc import RTCPeerConnection, RTCIceServer, RTCConfiguration
from pyee import EventEmitter
from call.track import CallStreamTrack
from enum import IntEnum


class Role(IntEnum):
    """
    Enum for the role of the description.
    """

    OFFER = 0
    ANSWER = 1


class WebRTCError(Exception):
    pass


class WebRTC(EventEmitter):
    """
    Class to establish a WebRTC connection and to stream the audio to a device.
    """

    def __init__(self, username, password, host='localhost', signaling_timeout=10):
        """
        Construct a new 'SerialLoop' object.

        :param username: username of the gateway
        :param password: password of the gateway
        :param host: signaling server
        """

        super().__init__()

        # Events for thread safety synchronisation
        self._call = Event()
        self._running = Event()

        self.host = host
        self.username = username
        self.password = password

        self._peer_connection = None
        self._role = None
        self.signaling_timeout = signaling_timeout

    def start_call(self, role):
        """
        Initializes a new webrtc connection.

        :param role: role of the connection
        :type role: Role
        :return: nothing
        """

        # Use google's stun server
        stun = RTCIceServer('stun:stun.l.google.com:19302')
        conf = RTCConfiguration([stun])

        # create peer connection
        self._peer_connection = RTCPeerConnection(configuration=conf)
        self._role = role

        # Raise an exception if a call is ongoing
        if self._call.is_set():
            raise WebRTCError('Only one call can be active at a time!')

        # Start the call
        self._call.set()

        asyncio.ensure_future(self._make_call())

    def stop_call(self):
        """
        Closes the webrtc connection.

        :return: nothing.
        """

        # Stop the call
        self._call.clear()

    def is_ongoing(self):
        """
        Check if the webrtc connection is ongoing.

        :return: ongoing connection
        :rtype: bool
        """

        return self._call.is_set()

    async def _log_signaling_states(self):
        """
        Logs the state of ice-, gathering-, and signal connection, when the state changes.

        :return: nothing
        """

        logger.debug('Connection State', 'Ice connection state set to ' + AnsiEscapeSequence.UNDERLINE +
                     self._peer_connection.iceConnectionState + AnsiEscapeSequence.DEFAULT)
        logger.debug('Gathering State', 'Ice gathering state set to ' + AnsiEscapeSequence.UNDERLINE +
                     self._peer_connection.iceGatheringState + AnsiEscapeSequence.DEFAULT)
        logger.debug('Signaling State', 'signaling state set to '
                     + AnsiEscapeSequence.UNDERLINE + self._peer_connection.signalingState + AnsiEscapeSequence.DEFAULT)

        @self._peer_connection.on('iceconnectionstatechange')
        def ice_connection_state_change():
            if self._peer_connection.iceConnectionState == 'completed':
                self.emit('connect')

            logger.debug('Connection State', 'Ice connection state changed to ' + AnsiEscapeSequence.UNDERLINE +
                         self._peer_connection.iceConnectionState + AnsiEscapeSequence.DEFAULT)

        @self._peer_connection.on('icegatheringstatechange')
        def ice_gathering_state_change():
            logger.debug('Gathering State', 'Ice gathering state changed to ' + AnsiEscapeSequence.UNDERLINE +
                         self._peer_connection.iceGatheringState + AnsiEscapeSequence.DEFAULT)

        @self._peer_connection.on('signalingstatechange')
        def signaling_state_change():
            logger.debug('Signaling State', 'signaling state changed to ' + AnsiEscapeSequence.UNDERLINE +
                         self._peer_connection.signalingState + AnsiEscapeSequence.DEFAULT)

    async def _signaling_authenticate(self, socket):
        """
        Authenticates with the signaling server.

        :param socket: websocket
        :return: nothing
        """

        logger.info('Signaling', 'Connected with signaling server!')
        try:
            await signaling.authenticate(socket, self._role, self.username, self.password)
        except AuthenticationError:
            raise

        logger.info('Signaling', 'Successfully authenticated!')

    async def _signaling_offer(self, socket):
        """
        Sends the offer to the device and gets back the answer.

        :param socket: websocket
        :return: nothing
        """

        await self._peer_connection.setLocalDescription(await self._peer_connection.createOffer())
        await signaling.send_offer(socket, self._peer_connection.localDescription)
        answer = await signaling.recv_answer(socket)
        await self._peer_connection.setRemoteDescription(answer)

    async def _signaling_answer(self, socket):
        """
        Gets the offer sdp from the device and sends back the answer.

        :param socket: websocket
        :return: nothing
        """

        offer = await signaling.recv_offer(socket)
        await self._peer_connection.setRemoteDescription(offer)

        await self._peer_connection.setLocalDescription(await self._peer_connection.createAnswer())
        await signaling.send_answer(socket, self._peer_connection.localDescription)

    async def _exchange_sdp(self, socket):
        """
        Exchanges the sdp from device and gateway.

        :param socket: websocket
        :return: nothing
        """

        # Ice description exchange with the signaling server
        try:
            await self._signaling_authenticate(socket)
        except AuthenticationError:
            raise

        if self._role == Role.ANSWER:
            await self._signaling_answer(socket)
        else:
            await self._signaling_offer(socket)

        logger.info('Signaling', 'Completed signaling process!')

    async def _make_call(self):
        """
        Creates a connection with the device that receives and sends the audio frames.

        :return: nothing
        """

        print(self._peer_connection.localDescription)

        await self._log_signaling_states()

        # Add the track to the peer connection
        local_track = CallStreamTrack()
        self._peer_connection.addTrack(local_track)
        logger.info('Mediatrack', 'Add local media track ({})'.format(local_track.id))

        # Set the remove track
        remote_track = None

        @self._peer_connection.on('track')
        def on_track(track):
            nonlocal remote_track

            logger.info('Mediatrack', 'Received remote media track ({})'.format(track.id))
            if track.kind == 'audio':
                remote_track = track

        async with websockets.connect('wss://' + self.host) as socket:
            try:
                error = await asyncio.wait_for(self._exchange_sdp(socket), timeout=self.signaling_timeout)
                print(error)
            except asyncio.TimeoutError:
                logger.error('Signaling', 'Signaling process timed out after {} seconds!'.format(self.signaling_timeout))
                self._call.clear()
                return
            except AuthenticationError:
                self._call.clear()
                return

            finally:
                socket.close()

        # Receive and send the media tracks until the connection closes
        try:
            while True:
                done, pending = await asyncio.wait([remote_track.recv()])
                # Received frame
                frame = list(done)[0].result()
                logger.log('Mediatrack', 'Received frame (samples: {}, sample_rate: {})'
                           .format(frame.samples, frame.sample_rate))

                if not self._call.is_set():
                    raise MediaStreamError('local')
        except MediaStreamError as err:
            if err.args == 'local':
                logger.info('Connection', 'Peer connection closed from local client!')
            else:
                logger.info('Connection', 'Peer connection closed from remote client!')
                self._call.clear()
            await self._peer_connection.close()
            self.emit('connectionClosed')
