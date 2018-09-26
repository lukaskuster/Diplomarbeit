#! /usr/bin/python3.6

import argparse
from sim800 import Sim800
from functools import partial


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Serial connection sending AT-Commands to Sim800')
    parser.add_argument('--hangup', '-u', action='count')
    parser.add_argument('--answer', '-a', action='count')
    parser.add_argument('--dial', '-d')
    parser.add_argument('--debug', action='count')

    # Callback function for the commands, that just prints the return value from the serial interface
    # and closes the sim800 object
    def on_serial_return(sim800, e):
        print(e)
        if sim800.debug:
            sim800.close()

    # Parse commandline arguments
    args = parser.parse_args()

    debug = True if args.debug else False

    # Initialize new Sim800 object with debug enabled
    sim = Sim800(debug=debug)

    # Print ring when the sim800 module gets an incoming call
    sim.on('ring', lambda: print('Incoming call!'))

    # Bind the sim object to the function
    on_serial_return = partial(on_serial_return, sim)

    # Run the specified AT-Command
    if args.answer:
        sim.answer_call(callback=on_serial_return)
    elif args.hangup:
        sim.hang_up_call(callback=on_serial_return)
    elif args.dial:
        sim.dial_number(args.dial, callback=on_serial_return)

    # Custom AT-Commands while running
    # Only available if debug mode is not enabled
    if not debug:
        while True:
            cmd = input()
            # Strip all whitespaces
            cmd.strip()

            # Exit the loop and close the sim800 object if 'exit' is typed
            if cmd == 'exit':
                sim.close()
                break
            # Send the command
            sim.custom_command(cmd, callback=on_serial_return)
