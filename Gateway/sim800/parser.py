import utils
import sim800.response_objects as response_objects


class Parser:
    @staticmethod
    def parse(content):
        return None


class SMSListParser(Parser):
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
    @staticmethod
    def parse(content):
        data = utils.split_str(content[0][content[0].index(': ') + 2:])

        status = response_objects.NetworkStatus(data[0], int(data[1]))

        if len(data) == 4:
            status.lac = data[2]
            status.ci = data[3]

        return status


class SignalQualityParser(Parser):
    @staticmethod
    def parse(content):
        data = utils.split_str(content[0][content[0].index(': ') + 2:])
        return response_objects.SignalQuality(data[0], data[1])


class PinStatusParser(Parser):
    @staticmethod
    def parse(content):
        return response_objects.PINStatus(content[0])


class IMEIParser(Parser):
    @staticmethod
    def parse(content):
        return response_objects.IMEI(content[0])
