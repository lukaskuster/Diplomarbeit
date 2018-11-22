#!/usr/local/bin/python3.6

import json
import argparse
from xml.etree import ElementTree

apns = {}


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='XHTML APN to Json Parser.')
    parser.add_argument('--input', '-i')
    parser.add_argument('--output', '-o')

    args = parser.parse_args()

    INPUT_FILE = args.input or 'apn-conf.xhtml'
    OUTPUT_FILE = args.output or 'apn-conf.json'

    with open(INPUT_FILE, 'r') as f:
        s = f.read()

    table = ElementTree.XML(s)
    rows = iter(table)
    headers = [col.text for col in next(rows)]
    for row in rows:
        values = [col.text for col in row]
        a = dict(zip(headers, values))
        ctr_code = a['MCC']
        oper_code = a['MNC']
        network = a['Network']
        country = a['Country']
        iso = a['ISO']

        if ctr_code not in apns:
            apns[ctr_code] = {}

        apns[ctr_code][oper_code] = network
        apns[ctr_code]['country'] = country
        apns[ctr_code]['iso'] = iso

    with open(OUTPUT_FILE, 'w') as file:
        json.dump(apns, file, indent=4)
