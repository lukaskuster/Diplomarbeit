import argparse
import asyncio
import websockets
from backend import recv_answer, recv_offer, send_offer, send_answer, authenticate
from aiortc import RTCPeerConnection, AudioStreamTrack, RTCConfiguration, RTCIceServer
from aiortc.mediastreams import MediaStreamError


async def run(pc, role):
    print('Connection State: ' + pc.iceConnectionState)
    print('Gathering State: ' + pc.iceGatheringState)
    print('Signaling State: ' + pc.signalingState)

    @pc.on('iceconnectionstatechange')
    def iceconnectionstatechange():
        print('Connection State: ' + pc.iceConnectionState)

    @pc.on('icegatheringstatechange')
    def icegatheringstatechange():
        print('Gathering State: ' + pc.iceGatheringState)

    @pc.on('signalingstatechange')
    def signalingstatechange():
        print('Signaling State: ' + pc.signalingState)

    if role == 'answer':
        remote_track = None

        # Define the track
        @pc.on('track')
        def on_track(track):
            nonlocal remote_track
            assert track.kind == 'audio'
            remote_track = track

        # Ice description exchange with the signaling server
        async with websockets.connect('wss://signaling.da.digitalsubmarine.com:443') as socket:
            print(type(socket))
            print('Connected')
            auth = await authenticate(socket, 'answer', 'quentin@wendegass.com', 'test123')
            if not auth['authenticated']:
                raise RuntimeError(auth['error'])

            await pc.setRemoteDescription(await recv_offer(socket))
            await pc.setLocalDescription(await pc.createAnswer())
            await send_answer(socket, pc.localDescription)

        print('Receiving audio...')
        # Receive the audio frames until the connection closes
        while True:
            done, pending = await asyncio.wait([remote_track.recv()])
            try:
                print(list(done)[0].result())
            except MediaStreamError:
                print("Connection closed!")
                break
    else:
        # Add the track to the peer connection
        pc.addTrack(AudioStreamTrack())

        # Ice description exchange with the signaling server
        async with websockets.connect('wss://signaling.da.digitalsubmarine.com:443') as socket:
            print('Connected')
            await pc.setLocalDescription(await pc.createOffer())
            await authenticate(socket, 'offer', 'quentin@wendegass.com', 'test123')
            await send_offer(socket, pc.localDescription)
            await pc.setRemoteDescription(await recv_answer(socket))

        # Send 10 seconds the audio stream
        print('Sending audio...')
        await asyncio.sleep(10)
        print('Closing connection...')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Video stream from the command line')
    parser.add_argument('role', choices=['offer', 'answer'])
    args = parser.parse_args()

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
