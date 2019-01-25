#!/usr/local/bin/python3.6

import json
import xml.etree.ElementTree
import argparse

apns = {}


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='XML APN to Json Parser.')
    parser.add_argument('--input', '-i')
    parser.add_argument('--output', '-o')

    args = parser.parse_args()

    INPUT_FILE = args.input or 'apn-conf.xml'
    OUTPUT_FILE = args.output or 'apn-conf.json'

    e = xml.etree.ElementTree.parse(INPUT_FILE).getroot()

    for t in e.findall('apn'):
        ctr_code = t.get('mcc')
        oper_code = t.get('mnc')
        carrier = t.get('carrier')

        if ctr_code not in apns:
            apns[ctr_code] = {}

        apns[ctr_code][oper_code] = carrier
        apns[ctr_code]['iso'] = None
        apns[ctr_code]['country'] = None

    with open(OUTPUT_FILE, 'w') as file:
                json.dump(apns, file, indent=4)
