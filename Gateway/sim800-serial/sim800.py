#! /usr/bin/python3.6

from serial import Serial
import re
from threading import Thread
from pyee import EventEmitter
from queue import Queue


# Decorator to add a callback to a command function,
# that gets called when the serial loop gets a return value from the serial interface
def _serial_return(func):
    def wrapper(self, *args, **kwargs):
        if 'callback' in kwargs:
            # Add a listener on the event with the callback arg
            self.on(func.__name__, kwargs['callback'])
            del kwargs['callback']
        else:
            self.on(func.__name__, lambda e: None)

        data = func(self, *args, **kwargs)

        # Set the event name in the serial loop to the function name
        self.serial_loop.command_queue.put({'event': func.__name__, 'data': data})
    return wrapper


class SerialLoop(Thread):
    def __init__(self, sim, serial_port, debug):
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
        while self.running:

            # Write the event to the serial interface and emit the returning value
            if not self.command_queue.empty():
                event = self.command_queue.get()
                self._write(event['data'])

                sim_data = self._read()

                # Emit an event to the last called command function
                self.sim.emit(event['event'], sim_data)

            # If no events are in the queue, just listen on the serial port
            else:
                sim_data = self._read()

                if sim_data == b'RING':
                    self.sim.emit('ring')

    def _read(self):
        # When debug mode is enabled get the data from the command line
        if self.debug:
            return str.encode(input())
        else:
            # Read the data from the serial interface
            return self.serial.readline()

    def _write(self, data):

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

    def __init__(self, serial_port='/dev/serial0', debug=False):
        super().__init__()

        # Create serial loop
        self.serial_loop = SerialLoop(self, serial_port, debug)

        # Start the thread
        self.serial_loop.start()

    def close(self):
        self.serial_loop.running = False

    @_serial_return
    def custom_command(self, command):
        command = re.sub('([\n\r])', '', command)
        return command + '\r\n'

    @_serial_return
    def answer_call(self):
        return 'ATA\r\n'

    @_serial_return
    def hang_up_call(self):
        return 'ATH\r\n'

    @_serial_return
    def dial_number(self, number):
        # Remove all \n and \r from the number
        number = re.sub('([\n\r])', '', number)
        return 'ATD{};\r\n'.format(number)
