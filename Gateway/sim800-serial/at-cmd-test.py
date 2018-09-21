import serial
import argparse

SERIAL_PORT = "/dev/serial0"

ser = serial.Serial(SERIAL_PORT, baudrate=9600, timeout=5)

parser = argparse.ArgumentParser(description='Serial connection sending AT-Commands to Sim800')
parser.add_argument('--hangup', '-u', action='count')
parser.add_argument('--answer', '-a', action='count')
parser.add_argument('--call', '-c')


args = parser.parse_args()

if args.answer:
    ser.write(b'ATA\r\n')

elif args.hangup:
    ser.write(b'ATH\r\n')

elif args.call:
    number = args.call
    number = number.replace('\r', '')
    number = number.replace('\n', '')
    x = 'ATD%s;\n' % number
    ser.write(str.encode(x))

while True:
    print(ser.readline())

