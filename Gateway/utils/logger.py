from utils.singleton import Singleton
from enum import IntEnum
import datetime


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


def _time_str():
    return datetime.datetime.today().strftime(AnsiEscapeSequence.BOLD + '[%x %X]') + AnsiEscapeSequence.DEFAULT


@Singleton
class Logger:
    """
    Logger with log levels.
    """

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
        if self.level >= Level.LOG:
            print('{} {}: {}'.format(_time_str(), namespace.upper(), message))

    def info(self, namespace, message):
        """
        Prints the message if the log level is set to 'INFO'.

        :param namespace: namespace of the log
        :param message: message of the log
        :type namespace: str
        :type message: str
        :return: nothing
        """
        if self.level >= Level.INFO:
            namespace = AnsiEscapeSequence.OK_BLUE + namespace.upper() + AnsiEscapeSequence.DEFAULT
            print('{} {}: {}'.format(_time_str(), namespace, message))

    def debug(self, namespace, message):
        """
        Prints the message if the log level is set to 'DEBUG'

        :param namespace: namespace of the log
        :param message: message of the log
        :type namespace: str
        :type message: str
        :return: nothing
        """
        if self.level >= Level.DEBUG:
            namespace = AnsiEscapeSequence.OK_GREEN + namespace.upper() + AnsiEscapeSequence.DEFAULT
            print('{} {}: {}'.format(_time_str(), namespace, message))

    def error(self, namespace, message):
        """
        Prints an error message.

        :param namespace: namespace of the log
        :param message: message of the log
        :type namespace: str
        :type message: str
        :return: nothing
        """
        message = AnsiEscapeSequence.FAIL + namespace.upper() + ': ' + message + AnsiEscapeSequence.DEFAULT
        print('{} {}'.format(_time_str(), message))

