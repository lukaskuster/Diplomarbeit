import asyncio
from enum import IntEnum
from threading import Event

import websockets
from aiortc import RTCPeerConnection, RTCIceServer, RTCConfiguration, RTCRtpSender, RTCRtpReceiver
from aiortc.mediastreams import MediaStreamError
from pyee import EventEmitter

from gateway.networking import signaling, AuthenticationError
from gateway.networking.track import CallStreamTrack
from gateway.utils import logger, AnsiEscapeSequence
from gateway.io import PCM


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

    def __init__(self, username, password, gateway_imei, host='localhost', signaling_timeout=10, webrtc_timeout=10, debug=False):
        """
        Construct a new 'SerialLoop' object.

        :param username: username of the gateway
        :param password: password of the gateway
        :param host: signaling server
        """

        RTCRtpSender.disableEncoding = True
        RTCRtpReceiver.disableDecoding = True

        super().__init__()

        # Events for thread safety synchronisation
        self._call = Event()
        self._running = Event()

        self.host = host
        self.username = username
        self.password = password

        self._peer_connection = None
        self._role = None
        self._recv_ice_candidates = True
        self.signaling_timeout = signaling_timeout
        self.webrtc_timeout = webrtc_timeout
        self._gateway_imei = gateway_imei

        # Don't include the pcm module in debug mode
        if not debug:
            self.pcm = PCM()
        else:
            self.pcm = None
        self.debug = debug

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

        # Set local audio track
        local_track = CallStreamTrack(self.pcm)
        self._peer_connection.addTrack(local_track)
        logger.info('Mediatrack', 'Add local media track ({})'.format(local_track.id))

        self._set_audio_codec()

        # Raise an exception if a call is ongoing
        if self._call.is_set():
            raise WebRTCError('Only one call can be active at a time!')

        # Start the call
        self._call.set()

        asyncio.ensure_future(self._make_call())

    def _set_audio_codec(self):
        """
        Sets PCMU/PCMA audio encoding/decoding to the PeerConnection.

        :return: nothing
        """

        capabilities = RTCRtpSender.getCapabilities('audio')
        preferences = list(filter(lambda x: x.name == 'PCMA', capabilities.codecs))
        transceiver = self._peer_connection.getTransceivers()[0]
        transceiver.setCodecPreferences(preferences)

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
                self.emit('connected')

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
            await signaling.authenticate(socket, self._role, self.username, self.password, self._gateway_imei)
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

    def _on_new_ice_candidate(self, task):
        """
        Add a new ice candidate if one is send from the peer connection.

        :param task: finished task
        :return: nothing
        """

        try:
            error, candidate, socket = task.result()
        except websockets.ConnectionClosed:
            return

        if not error:
            self._peer_connection.addIceCandidate(candidate)

        resv_ice_task = asyncio.ensure_future(signaling.resv_ice_candidate(socket))
        resv_ice_task.add_done_callback(self._on_new_ice_candidate)

    async def _make_call(self):
        """
        Creates a connection with the device that receives and sends the audio frames.

        :return: nothing
        """

        await self._log_signaling_states()

        # Set the remote track
        remote_track = None

        @self._peer_connection.on('track')
        def on_track(track):
            nonlocal remote_track

            logger.info('Mediatrack', 'Received remote media track ({})'.format(track.id))
            if track.kind == 'audio':
                remote_track = track

        # Do Signaling
        async with websockets.connect(self.host) as socket:
            try:
                await asyncio.wait_for(self._exchange_sdp(socket), timeout=self.signaling_timeout)
            except asyncio.TimeoutError:
                logger.error('Signaling', 'TimeoutError'
                             .format(self.signaling_timeout))
                self.emit("timeoutError")
                self._call.clear()
                return
            except AuthenticationError:
                self.emit("authenticationError")
                self._call.clear()
                return

            # Create new task to add new received ice candidates
            resv_ice_task = asyncio.ensure_future(signaling.resv_ice_candidate(socket))
            resv_ice_task.add_done_callback(self._on_new_ice_candidate)

            # Receive and send the audio frames until the connection closes
            try:
                while True:

                    try:
                        frame = await asyncio.wait_for(remote_track.recv(), timeout=self.webrtc_timeout)
                    except asyncio.TimeoutError:
                        raise MediaStreamError('local')

                    logger.debug('Mediatrack', 'Receiving frame (samples: {}, timestamp (pts): {})'
                                 .format(len(frame.data), frame.timestamp))

                    # Write the samples of the frame to the pcm interface
                    if not self.debug:
                        self.pcm.write_frame(frame.data)

                    if not self._call.is_set():
                        raise MediaStreamError('local')

            except MediaStreamError as err:
                if not self.debug:
                    self.pcm.disable()

                if err.args == ('local', ):
                    logger.info('Connection', 'Peer connection closed from local client!')
                else:
                    logger.info('Connection', 'Peer connection closed from remote client!')
                    self._call.clear()
                await self._peer_connection.close()
                self.emit('connectionClosed')
