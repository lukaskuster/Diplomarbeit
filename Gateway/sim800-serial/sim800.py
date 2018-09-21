import serial
import re
from threading import Thread
from pyee import EventEmitter


# Decorator to add a callback to a command function,
# that gets called when the serial loop gets a return value from the serial interface
def _serial_return(func):
    def wrapper(self, *args, **kwargs):
        # Set the event name in the serial loop to the function name
        self.serial_loop.event = func.__name__

        if 'callback' in kwargs:
            # Add a listener on the event with the callback arg
            self.on(func.__name__, kwargs['callback'])
            del kwargs['callback']
        else:
            self.on(func.__name__, lambda e: None)

        return func(self, *args, **kwargs)
    return wrapper


class SerialLoop(Thread):
    def __init__(self, sim):
        super(SerialLoop, self).__init__()

        # Set the sim800 object to emit events
        self.sim = sim

        # The Event that should be emitted, when a message returns from the serial interface
        self.event = None

        # Set running to False to stop the loop
        self.running = True

    def run(self):
        while self.running:
            # When debug mode is enabled get the data from the command line
            if self.sim.debug:
                sim_data = str.encode(input())
            else:
                # Read the data from the serial interface
                sim_data = self.sim.serial.readline()

            if sim_data == b'RING':
                self.sim.emit('ring')

            elif self.event is not None:
                # Emit an event to the last called command function
                self.sim.emit(self.event, sim_data)
                self.event = None


class Sim800(EventEmitter):

    def __init__(self, serial_port='/dev/serial0', debug=False):
        super().__init__()

        self.debug = debug

        # Create serial loop and pass the current obj as argument
        self.serial_loop = SerialLoop(self)

        # Start the thread
        self.serial_loop.start()

        if not debug:
            # Initialize a new serial connection
            self.serial = serial.Serial(serial_port, baudrate=9600, timeout=5)

    @_serial_return
    def answer_call(self):
        self._write('ATA\r\n')

    @_serial_return
    def hang_up_call(self):
        self._write('ATH\r\n')

    @_serial_return
    def dial_number(self, number):
        # Remove all \n and \r from the number
        number = re.sub('(\n|\r)', '', number)
        self._write('ATD%s;\r\n' % number)

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
