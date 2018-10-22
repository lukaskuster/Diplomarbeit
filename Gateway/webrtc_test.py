import argparse
import asyncio
import logging
import websockets
import backend.signaling as signaling
from aiortc import RTCPeerConnection, AudioStreamTrack
from aiortc.contrib.signaling import add_signaling_arguments


async def run(pc, role):
    if role == 'answer':
        remote_track = None

        @pc.on('track')
        def on_track(track):
            nonlocal remote_track
            assert track.kind == 'audio'
            remote_track = track

        async with websockets.connect('wss://signaling.da.digitalsubmarine.com:443') as socket:
            print('Connected')
            await signaling.authenticate(socket, 'answer')
            await pc.setRemoteDescription(await signaling.recv_offer(socket))
            await pc.setLocalDescription(await pc.createAnswer())
            await signaling.send_answer(socket, pc.localDescription)

            print('Receiving audio...')
            while True:
                done, pending = await asyncio.wait([remote_track.recv()])
                print(list(done)[0].result())
    else:
        pc.addTrack(AudioStreamTrack())

        async with websockets.connect('wss://signaling.da.digitalsubmarine.com:443') as socket:
            await pc.setLocalDescription(await pc.createOffer())
            await signaling.authenticate(socket, 'offer')
            await signaling.send_offer(socket, pc.localDescription)
            await pc.setRemoteDescription(await signaling.recv_answer(socket))

        print('Sending audio...')
        await asyncio.sleep(10)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Video stream from the command line')
    parser.add_argument('role', choices=['offer', 'answer'])
    parser.add_argument('--record-to', help='Write received media to a file.'),
    parser.add_argument('--verbose', '-v', action='count')
    add_signaling_arguments(parser)
    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)

    # create peer connection
    pc = RTCPeerConnection()

    # run event loop
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(run(
            pc=pc,
            role=args.role))
    except KeyboardInterrupt:
        pass
    finally:
        # cleanup
        loop.run_until_complete(pc.close())