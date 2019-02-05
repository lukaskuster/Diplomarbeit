# cython: language_level=3
# distutils: sources = lib/pcmlib/pcmlib.c
# distutils: include_dirs = lib/pcmlib/

from gateway.io.pcm cimport cpcmlib
from cpython.bytes cimport PyBytes_FromStringAndSize

from gateway.utils import logger


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

    def enable(self):
        cpcmlib.enable_clk()

        ret = cpcmlib.enable_pcm()

        if ret < 0:
            logger.error('PCM', 'EnablePCMError({})'.format(ret))

    def disable(self):
        ret = cpcmlib.disable_pcm()

        if ret < 0:
            logger.error('PCM', 'DisablePCMError({})'.format(ret))

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

