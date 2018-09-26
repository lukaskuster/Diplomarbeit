from pyee import EventEmitter
from sim800.utils import clear_str
from sim800.serial_loop import SerialLoop


def _serial_return(func):
    """
    Decorator to add a callback to a command function,
    that gets called when the serial loop gets a return value from the serial interface

    :param func: Function that returns the command as String
    :return: New Function with an callback argument
    """

    def wrapper(self, *args, **kwargs):
        if 'callback' in kwargs:
            # Add a listener on the event with the callback arg
            self.on(func.__name__, kwargs['callback'])
            del kwargs['callback']
        else:
            self.on(func.__name__, lambda e: None)

        data = func(self, *args, **kwargs)

        # Set the event name in the serial loop to the function name
        self.serial_loop.command_queue.put({'name': func.__name__, 'data': data})
    return wrapper


class Sim800(EventEmitter):
    """
    Sim800 processes AT-Commands over the serial interface
    """

    def __init__(self, serial_port='/dev/serial0', debug=False):
        """
        Construct a new 'SerialLoop' object.

        :param serial_port: port of the serial interface
        :param debug: indicates debug mode
        :return: returns nothing
        """

        super().__init__()

        # Create serial loop
        self.serial_loop = SerialLoop(self, serial_port, debug)

        # Start the thread
        self.serial_loop.start()

        self.debug = debug

    def close(self):
        """
        Closes the SerialLoop thread

        :return: returns nothing
        """

        self.serial_loop.running = False

    @_serial_return
    def custom_command(self, command):
        """
        :param command: Command that should be written to the serial interface
        :return: returns the command with trailing \r\n
        """

        command = clear_str(command)
        return command + '\r\n'

    @_serial_return
    def answer_call(self):
        """
        :return: returns the answer call AT-Command
        """

        return 'ATA\r\n'

    @_serial_return
    def hang_up_call(self):
        """
        :return: returns the hang up AT-Command
        """

        return 'ATH\r\n'

    @_serial_return
    def dial_number(self, number):
        """
        :param number: Number that should be dialed
        :return: returns the dial AT-Command
        """

        # Remove all \n and \r from the number
        number = clear_str(number)
        return 'ATD{};\r\n'.format(number)
