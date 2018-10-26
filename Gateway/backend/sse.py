from threading import Thread
import requests
from requests.exceptions import ConnectionError, ChunkedEncodingError
import json
import time


class SSE(Thread):
    """
    Thread that tries to open a sse connection until it is closed
    """
    def __init__(self, emitter, timeout=5):
        super(SSE, self).__init__()
        self.emitter = emitter
        self.timeout = timeout
        self._running = True
        self._connection_state = 'new'

    @property
    def connection_state(self):
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
            self.emitter.emit('connectionstatechange', value)

    def close(self):
        """
        Close the thread.

        :return: nothing
        """

        self._running = False

    def run(self):
        """
        Try to establish a connection until the thread is closed.
        Emits the parsed events on the API.

        :return: noting
        """
        while True:
            try:
                self.connection_state = 'connecting'

                response = requests.get(self.emitter.host + '/stream', stream=True, json={'id': self.emitter.id},
                                        auth=self.emitter.auth)

                self.connection_state = 'connected'
                self.emitter.emit('connect')

                if response.encoding is None:
                    response.encoding = 'utf-8'

                for line in response.iter_lines(decode_unicode=True):

                    # Return the run function to end the thread
                    if self._running is False:
                        self.connection_state = 'end'
                        return

                    # Check if the line has content to filter out the keep alive packets
                    if line:
                        try:
                            notification = json.loads(line)
                            self.emitter.emit(notification['event'], notification['data'])
                        except ValueError:    # Json failed to load
                            pass              # For now ignore when a wrong message arrived

            except ConnectionError:           # Failed to connect
                self.emitter.emit('connectionrefused')
                time.sleep(self.timeout)
            except ChunkedEncodingError:      # Connection was aborted
                self.emitter.emit('connectionaborted')
                self.connection_state = 'connecting'
                time.sleep(self.timeout)
