from serial import Serial
from queue import Queue
from threading import Thread
from utils import clear_str, logger
import sim800.at_command as atcmd
import sim800.at_event as atevent
import threading
import pyee


class SerialLoop(Thread):
    """
    SerialLoop is a thread there for communicate with the sim800 module over the serial interface
    """

    def __init__(self, emitter, serial_port, debug):
        """
        Construct a new 'SerialLoop' object.

        :param emitter: Sim800 object
        :param serial_port: port of the serial interface
        :param debug: indicates debug mode
        :type emitter: object
        :type serial_port: str
        :type debug: bool
        :return: returns nothing
        """

        if not hasattr(emitter, 'emit'):
            raise ValueError

        super(SerialLoop, self).__init__()

        # If debug is enabled the serial connection is emulated with the commandline
        self.debug = debug

        if not debug:
            # Initialize a new serial connection
            self.serial = Serial(serial_port, baudrate=115200, timeout=1)

        # Set the event emitter

        if not isinstance(emitter, pyee.EventEmitter):
            raise TypeError('emitter must be of type pyee.EventEmitter!')

        self.emitter = emitter
        self.echo = True

        # The Events that should be written and emitted, when a message returns from the serial interface
        self.command_queue = Queue(64)

        # Set running to stop the loop
        self.running = threading.Event()

    def run(self):
        """
        Is there for writing commands to the serial interface and reading the response

        :return: returns nothing
        """

        logger.info('Sim800', 'Started Service!')

        while not self.running.is_set():

            # Write the event to the serial interface and emit the returning value
            if not self.command_queue.empty():

                # Get the next event from the queue
                command: atcmd.ATCommand = self.command_queue.get()

                # Write the command to the serial interface
                self._write(command.command)

                # Remove \r\n
                command = clear_str(command.command)

                # Verify the command if echo mode is on
                if self.echo:
                    # Get the data from the serial interface, remove \r\n and convert it to a string
                    response = clear_str(self._read().decode('utf-8'))

                    # The sim800 module sends usually the same command back first
                    if response != command:
                        # Print an error and continue with the next command if not the same is send back
                        logger.error('Sim800', 'Wrong event returned on serial port! Got: {}, at_command.py: {}'
                                     .format(response, command.command))
                        continue

                # Create new event object
                e = atevent.ATEvent(command.name)

                # Listen on the serial interface until an error or success
                while True:

                    res = self._read()
                    # Get the data from the serial interface, remove \r\n and convert it to a string
                    try:
                        response = clear_str(res.decode('utf-8'))

                        # If the prompt char is send back, serial800 expects some kind of data
                        if ('>' in response) and ('data' in command):
                            self._write(command.data)
                            continue

                        if 'OK' in response:
                            e.error = False
                            break
                        elif 'ERROR' in response:
                            e.error_message = response
                            e.error = True
                            break
                        elif len(response) > 0:
                            # Save the transmitted data in the content property of
                            # the event line by line until OK or ERROR is send
                            e.content.append(response)
                    except UnicodeDecodeError:
                        logger.error('Sim800',
                                     'Could not decode the message from the serial interface! Message: {}'.format(res))

                # Emit an event to the last called command function
                command.callback(e)

            # If no events are in the queue, just listen on the serial port
            else:
                # Get the data from the serial interface, remove \r\n and convert it to a string
                res = self._read()
                try:
                    response = clear_str(res.decode('utf-8'))

                    if response == 'RING':
                        # Emit the ring event
                        self.emitter.emit('ring')
                        logger.info('Sim800', 'Ring event!')
                except UnicodeDecodeError:
                    logger.error('Sim800',
                                 'Could not decode the message from the serial interface! Message: {}'.format(res))

    def _read(self):
        """
        Reads from the serial interface

        :return: returns the value from the serial interface
        :rtype: bytearray
        """

        # When debug mode is enabled get the data from the command line
        if self.debug:
            return str.encode(input())
        else:
            # Read the data from the serial interface
            data = self.serial.readline()

            logger.debug('Sim800', 'Received data from serial interface: ' + str(data))
            return data

    def _write(self, data):
        """
        Writes data to the serial interface

        :param data: data that should be written
        :type data: bytearray, str
        :return: returns nothing
        """

        # When the data is not a string or bytes raise an value error
        if type(data) != bytes and type(data) != str:
            error = ValueError('Data must be type string or bytes')
            logger.error('Sim800', error.args[0])
            raise error

        # If the data is a string encode it to bytes
        elif type(data) == str:
            data = str.encode(data)

        # If debug is enabled print the data to the console
        if self.debug:
            logger.info('Sim800', 'Wrote data to interface (DEBUG): ' + str(data))
            return

        # Else write the data to the serial interface
        self.serial.write(data)
        logger.debug('Sim800', 'Wrote data to serial interface: ' + str(data))
