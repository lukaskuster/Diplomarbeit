from pyee import EventEmitter
from utils import clear_str, split_str
from sim800.serial_loop import SerialLoop
import sim800.at_command as cmd
import sim800.response_objects as response_objects


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

        self.serial_loop.running.set()

    def write(self, command, callback=lambda e: None):
        """
        Writes the command to the serial interface.
        The raw response is in the content array of the event from the callback

        :param command: command that should be written to the serial interface
        :param callback: callback that gets the response event
        """

        # Add the event to the serial loop queue
        if type(command) == str:
            self.serial_loop.command_queue.put(cmd.ATCommand(command, callback=callback))
            return

        self.serial_loop.command_queue.put(command)

    def answer_call(self, callback=lambda e: None):
        """
        Answer an incoming call.

        :param callback: function that gets the response event
        :return: nothing
        """

        self.write(cmd.ATCommand('ATA\r\n', name='AnswerCall', callback=callback))

    def hang_up_call(self, callback=lambda e: None):
        """
        Disconnect the current call.

        :param callback: function that gets the response event
        :return: nothing
        """

        self.write(cmd.ATCommand('ATH\r\n', name='HangUpCall', callback=callback))

    def dial_number(self, number, callback=lambda e: None):
        """
        Call a participant.

        :param number: phone number of the participant
        :param callback: function that gets the response event
        :type number: str
        :return: nothing
        """

        # Remove all \n and \r from the number
        number = clear_str(number)
        self.write(cmd.ATCommand('ATD{};\r\n'.format(number), name='DialNumber', callback=callback))

    def send_sms(self, number, text, callback=lambda e: None):
        """
        Send a sms to a participant.

        :param number: phone number of the participant
        :param text: message of the sms
        :param callback: function that gets the response event
        :type number: str
        :type text: str
        :return: nothing
        """

        # Remove all \n\r from the strings and add <ctrl-Z/ESC> after the message of the sms
        number = clear_str(number)
        text = clear_str(text)
        text += '\x1A'

        self.write(cmd.ATCommand('AT+CMGS="{}"\r'.format(number), name='SendSMS', callback=callback, data=text))

    def request_unread_sms(self, callback=lambda e: None):
        """
        Read all unread sms.

        Event Data: [{index, status, recipient, recipientText, time, message}]

        :param callback: function that gets the response event
        :return: nothing
        """

        def _callback(event):
            """
            Add the parsed data to the event.

            :param event: response event from the at-command
            :return: nothing
            """

            # Every second line represents the information of the sms. The other line is the message of the sms.
            for i, line in enumerate(event.content[::2]):
                # Remove the command name from the string and split the data
                data = split_str(line[line.index(': ') + 2:])

                # Add the data to the event
                event.data.append({
                    'index': int(data[0]),
                    'status': data[1][1:-1],
                    'recipient': data[2][1:-1],
                    'recipientText': data[3][1:-1],
                    'time': data[4][1:-1],
                    'message': event.content[i * 2 + 1]
                })
            # Invoke the callback with the updated event
            callback(event)

        self.write(cmd.ATCommand('AT+CMGL="REC UNREAD"\r\n', name='ListUnreadSMS', callback=_callback))

    def request_all_sms(self, callback=lambda e: None):
        """
        Read all sms.

        Event Data: [{index, status, recipient, recipientText, time, message}]

        :param callback: function that gets the response event
        :return: nothing
        """

        def _callback(event):
            for i, line in enumerate(event.content[::2]):
                data = split_str(line[line.index(': ') + 2:])
                event.data.append({
                    'index': int(data[0]),
                    'status': data[1][1:-1],
                    'recipient': data[2][1:-1],
                    'recipientText': data[3][1:-1],
                    'time': data[4][1:-1],
                    'message': event.content[i * 2 + 1]
                })
            callback(event)

        self.write(cmd.ATCommand('AT+CMGL="ALL"\r\n', name='ListAllSMS', callback=_callback))

    def set_sms_mode(self, mode, callback=lambda e: None):
        """
        Set the sms mode.

        Mode can be either 0 or 1
        0: PDU mode
        1: Text mode

        :param mode: sms mode
        :param callback: function that gets the response event
        """

        self.write(cmd.ATCommand('AT+CMGF={}\r\n'.format(mode), name='SetSMSMode', callback=callback))

    def power_off(self, mode, callback=lambda e: None):
        """
        Shutdown the sim-module.

        Mode can be either 0 or 1
        0: Power off urgently
        1: Normal power off

        :param mode: mode for power off
        :param callback: function that gets the response event
        """

        self.write(cmd.ATCommand('AT+CPOWD={}\r\n'.format(mode), name='PowerOff', callback=callback))

    def request_signal_quality(self, callback=lambda e: None):
        """
        Read the signal quality.

        Event Data: {rssi, ber}

        :param callback: function that gets the response event
        :return: nothing
        """

        def _callback(event):
            data = split_str(event.content[0][event.content[0].index(': ') + 2:])
            event.data = response_objects.SignalQuality(data[0], data[1])

            callback(event)

        self.write(cmd.ATCommand('AT+CSQ\r\n', name='SignalQuality', callback=_callback))

    def reset_default_configuration(self, callback=lambda e: None):
        """
        Reset sim-module to default configuration.

        :param callback: function that gets the response event
        :return: nothing
        """

        self.write(cmd.ATCommand('ATZ\r\n', name='ResetDefaultConfiguration', callback=callback))

    def enter_pin(self, pin, callback=lambda e: None):
        """
        Enter the sim card pin.

        :param pin: pin, puk or puk2
        :param callback: function that gets the response event
        :return: nothing
        """

        self.write(cmd.ATCommand('AT+CPIN={}\r\n'.format(pin), name='EnterPIN', callback=callback))

    def request_pin_status(self, callback=lambda e: None):
        """
        Read the pin status of the sim card.

        Event Data: {status: PINStatus}

        :param callback: function that gets the response event
        :return: nothing
        """

        def _callback(event):
            event.data = response_objects.PINStatus(event.content[0]),

            callback(event)

        self.write(cmd.ATCommand('AT+CPIN?\r\n', name='PINStatus', callback=_callback))

    def request_imei(self, callback=lambda e: None):
        """
        Read the imei.

        Event Data: {imei}

        :param callback: function that gets the response event
        :return: nothing
        """

        def _callback(event):
            event.data = event.content[0]

            callback(event)

        self.write(cmd.ATCommand('AT+GSN', name='RequestIMEI', callback=_callback))

    def request_network_status(self, callback=lambda e: None):
        """
        Reads the current network status.

        Event Data: {status: NetworkStatus}

        :param callback: function that gets the response event
        :return: nothing
        """

        def _callback(event):
            data = split_str(event.content[0][event.content[0].index(': ') + 2:])

            status = response_objects.NetworkStatus(data[0], data[1])

            if len(data) == 4:
                status.lac = data[2]
                status.ci = data[3]

            event.data = status,

            callback(event)

        self.write(cmd.ATCommand('AT+GSN', name='NetworkStatus', callback=_callback))
