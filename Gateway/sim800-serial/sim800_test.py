#! /usr/bin/python3.6

import argparse
from sim800 import Sim800


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Serial connection sending AT-Commands to Sim800')
    parser.add_argument('--hangup', '-u', action='count')
    parser.add_argument('--answer', '-a', action='count')
    parser.add_argument('--call', '-c')

    # Initialize new Sim800 object with debug enabled
    sim = Sim800(debug=True)

    # Callback function for the commands, that just prints the return value from the serial interface
    def on_serial_return(e):
        print(e)

    # Parse commandline arguments
    args = parser.parse_args()

    # Run the specified AT-Command
    if args.answer:
        sim.answer_call(callback=on_serial_return)
    if args.hangup:
        sim.hang_up_call(callback=on_serial_return)
    if args.call:
        sim.dial_number(args.call, callback=on_serial_return)

    # Gets called when the sim800 module gets an incomming call
    @sim.on('ring')
    def ring():
        print("ring")

