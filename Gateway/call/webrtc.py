import asyncio
import websockets
from backend import signaling, AuthenticationError
from aiortc.mediastreams import MediaStreamError
from utils import logger, AnsiEscapeSequence
import signal
from threading import Event
from aiortc import RTCPeerConnection, RTCIceServer, RTCConfiguration
from pyee import EventEmitter
from call.track import CallStreamTrack


class WebRTCError(Exception):
    pass


class WebRTC(EventEmitter):
    """
    Class to establish a WebRTC connection and to stream the audio to a device.
    """

    def __init__(self, username, password, host='signaling.da.digitalsubmarine.com:443'):
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

    def start_call(self, role):
        """
        Initializes a new webrtc connection.

        :param role: role of the connection
        :return: nothing
        """

        # Use google's stun server
        stun = RTCIceServer('stun:stun.l.google.com:19302')
        conf = RTCConfiguration([stun])

        # create peer connection
        peer = RTCPeerConnection(configuration=conf)

        # Raise an exception if a call is ongoing
        if self._call.is_set():
            raise WebRTCError('Only one call can be active at a time!')

        # Start the call
        self._call.set()
        asyncio.ensure_future(self._make_call(peer, role))

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

    async def _make_call(self, pc, role):
        """
        Creates a connection with the device that receives and sends the audio frames.

        :param pc: peer connection
        :param role: role of the connection
        :return: nothing
        """

        logger.debug('Connection State', 'Ice connection state set to '
                     + AnsiEscapeSequence.UNDERLINE + pc.iceConnectionState + AnsiEscapeSequence.DEFAULT)
        logger.debug('Gathering State', 'Ice gathering state set to '
                     + AnsiEscapeSequence.UNDERLINE + pc.iceGatheringState + AnsiEscapeSequence.DEFAULT)
        logger.debug('Signaling State', 'signaling state set to '
                     + AnsiEscapeSequence.UNDERLINE + pc.signalingState + AnsiEscapeSequence.DEFAULT)

        @pc.on('iceconnectionstatechange')
        def ice_connection_state_change():
            if pc.iceConnectionState == 'completed':
                self.emit('connect')

            logger.debug('Connection State', 'Ice connection state changed to '
                         + AnsiEscapeSequence.UNDERLINE + pc.iceConnectionState + AnsiEscapeSequence.DEFAULT)

        @pc.on('icegatheringstatechange')
        def ice_gathering_state_change():
            logger.debug('Gathering State', 'Ice gathering state changed to '
                         + AnsiEscapeSequence.UNDERLINE + pc.iceGatheringState + AnsiEscapeSequence.DEFAULT)

        @pc.on('signalingstatechange')
        def signaling_state_change():
            logger.debug('Signaling State', 'signaling state changed to '
                         + AnsiEscapeSequence.UNDERLINE + pc.signalingState + AnsiEscapeSequence.DEFAULT)

        # Add the track to the peer connection
        local_track = CallStreamTrack(role)
        pc.addTrack(local_track)
        logger.info('Mediatrack', 'Add local media track ({})'.format(local_track.id))

        # Set the remove track
        remote_track = None

        @pc.on('track')
        def on_track(track):
            nonlocal remote_track

            logger.info('Mediatrack', 'Received remote media track ({})'.format(track.id))
            if track.kind == 'audio':
                remote_track = track

        signaling_completed = False
        try:
            # Close the program if after 20sec the signaling process isn't finished
            def on_time_out(signum, frame):
                if signaling_completed:
                    return
                self.emit('signalingTimeout')
                logger.error('Signaling', 'Signaling process took to long!')
                exit(1)

            signal.signal(signal.SIGALRM, on_time_out)
            signal.alarm(20)

            logger.info('Connection', 'Connecting with role: ' + role + "!")

            if role == 'answer':
                # Ice description exchange with the signaling server
                async with websockets.connect('wss://' + self.host) as socket:
                    logger.info('Signaling', 'Connected with signaling server!')
                    try:
                        await signaling.authenticate(socket, 'answer', self.username, self.password)
                    except AuthenticationError:
                        logger.error('Signaling', 'Authentication failed!')
                        raise
                    logger.info('Signaling', 'Successfully authenticated!')
                    offer = await signaling.recv_offer(socket)
                    await pc.setRemoteDescription(offer)

                    await pc.setLocalDescription(await pc.createAnswer())
                    await signaling.send_answer(socket, pc.localDescription)
                    logger.info('Signaling', 'Completed signaling process!')

            else:
                # Ice description exchange with the signaling server
                async with websockets.connect('wss://' + self.host) as socket:
                    logger.info('Signaling', 'Connected with signaling server!')
                    await pc.setLocalDescription(await pc.createOffer())
                    try:
                        await signaling.authenticate(socket, 'offer', self.username, self.password)
                    except AuthenticationError:
                        logger.error('Signaling', 'Authentication failed!')
                        raise
                    logger.info('Signaling', 'Successfully authenticated!')
                    await signaling.send_offer(socket, pc.localDescription)
                    answer = await signaling.recv_answer(socket)
                    await pc.setRemoteDescription(answer)
                    logger.info('Signaling', 'Completed signaling process!')

        except Exception as e:
            logger.error('Signaling', e.args[0])
            signal.alarm(0)
            exit(1)

        # Stop timeout error
        signaling_completed = True
        signal.alarm(0)

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
            await pc.close()
            self.emit('connectionClosed')
