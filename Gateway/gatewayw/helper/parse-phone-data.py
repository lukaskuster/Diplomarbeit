import argparse
import json

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='XHTML APN to Json Parser.')
    parser.add_argument('--input', '-i')
    parser.add_argument('--output', '-o')

    args = parser.parse_args()

    INPUT_FILE = args.input or 'apn-conf.xhtml'
    OUTPUT_FILE = args.output or 'apn-conf.json'

    with open(INPUT_FILE, 'r') as f:
        s = f.read()
