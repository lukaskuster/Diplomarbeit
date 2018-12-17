# cython: language_level=3

import asyncio


class ATEvent(asyncio.Event):
    """
    Event encapsulates an error and a content list.
    """

    def __init__(self, name, command, error=False):
        """
        Construct a new 'Event' object.

        :param error: error of event
        :type error: bool
        :return: returns nothing
        """
        super().__init__()

        self.error = error
        self.error_message = None
        self.name = name
        self.command = command
        self.content = []
        self.data = None

    def set(self):
        """
        Override to set the event threadsafe in the event loop.

        :return: nothing
        """

        self._loop.call_soon_threadsafe(super().set)

    def clear(self):
        """
        Override to clear the event threadsafe in the event loop.

        :return: nothing
        """

        self._loop.call_soon_threadsafe(super().clear)

    def __str__(self):
        """
        Returns the event as a human readable string

        :return: human readable string of the event
        :rtype: str
        """

        return 'Name: {}\nError: {}\nError Message: {}\nCommand: {}\nData: {}\n'.format(
            self.name, self.error, self.error_message, self.command, self.data)
