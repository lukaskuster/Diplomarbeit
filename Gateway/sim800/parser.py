import json
import utils
import sim800.response_objects as response_objects
from utils.config import config


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
            data = utils.split_str(line[line.index(': ') + 2:])
            # Add a new sms object to the list
            sms.append(response_objects.SMS(
                int(data[0]), data[1][1:-1], data[2][1:-1], data[3][1:-1], data[4][1:-1], content[i * 2 + 1]
            ))
        return sms


class NetworkStatusParser(Parser):
    """
    Parser that returns a NetworkStatus object.
    """

    @staticmethod
    def parse(content):
        data = utils.split_str(content[0][content[0].index(': ') + 2:])

        status = response_objects.NetworkStatus(data[0], int(data[1]))

        if len(data) == 4:
            status.lac = data[2]
            status.ci = data[3]

        return status


class SignalQualityParser(Parser):
    """
    Parser that returns a SignalQuality object.
    """

    @staticmethod
    def parse(content):
        data = utils.split_str(content[0][content[0].index(': ') + 2:])
        return response_objects.SignalQuality(data[0], data[1])


class PinStatusParser(Parser):
    """
    Parser that returns a PinStatus object.
    """

    @staticmethod
    def parse(content):
        return response_objects.PINStatus(content[0])


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
        data = utils.split_str(content[0][content[0].index(': ') + 2:])

        number = response_objects.SubscriberNumber(data[0], data[1], data[2])

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

        with open(config['DEFAULT']['apnfile']) as f:
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
