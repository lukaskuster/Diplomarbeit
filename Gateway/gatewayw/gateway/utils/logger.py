import datetime
from enum import IntEnum
import sys
import re

from gateway.utils.singleton import Singleton


def escape_ansi(line):
    """
    :param line: string that should be escaped
    :return: string without ansi escape sequences
    """
    ansi_escape = re.compile(r'(\x9B|\x1B\[)[0-?]*[ -/]*[@-~]')
    return ansi_escape.sub('', line)


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


@Singleton
class Logger:
    """
    Logger with log levels.
    """

    def __init__(self):
        # Config
        self.enable_ansi_strings = True
        self.enable_time = True
        self.time_format = '[%x %X]'
        self.level = Level.DEBUG

        self._error_handler = None
        self.config = None

    def use_config_options(self):
        c = self.config['LOG']
        self.enable_time = c.getboolean('enabletime', fallback=self.enable_time)
        self.enable_ansi_strings = c.getboolean('enableansistrings', fallback=self.enable_ansi_strings)
        self.time_format = c.get('timeformat', self.time_format)
        log_level = c.get('level', 'LOG')
        log_level = log_level.upper()
        if log_level == 'LOG':
            self.level = Level.LOG
        elif log_level == 'DEBUG':
            self.level = Level.DEBUG
        elif log_level == 'INFO':
            self.level = Level.INFO
        else:
            self.error('Logger', 'Can not detect log level!')

    def _time_str(self):
        """
        Gets the time string based on the available options.

        :return: string
        """

        if self.enable_time:
            time_str = datetime.datetime.today().strftime(self.time_format)

            if self.enable_ansi_strings:
                time_str = AnsiEscapeSequence.BOLD + time_str + AnsiEscapeSequence.DEFAULT

            return time_str
        return ''

    def set_error_handler(self, func):
        """
        Sets the error handler for log_error.
        The handler needs the error code and message as arguments.

        :param func: error handler
        :return:
        """

        self._error_handler = func

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
            if not self.enable_ansi_strings:
                message = escape_ansi(message)

            print('{} {}: {}'.format(self._time_str(), namespace.upper(), message), flush=True)

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

            if not self.enable_ansi_strings:
                message = escape_ansi(message)
                namespace = escape_ansi(namespace)

            print('{} {}: {}'.format(self._time_str(), namespace, message), flush=True)

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

            if not self.enable_ansi_strings:
                message = escape_ansi(message)
                namespace = escape_ansi(namespace)

            print('{} {}: {}'.format(self._time_str(), namespace, message), flush=True)

    def error(self, namespace, message):
        """
        Prints an error message.

        :param namespace: namespace of the log
        :param message: message of the log
        :type namespace: str
        :type message: str
        :return: nothing
        """

        m = AnsiEscapeSequence.FAIL + namespace.upper() + ': ' + message + AnsiEscapeSequence.DEFAULT

        without_ansi = escape_ansi(m)

        if not self.enable_ansi_strings:
            m = without_ansi

        print('{}{}'.format(self._time_str(), m), file=sys.stderr, flush=True)

        if self._error_handler:
            message = escape_ansi(message)

            if namespace.upper() == 'SIM800':
                self._error_handler(20000, message)
            if namespace.upper() == 'API':
                self._error_handler(20001, message)
            if namespace.upper() == 'GATEWAY':
                self._error_handler(20002, message)
            if namespace.upper() == 'SIGNALING':
                self._error_handler(20003, message)
            if namespace.upper() == 'WEBRTC':
                self._error_handler(20004, message)
            if namespace.upper() == 'SSE':
                self._error_handler(20005, message)
