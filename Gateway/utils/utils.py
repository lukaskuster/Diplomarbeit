import re
from utils.singleton import Singleton
from enum import IntEnum
import datetime


def clear_str(string):
    """
    Function that returns the string without carriage return and new line character

    :param string: String that should be processed
    :type string: str
    :return: String without \n and \r characters
    :rtype: str
    """

    return re.sub('([\n\r])', '', string)


@Singleton
class Logger:
    """
    Logger with log levels.
    """

    class AnsiEscapeSequence:
        """
        Class that holds ANSI Escape Sequences. That are used for coloring the cli output.
        """
        HEADER = '\033[95m'
        OK_BLUE = '\033[94m'
        OK_GREEN = '\033[92m'
        WARNING = '\033[93m'
        FAIL = '\033[91m'
        DEFAULT = '\033[0m'
        BOLD = '\033[1m'
        UNDERLINE = '\033[4m'

    class Level(IntEnum):
        """
        Enum that holds the log levels
        """
        DEBUG = 3
        INFO = 2
        LOG = 1

    # String template of the current time
    _TIME_STRING = datetime.datetime.today().strftime(AnsiEscapeSequence.BOLD + '[%x %X]') + AnsiEscapeSequence.DEFAULT

    # The applied log level
    level = Level.LOG

    def log(self, namespace, message):
        """
        Prints the message if the log level is set to 'LOG'.

        :param namespace: namespace of the log
        :param message: message of the log
        :type namespace: str
        :type message: str
        :return: nothing
        """
        if self.level >= self.Level.LOG:
            print('{} {}: {}'.format(self._TIME_STRING, namespace.upper(), message))

    def info(self, namespace, message):
        """
        Prints the message if the log level is set to 'INFO'.

        :param namespace: namespace of the log
        :param message: message of the log
        :type namespace: str
        :type message: str
        :return: nothing
        """
        if self.level >= self.Level.INFO:
            namespace = self.AnsiEscapeSequence.OK_BLUE + namespace.upper() + self.AnsiEscapeSequence.DEFAULT
            print('{} {}: {}'.format(self._TIME_STRING, namespace, message))

    def debug(self, namespace, message):
        """
        Prints the message if the log level is set to 'DEBUG'

        :param namespace: namespace of the log
        :param message: message of the log
        :type namespace: str
        :type message: str
        :return: nothing
        """
        if self.level >= self.Level.DEBUG:
            namespace = self.AnsiEscapeSequence.OK_GREEN + namespace.upper() + self.AnsiEscapeSequence.DEFAULT
            print('{} {}: {}'.format(self._TIME_STRING, namespace, message))

    def error(self, namespace, message):
        """
        Prints an error message.

        :param namespace: namespace of the log
        :param message: message of the log
        :type namespace: str
        :type message: str
        :return: nothing
        """
        message = self.AnsiEscapeSequence.FAIL + namespace.upper() + ': ' + message + self.AnsiEscapeSequence.DEFAULT
        print('{} {}'.format(self._TIME_STRING, message))
