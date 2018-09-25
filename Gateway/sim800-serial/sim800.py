#! /usr/bin/python3.6

from serial import Serial
import re
from threading import Thread
from pyee import EventEmitter
from queue import Queue


def clear_str(string):
    """
    Function that returns the string without carriage return and new line character

    :param string: String that should be processed
    :return: String without \n and \r characters
    """

    return re.sub('([\n\r])', '', string)


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


class Event:
    """
    Event encapsulates an error and a content list.
    """
    def __init__(self, name, error=False):
        """
        Construct a new 'Event' object.

        :param error: error of event
        :return: returns nothing
        """
        self.error = error
        self.error_message = None
        self.name = name
        self.content = []

    def __str__(self):
        """
        Returns the event as a human readable string

        :return: human readable string of the event
        """

        content = '\n'.join(self.content)
        return 'Name: {}\nError: {}\nError Message: {}\nContent:\n{}'.format(
            self.name, self.error, self.error_message, content)


class SerialLoop(Thread):
    """
    SerialLoop is a thread there for communicate with the sim800 module over the serial interface
    """

    def __init__(self, sim, serial_port, debug):
        """
        Construct a new 'SerialLoop' object.

        :param sim: Sim800 object
        :param serial_port: port of the serial interface
        :param debug: indicates debug mode
        :return: returns nothing
        """

        super(SerialLoop, self).__init__()

        # If debug is enabled the serial connection is emulated with the commandline
        self.debug = debug

        if not debug:
            # Initialize a new serial connection
            self.serial = Serial(serial_port, baudrate=9600, timeout=1)

        # Set the sim800 object to emit events
        self.sim = sim

        # The Events that should be written and emitted, when a message returns from the serial interface
        self.command_queue = Queue(64)

        # Set running to False to stop the loop
        self.running = True

    def run(self):
        """
        Is there for writing commands to the serial interface and reading the response
        :return: returns nothing
        """

        while self.running:

            # Write the event to the serial interface and emit the returning value
            if not self.command_queue.empty():

                # Get the next command from the queue
                command = self.command_queue.get()

                # Write the command to the serial interface
                self._write(command['data'])

                # Remove \r\n
                data = clear_str(command['data'])

                # Get the data from the serial interface, remove \r\n and convert it to a string
                response = clear_str(self._read().decode('utf-8'))

                # The sim800 module sends the same command back first
                if response != data:
                    # Print an error and continue with the next command if not the same is send back
                    print("Error: Wrong event returned on serial port! Got: {}, Command: {}".format(response, data))
                    continue

                # Create new event object
                event = Event(command['name'])

                # Listen on the serial interface until an error or success
                while True:
                    # Get the data from the serial interface, remove \r\n and convert it to a string
                    response = clear_str(self._read().decode('utf-8'))

                    if 'OK' in response:
                        event.error = False
                        break
                    elif 'ERROR' in response:
                        event.error_message = response
                        event.error = True
                        break
                    elif len(response) > 0:
                        # Save the transmitted data in the content property of the event
                        event.content.append(response)

                # Emit an event to the last called command function
                self.sim.emit(command['name'], event)

            # If no events are in the queue, just listen on the serial port
            else:
                # Get the data from the serial interface, remove \r\n and convert it to a string
                response = clear_str(self._read().decode('utf-8'))

                if response == 'RING':
                    # Emit the ring event
                    self.sim.emit('ring')

    def _read(self):
        """
        Reads from the serial interface
        :return: returns the value from the serial interface
        """

        # When debug mode is enabled get the data from the command line
        if self.debug:
            return str.encode(input())
        else:
            # Read the data from the serial interface
            return self.serial.readline()

    def _write(self, data):
        """
        Writes data to the serial interface

        :param data: data that should be written
        :return: returns nothing
        """

        # When the data is not a string or bytes raise an value error
        if type(data) != bytes and type(data) != str:
            raise ValueError('Data must be type string or bytes')

        # If the data is a string encode it to bytes
        elif type(data) == str:
            data = str.encode(data)

        # If debug is enabled print the data to the console
        if self.debug:
            print(data)
            return

        # Else write the data to the serial interface
        self.serial.write(data)


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
