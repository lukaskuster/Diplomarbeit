import json
import time
from threading import Thread, Event

import requests
from requests.exceptions import ConnectionError, ChunkedEncodingError

from gateway.utils import logger, AnsiEscapeSequence


class SSE(Thread):
    """
    Thread that tries to open a sse connection until it is closed
    """

    def __init__(self, emitter, timeout=5):
        """
        Construct a new 'SSE' object.

        :param emitter: pyee emitter that can emit events
        :param timeout: time to wait before trying to reconnect in seconds
        """

        super(SSE, self).__init__()
        self.daemon = True
        self.emitter = emitter
        self.timeout = timeout
        self._running = Event()
        self._connection_state = 'new'

    @property
    def connection_state(self):
        """
        Getter for connection state.

        :return: connection state
        """
        return self._connection_state

    @connection_state.setter
    def connection_state(self, value):
        """
        Emits a 'connectionstatechange' event every time the state changes.

        :param value: str
        :return: nothing
        """

        if self._connection_state != value:
            self._connection_state = value
            self.emitter.emit('connectionStateChange', value)

            state = AnsiEscapeSequence.UNDERLINE + self._connection_state + AnsiEscapeSequence.DEFAULT
            logger.debug('SSE', 'Connection state changed to ' + state)

    def close(self):
        """
        Close the thread.

        :return: nothing
        """

        self._running.set()
        logger.debug('SSE', 'Closing initiated!')

    def run(self):  # TODO: Clean up method
        """
        Try to establish a connection until the thread is closed.
        Emits the parsed events on the API.

        :return: noting
        """

        logger.info('SSE', 'Started service!')

        while not self._running.is_set():
            try:
                self.connection_state = 'connecting'

                response = requests.get(self.emitter.host + '/gateway/stream', stream=True,
                                        json={'imei': self.emitter.id},
                                        auth=self.emitter.auth, timeout=10)

                self.connection_state = 'connected'
                self.emitter.emit('connect')
                logger.info('SSE', 'Connected with host!')

                if response.encoding is None:
                    response.encoding = 'utf-8'

                for line in response.iter_lines(decode_unicode=True):

                    # Return the run function to end the thread
                    if self._running.is_set():
                        self.connection_state = 'end'
                        return

                    # Check if the line has content to filter out the keep alive packets
                    if line:
                        try:
                            notification = json.loads(line)
                            logger.debug('SSE', 'Received {}{}{} event with data: {}{}{}'.format(
                                AnsiEscapeSequence.UNDERLINE,
                                notification['event'],
                                AnsiEscapeSequence.DEFAULT,
                                AnsiEscapeSequence.HEADER,
                                notification['data'],
                                AnsiEscapeSequence.DEFAULT))
                            if notification['event'] == 'reconnect':
                                logger.info('SSE', 'Reconnecting')
                                break
                            self.emitter.emit(notification['event'], notification['data'])
                        except ValueError:  # Json failed to load
                            pass  # For now ignore when a wrong message arrived
                        except KeyError:  # An error occurs if event or data is not available
                            pass

                if response.status_code != 200 and notification:
                    self.emitter.emit('connectionFailed', notification)
                    logger.error('SSE', 'ConnectionError({})'.format(notification['errorMessage']))
                    time.sleep(self.timeout)

            except ConnectionError:  # Failed to connect
                self.emitter.emit('connectionRefused')
                logger.info('SSE', 'ConnectionError')
                time.sleep(self.timeout)
            except ChunkedEncodingError:  # Connection was aborted
                self.emitter.emit('connectionAborted')
                logger.info('SSE', 'EncodingError')
                self.connection_state = 'connecting'
                time.sleep(self.timeout)
