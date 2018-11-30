from aiortc import AudioStreamTrack
import asyncio
import av
from utils import logger
import utils.config


class CallStreamTrack(AudioStreamTrack):
    def __init__(self):
        super().__init__()
        container = av.open(utils.config.config['Test']['audiofile'])
        self.frames = container.decode()

    # Send a frame to the peer connection
    async def recv(self):
        frame = next(self.frames)
        logger.log('Mediatrack', 'Sending frame (samples: {}, sample_rate: {})'
                   .format(frame.samples, frame.sample_rate))
        await asyncio.sleep(frame.samples / frame.sample_rate)
        return frame
