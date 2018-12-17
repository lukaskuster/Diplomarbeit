# cython: language_level=3

import asyncio

import av
from aiortc import AudioStreamTrack

from gateway.core import get_config
from gateway.utils import logger


class CallStreamTrack(AudioStreamTrack):
    def __init__(self):
        super().__init__()
        container = av.open(get_config()['Test']['audiofile'])
        self.frames = container.decode()

    # Send a frame to the peer connection
    async def recv(self):
        frame = next(self.frames)
        logger.log('Mediatrack', 'Sending frame (samples: {}, sample_rate: {}, format: {}, pts: {}, '
                                 'rate: {}, time: {}. planes: {}, index: {}, layout: {}, dts: {})'
                   .format(frame.samples, frame.sample_rate, frame.format.name, frame.pts, frame.rate,
                           frame.time, frame.planes, frame.index, frame.layout, frame.dts))
        await asyncio.sleep(1 / (frame.sample_rate / frame.samples))
        return frame
