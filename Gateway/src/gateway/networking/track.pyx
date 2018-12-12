from aiortc import AudioStreamTrack
import asyncio
import av
from gateway.utils import logger
from gateway.utils import config
import os


class CallStreamTrack(AudioStreamTrack):
    def __init__(self):
        super().__init__()
        container = av.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), config['Test']['audiofile']))
        self.frames = container.decode()

    # Send a frame to the peer connection
    async def recv(self):
        frame = next(self.frames)
        logger.log('Mediatrack', 'Sending frame (samples: {}, sample_rate: {}, format: {}, pts: {}, rate: {}, time: {}. planes: {}, index: {}, layout: {}, dts: {})'
                   .format(frame.samples, frame.sample_rate, frame.format.name, frame.pts, frame.rate, frame.time, frame.planes, frame.index, frame.layout, frame.dts))
        await asyncio.sleep(1 / (frame.sample_rate / frame.samples))
        return frame
