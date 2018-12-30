# cython: language_level=3

import json
from datetime import datetime

import gateway.utils as utils
from gateway.core.config import get_config
from gateway.io.sim800 import response_objects


class Parser:
    """
    Parser with an basic implementation that does nothing.

    All custom parser should extend this class.
    """

    @staticmethod
    def parse(content):
        """
        Parses the received data.

        :param content: array of received lines
        :return: the parsed data
        """
        return None


class SMSListParser(Parser):
    """
    Parser that returns al list of SMS objects.
    """

    @staticmethod
    def parse(content):
        sms = []

        # Every second line represents the information of the sms. The other line is the message of the sms.
        for i, line in enumerate(content[::2]):
            # Remove the command name from the string and split the data
            data = utils.split_str(line[line.index(':') + 1:])
            data[0] = data[0].strip()

            # Add a new sms object to the list
            s = response_objects.SMS(int(data[0]), data[1][1:-1], data[2][1:-1], content[i * 2 + 1])
            if data[3]:
                s.address_name = data[3][1:-1]
            if len(data) > 4 and data[4]:
                time_str = data[4][1:-1]

                # Get the index where the timezone starts
                try:
                    zone_index = time_str.index('-')
                except ValueError:
                    try:
                        zone_index = time_str.index('+')
                    except ValueError:
                        zone_index = len(time_str) - 1

                # Convert the timestamp to a datetime object without the timezone
                s.time = datetime.strptime(time_str[0:zone_index], '%y/%m/%d,%H:%M:%S')

            sms.append(s)
        return sms


class NetworkStatusParser(Parser):
    """
    Parser that returns a NetworkStatus object.
    """

    @staticmethod
    def parse(content):
        data = utils.split_str(content[0][content[0].index(':') + 1:])

        status = response_objects.NetworkStatus(data[0].strip(), int(data[1]))

        if len(data) == 4:
            status.lac = data[2][1:-1]
            status.ci = data[3][1:-1]

        return status


class SignalQualityParser(Parser):
    """
    Parser that returns a SignalQuality object.
    """

    @staticmethod
    def parse(content):
        data = utils.split_str(content[0][content[0].index(':') + 1:])
        return response_objects.SignalQuality(data[0].strip(), data[1])


class PinStatusParser(Parser):
    """
    Parser that returns a PinStatus object.
    """

    @staticmethod
    def parse(content):
        return response_objects.PINStatus(utils.split_str(content[0][content[0].index(':') + 1:])[0].strip())


class IMEIParser(Parser):
    """
    Parser that returns a IMEI object.
    """

    @staticmethod
    def parse(content):
        return response_objects.IMEI(content[0])


class SubscriberNumberParser(Parser):
    """
    Parser that returns a SubscriberNumber object.
    """

    @staticmethod
    def parse(content):
        data = utils.split_str(content[0][content[0].index(':') + 1:])

        number = response_objects.SubscriberNumber(data[1][1:-1], data[2])

        if data[0].strip():
            number.alpha = data[0].strip()

        if len(data) == 5:
            number.speed = data[3]
            number.service = data[4]

        return number


class IMSIParser(Parser):
    """
    Parser that returns an IMSI object.
    """

    @staticmethod
    def parse(content):
        mcc = content[0][:3]
        mnc = content[0][3:5]
        msin = content[0][5:]

        with open(get_config()['DEFAULT']['apnfile']) as f:
            data = json.load(f)

            country = None
            iso = None
            network = None

            if mcc in data:
                country = data[mcc]['country']
                iso = data[mcc]['iso']

                if mnc in data[mcc]:
                    network = data[mcc][mnc]

            return response_objects.IMSI(mcc, mnc, msin, network, country, iso)


class CallerIdentificationParser(Parser):
    """
    Parser that returns the caller number.
    """

    @staticmethod
    def parse(content):
        data = utils.split_str(content[0][content[0].index(':') + 1:])
        return data[0].strip()
