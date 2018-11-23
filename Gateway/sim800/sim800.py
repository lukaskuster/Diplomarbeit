from pyee import EventEmitter
from utils import clear_str
import sim800.serial_loop as serial_loop
import sim800.at_command as cmd
import sim800.at_event as atev
import sim800.parser as atparser
import asyncio


class Sim800(EventEmitter):
    """
    Sim800 processes AT-Commands over the serial interface
    """

    def __init__(self, serial_port='/dev/serial0', debug=False, loop=asyncio.get_event_loop()):
        """
        Construct a new 'SerialLoop' object.

        :param serial_port: port of the serial interface
        :param debug: indicates debug mode
        :type serial_port: str
        :type debug: bool
        :return: returns nothing
        """

        super().__init__(scheduler=asyncio.run_coroutine_threadsafe, loop=loop)

        # Create serial loop
        self.serial_loop = serial_loop.SerialLoop(self, serial_port, debug)
        if debug:
            self.serial_loop.echo = False
        # Set the event loop
        self._event_loop = loop

        # Start the thread
        self.serial_loop.start()

        self.debug = debug

    def close(self):
        """
        Closes the SerialLoop thread

        :return: returns nothing
        :rtype: str
        """

        self.serial_loop.running.set()

    async def write(self, command):
        """
        Writes the command to the serial interface.

        This method can be used synchronously as well as asynchronously,
        by setting a callback in the command object. If the method runs synchronously it returns the response event.
        When a callback is specified this method is non blocking and gets the event as argument to the callback.

        :param command: command that should be written to the serial interface
        :return: returns the response event if no callback is set on the command
        """

        event = atev.ATEvent(command.name, command)
        self.serial_loop.command_queue.put(event)

        await event.wait()
        return event

    async def answer_call(self):
        """
        Answer an incoming call.

        :return: event
        """

        return await self.write(cmd.ATCommand('ATA\r\n', name='AnswerCall'))

    async def hang_up_call(self):
        """
        Disconnect the current call.

        :return: event
        """

        return await self.write(cmd.ATCommand('ATH\r\n', name='HangUpCall'))

    async def dial_number(self, number):
        """
        Call a participant.

        :param number: phone number of the participant
        :type number: str
        :return: event
        """

        # Remove all \n and \r from the number
        number = clear_str(number)
        return await self.write(cmd.ATCommand('ATD{};\r\n'.format(number), name='DialNumber'))

    async def send_sms(self, number, text):
        """
        Send a sms to a participant.

        :param number: phone number of the participant
        :param text: message of the sms
        :type number: str
        :type text: str
        :return: event
        """

        # Remove all \n\r from the strings and add <ctrl-Z/ESC> after the message of the sms
        number = clear_str(number)
        text = clear_str(text)
        text += '\x1A'

        return await self.write(cmd.ATCommand('AT+CMGS="{}"\r'.format(number), name='SendSMS', data=text))

    async def request_unread_sms(self):
        """
        Read all unread sms.

        Event Data: [SMS]

        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CMGL="REC UNREAD"\r\n', name='ListUnreadSMS',
                                              parser=atparser.SMSListParser))

    async def request_all_sms(self):
        """
        Read all sms.

        Event Data: [SMS]

        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CMGL="ALL"\r\n', name='ListAllSMS', parser=atparser.SMSListParser))

    async def set_sms_mode(self, mode=None):
        """
        Set the sms mode.

        Mode can be either 0 or 1
        0: PDU mode
        1: Text mode

        :param mode: sms mode
        :type mode: int
        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CMGF={}\r\n'.format(mode), name='SMSMode'))

    async def power_off(self, mode):
        """
        Shutdown the sim-module.

        Mode can be either 0 or 1
        0: Power off urgently
        1: Normal power off

        :param mode: mode for power off
        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CPOWD={}\r\n'.format(mode), name='PowerOff'))

    async def request_signal_quality(self):
        """
        Read the signal quality.

        Event Data: SignalQuality

        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CSQ\r\n', name='SignalQuality', parser=atparser.SignalQualityParser))

    async def reset_default_configuration(self):
        """
        Reset sim-module to default configuration.

        :return: event
        """

        return await self.write(cmd.ATCommand('ATZ\r\n', name='ResetDefaultConfiguration'))

    async def enter_pin(self, pin):
        """
        Enter the sim card pin.

        :param pin: pin, puk or puk2
        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CPIN={}\r\n'.format(pin), name='EnterPIN'))

    async def request_pin_status(self):
        """
        Read the pin status of the sim card.

        Event Data: PinStatus

        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CPIN?\r\n', name='PINStatus', parser=atparser.PinStatusParser))

    async def request_imei(self):
        """
        Read the imei.

        Event Data: IMEI

        :return: event
        """

        return await self.write(cmd.ATCommand('AT+GSN', name='IMEI', parser=atparser.IMEIParser))

    async def request_network_status(self):
        """
        Reads the current network status.

        Event Data: NetworkStatus

        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CREG?', name='NetworkStatus', parser=atparser.NetworkStatusParser))

    async def set_echo_mode(self, mode):
        """
        Set the echo mode.

        0: Echo mode off
        1: Echo mode on

        :param mode: echo mode
        :type mode: int
        :return: event
        """

        event = await self.write(cmd.ATCommand('ATE{}'.format(mode), name='EchoMode'))

        if not event.error:
            self.serial_loop.echo = bool(mode)

        return event

    async def set_error_mode(self, mode):
        """
        Set the error mode.

        0: Disable CME error
        1: Enable CME error with error codes
        2: Enable CME error with verbose message

        :param mode: error mode
        :type mode: int
        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CMEE={}'.format(mode), name='ErrorMode'))

    async def request_subscriber_number(self):
        """
        Read the subscriber number and additional parameters.

        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CNUM', name='SubscriberNumber'))

    async def request_imsi(self):
        """
        Read the operator imsi.

        :return: event
        """

        return await self.write(cmd.ATCommand('AT+CIMI', name='IMSI', parser=atparser.IMEIParser))
