import asyncio
import time
import fractions

from av import AudioFrame
from aiortc import AudioStreamTrack

from gateway.utils import logger


SAMPLE_RATE = 8000

# 20ms audio packetization
AUDIO_PTIME = 0.020

# Samples per frame
FRAME_SAMPLES = int(AUDIO_PTIME * SAMPLE_RATE)


class CallStreamTrack(AudioStreamTrack):
    """
    WebRTC audio track that gets send to the remote peer.
    """

    def __init__(self, pcm):
        super().__init__()
        # Start time of the transmission to calculate the wait time
        self._start = 0

        # The pcm module to read samples from the driver buffer
        self.pcm = pcm

        # Configure a standard frame:
        # Sample rate - 8kHz
        # Sample length - 8bit
        # 1 Channel
        frame = AudioFrame(format='u8', layout='mono', samples=FRAME_SAMPLES)
        frame.sample_rate = SAMPLE_RATE
        frame.time_base = fractions.Fraction(1, SAMPLE_RATE)
        self.frame = frame

        # Only for testing the track without the pcm module
        self.count = 0

    # Send a frame to the peer connection
    async def recv(self):
        """
        Gets called when a new audio frame gets send to the remote peer.
        This method must return a audio frame that is g.711 encoded.

        :return: audio frame
        """

        if hasattr(self, '_timestamp'):
            # Increase the timestamp and wait if needed, to keep everything sync
            self._timestamp += FRAME_SAMPLES
            wait = self._start + (self._timestamp / SAMPLE_RATE) - time.time()
            if wait > 0:
                await asyncio.sleep(wait)
        else:
            # Gets called on the first execution
            self._start = time.time()

            # Timestamp for the audio frame measured in samples
            self._timestamp = 0

            # Enable the pcm bus
            if self.pcm is not None:
                self.pcm.enable()

        # Only for testing without the pcm module
        if self.pcm is None:
            if self.count > 255:
                self.count = 0

            self.frame.planes[0].update(bytearray([self.count for i in range(FRAME_SAMPLES)]))

            # self.count += 1
        else:
            # Get the amount of samples a frame can hold from the pcm interface
            frame_data = self.pcm.read_frame()

            if frame_data is None:
                # If there are no new samples send silence for now
                self.frame.planes[0].update(bytes(FRAME_SAMPLES))
            else:
                # Fill the buffer in the frame with the pcm samples
                self.frame.planes[0].update(frame_data)

        # Include the timestamp in the frame
        self.frame.pts = self._timestamp

        logger.log('Mediatrack', 'Sending frame (samples: {}, sample_rate: {}, format: {}, pts: {}, '
                                 'rate: {}, time: {}. planes: {}, index: {}, layout: {}, dts: {})'
                   .format(self.frame.samples, self.frame.sample_rate, self.frame.format.name, self.frame.pts,
                           self.frame.rate,
                           self.frame.time, self.frame.planes, self.frame.index, self.frame.layout, self.frame.dts))

        return self.frame
