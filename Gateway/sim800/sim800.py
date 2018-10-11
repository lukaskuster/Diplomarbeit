from pyee import EventEmitter
from sim800.utils import clear_str
from sim800.serial_loop import SerialLoop


def _serial_return(func):
    """
    Decorator to add a callback to a command function,
    that gets called when the serial loop gets a return value from the serial interface

    :param func: function that returns the command as String
    :return: new Function with an callback argument
    """

    def wrapper(self, *args, **kwargs):
        if 'callback' in kwargs:
            # Add a listener on the event with the callback arg
            self.on(func.__name__, kwargs['callback'])
            del kwargs['callback']
        else:
            self.on(func.__name__, lambda e: None)

        command = func(self, *args, **kwargs)

        # Create the event
        event = {'name': func.__name__}
        if isinstance(command, dict):
            event['command'] = command['command']
            event['data'] = command['data']
        else:
            event['command'] = command

        # Add the event to the serial loop queue
        self.serial_loop.event_queue.put(event)
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
        :type serial_port: str
        :type debug: bool
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
        :rtype: str
        """

        self.serial_loop.running = False

    @_serial_return
    def custom_command(self, command):
        """
        :param command: command that should be written to the serial interface
        :type command: str
        :return: returns the command with trailing \r\n
        :rtype: str
        """

        command = clear_str(command)
        return command + '\r\n'

    @_serial_return
    def answer_call(self):
        """
        :return: returns the answer call AT-Command
        :rtype: str
        """

        return 'ATA\r\n'

    @_serial_return
    def hang_up_call(self):
        """
        :return: returns the hang up AT-Command
        :rtype: str
        """

        return 'ATH\r\n'

    @_serial_return
    def dial_number(self, number):
        """
        :param number: number that should be dialed
        :type number: str
        :return: returns the dial AT-Command
        :rtype: str
        """

        # Remove all \n and \r from the number
        number = clear_str(number)
        return 'ATD{};\r\n'.format(number)

    @_serial_return
    def send_sms(self, number, text):
        """
        :param number: number the sms should be send to
        :param text: text of the sms
        :type number: str
        :type text: str
        :return: returns the send sms AT-Command
        :rtype: str
        """

        number = clear_str(number)
        text = clear_str(text)
        text += '\x1A'

        return {'command': 'AT+CMGS="{}"\r'.format(number), 'data': text}

    @_serial_return
    def list_unread_sms(self):
        """
        :return: returns the AT-Command for all unread sms'
        :rtype: str
        """

        return 'AT+CMGL="REC UNREAD"\r\n'

    @_serial_return
    def list_all_sms(self):
        """
        :return: returns the AT-Command for all sms'
        :rtype: str
        """

        return 'AT+CMGL="ALL"\r\n'

    @_serial_return
    def set_sms_mode(self, mode):
        """
        :param mode: sms message format
        :type mode: int
        :return: returns the sms message format AT-Command
        :rtype: str

        Mode can be either 0 or 1
        0: PDU mode
        1: Text mode
        """

        return 'AT+CMGF={}\r\n'.format(mode)

    @_serial_return
    def power_off(self, mode):
        """
        :param mode: power off mode
        :type mode: int
        :return: returns the power off AT-Command
        :rtype: str

        Mode can be either 0 or 1
        0: Power off urgently
        1: Normal power off
        """

        return 'AT+CPOWD={}\r\n'.format(mode)

    @_serial_return
    def signal_quality(self):
        """
        :return: returns the signal quality report AT-Command'
        :rtype: str
        """

        return 'AT+CSQ\r\n'

    @_serial_return
    def reset_default_configuration(self):
        """
        :return: returns the reset default configuration AT-Command'
        :rtype: str
        """

        return 'ATZ\r\n'

    @_serial_return
    def enter_pin(self, pin):
        """
        :param pin: can be pin, puk, etc...
        :return: returns the enter pin write AT-Command'
        :rtype: str
        """

        return 'AT+CPIN={}\r\n'.format(pin)

    @_serial_return
    def pin_required(self):
        """
        :return: returns the enter pin read AT-Command'
        :rtype: str
        """

        return 'AT+CPIN?\r\n'
