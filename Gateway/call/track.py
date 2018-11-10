from aiortc import AudioStreamTrack
import asyncio
import av
from utils import logger


class CallStreamTrack(AudioStreamTrack):
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
