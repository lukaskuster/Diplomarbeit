import argparse
import asyncio
import websockets
from backend import recv_answer, recv_offer, send_offer, send_answer, authenticate
from aiortc import RTCPeerConnection, AudioStreamTrack, RTCConfiguration, RTCIceServer
from aiortc.mediastreams import MediaStreamError
import av
from utils import logger, AnsiEscapeSequence, Level
import signal

# Set log level to debug
logger.level = Level.DEBUG


class TestAudioStreamTrack(AudioStreamTrack):
    def __init__(self, rule):
        super().__init__()
        if rule == 'answer':
            container = av.open('test_files/music.wav')
        else:
            container = av.open('test_files/speech.wav')

        self.frames = container.decode()

    # Send a frame to the peer connection
    async def recv(self):
        frame = next(self.frames)
        logger.log('Mediatrack', 'Sending frame (samples: {}, sample_rate: {})'
                   .format(frame.samples, frame.sample_rate))
        await asyncio.sleep(frame.samples / frame.sample_rate)
        return frame


async def run(pc, role):
    logger.debug('Connection State', 'Ice connection state set to '
                 + AnsiEscapeSequence.UNDERLINE + pc.iceConnectionState + AnsiEscapeSequence.DEFAULT)
    logger.debug('Gathering State', 'Ice gathering state set to '
                 + AnsiEscapeSequence.UNDERLINE + pc.iceGatheringState + AnsiEscapeSequence.DEFAULT)
    logger.debug('Signaling State', 'signaling state set to '
                 + AnsiEscapeSequence.UNDERLINE + pc.signalingState + AnsiEscapeSequence.DEFAULT)

    @pc.on('iceconnectionstatechange')
    def ice_connection_state_change():
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
    local_track = TestAudioStreamTrack(role)
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
            logger.error('Signaling', 'Signaling process took to long!')
            exit(1)
        signal.signal(signal.SIGALRM, on_time_out)
        signal.alarm(20)

        logger.info('Connection', 'Connecting with role: ' + role + "!")

        if role == 'answer':
            # Ice description exchange with the signaling server
            async with websockets.connect('wss://signaling.da.digitalsubmarine.com:443') as socket:
                logger.info('Signaling', 'Connected with signaling server!')
                auth = await authenticate(socket, 'answer', 'quentin@wendegass.com', 'test123')
                if not auth['authenticated']:
                    logger.error('Signaling', 'Authentication failed!')
                    raise RuntimeError(auth['error'])
                logger.info('Signaling', 'Successfully authenticated!')
                offer = await recv_offer(socket)
                logger.debug('Signaling', 'Received offer with sdp:\n' + AnsiEscapeSequence.HEADER
                             + offer.sdp + AnsiEscapeSequence.DEFAULT)
                await pc.setRemoteDescription(offer)

                await pc.setLocalDescription(await pc.createAnswer())
                await send_answer(socket, pc.localDescription)
                logger.debug('Signaling', 'Send answer with sdp:\n' + AnsiEscapeSequence.HEADER
                             + pc.localDescription.sdp + AnsiEscapeSequence.DEFAULT)
                logger.info('Signaling', 'Completed signaling process!')

        else:
            # Ice description exchange with the signaling server
            async with websockets.connect('wss://signaling.da.digitalsubmarine.com:443') as socket:
                logger.info('Signaling', 'Connected with signaling server!')
                await pc.setLocalDescription(await pc.createOffer())
                auth = await authenticate(socket, 'offer', 'quentin@wendegass.com', 'test123')
                if not auth['authenticated']:
                    logger.error('Signaling', 'Authentication failed!')
                    raise RuntimeError(auth['error'])
                logger.info('Signaling', 'Successfully authenticated!')
                await send_offer(socket, pc.localDescription)
                logger.debug('Signaling', 'Send offer with sdp:\n' + AnsiEscapeSequence.HEADER
                             + pc.localDescription.sdp + AnsiEscapeSequence.DEFAULT)
                answer = await recv_answer(socket)
                logger.debug('Signaling', 'Received answer with sdp:\n' + AnsiEscapeSequence.HEADER
                             + answer.sdp + AnsiEscapeSequence.DEFAULT)
                await pc.setRemoteDescription(answer)
    except Exception as e:
        logger.error('Signaling', e.args[0])
        exit(1)

    # Stop timeout error
    signaling_completed = True

    # Receive and send the media tracks until the connection closes
    while True:
        done, pending = await asyncio.wait([remote_track.recv()])
        try:
            # Received frame
            frame = list(done)[0].result()
            logger.log('Mediatrack', 'Received frame (samples: {}, sample_rate: {})'
                       .format(frame.samples, frame.sample_rate))
        except MediaStreamError:
            logger.info('Connection', 'Peer Connection closed!')
            break


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Audio stream from the command line')
    parser.add_argument('role', choices=['offer', 'answer'])
    args = parser.parse_args()

    # Use google's stun server
    stun = RTCIceServer('stun:stun.l.google.com:19302')
    conf = RTCConfiguration([stun])

    # create peer connection
    peer = RTCPeerConnection(configuration=conf)

    # run event loop
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(run(
            pc=peer,
            role=args.role))
    except KeyboardInterrupt:
        pass
    finally:
        # cleanup
        loop.run_until_complete(peer.close())
