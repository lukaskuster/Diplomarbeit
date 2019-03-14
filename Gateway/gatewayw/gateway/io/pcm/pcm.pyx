# cython: language_level=3
# distutils: sources = lib/pcmlib/pcmlib.c
# distutils: include_dirs = lib/pcmlib/

from gateway.io.pcm cimport cpcmlib
from cpython.bytes cimport PyBytes_FromStringAndSize

from gateway.io.pcm import ModeControlRegister, CHANNEL, BAUD_RATE
from gateway.utils import logger

import pigpio


cdef class PCM:
    """
    Wrapper class for the c library.
    """

    def __cinit__(self):
        """
        Gets called before the python object is build.
        Because of that don't try to interact with the object in this method.

        :return: nothing
        """

        ret = cpcmlib.alloc_clk()
        if ret < 0:
            raise MemoryError('CLK could not be allocated! Error code: {}'.format(ret))

    def _power_up(self):
        connection = pigpio.pi()

        if not connection.connected:
            logger.error('PCM', 'SPIConnectionError')
            raise ConnectionError

        handler = connection.spi_open(CHANNEL, BAUD_RATE, pigpio.SPI_MODE_0)
        mode_control_register = ModeControlRegister()

        mode_control_register.PD = 0
        mode_control_register.write(connection, handler)

        logger.info('PCM', 'Set PD bit to 0!')

        connection.spi_close(handler)

        connection.stop()

    def _power_down(self):
        connection = pigpio.pi()

        if not connection.connected:
            return logger.error('PCM', 'SPIConnectionError')

        handler = connection.spi_open(CHANNEL, BAUD_RATE, pigpio.SPI_MODE_0)

        mode_control_register = ModeControlRegister()

        mode_control_register.PD = 1
        mode_control_register.write(connection, handler)

        logger.info('PCM', 'Set PD bit to 1!')

        connection.spi_close(handler)

        connection.stop()

    def enable(self):
        cpcmlib.enable_clk()

        self._power_up()

        ret = cpcmlib.enable_pcm()

        if ret < 0:
            return logger.error('PCM', 'EnablePCMError({})'.format(ret))


    def disable(self):
        ret = cpcmlib.disable_pcm()

        if ret < 0:
            logger.error('PCM', 'DisablePCMError({})'.format(ret))

        self._power_down()

        cpcmlib.disable_clk()

    def write_frame(self, samples):
        if cpcmlib.write_frame(samples) < 0:
            logger.info('PCM', 'Could not write samples!')

    cpdef read_frame(self):
        cdef char * samples = cpcmlib.read_frame()

        if samples is NULL:
            logger.info('PCM', 'Could not read samples!')
            return None

        # Copy 160 bytes from the sample pointer, because char * uses null terminator
        output = PyBytes_FromStringAndSize(samples, 160)

        return output

    def __dealloc__(self):
        """
        Gets called when no more reference of this object exists.

        :return: nothing
        """

        cpcmlib.dealloc_clk()

