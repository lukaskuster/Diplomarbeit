from enum import IntEnum, Enum
import attr


@attr.s
class IMEI:
    """
    Wrapper class for IMEI.
    """

    imei = attr.ib()


class PINStatus(Enum):
    """
    Enum for the pin status.
    """

    Ready = 'READY'
    Pin = 'SIM PIN'
    Puk = 'SIM PUK'
    PHPin = 'PH_SIM PIN'
    PHPuk = 'PH_SIM PUK'
    Pin2 = 'SIM PIN2'


@attr.s
class NetworkStatus:
    """
    Data class for the network status.

    The attribute names are the same as in the at-commands documentation
    (https://www.elecrow.com/download/SIM800%20Series_AT%20Command%20Manual_V1.09.pdf).
    Furthermore a enum for the actual status is defined within this class.
    """

    class Status(IntEnum):
        """
        Enum for the network status.
        """

        NotRegistered = 0
        RegisteredHome = 1
        Searching = 2
        Denied = 3
        Unknown = 4
        RegisteredRoaming = 5

    # Names defined like in the at-commands documentation
    n = attr.ib()
    stat = attr.ib()
    lac = attr.ib(default=None)
    ci = attr.ib(default=None)

    def __attrs_post_init__(self):
        """
        Sets self.stat to a Status object after the initialization.

        :return: nothing
        """

        self.stat = self.Status(self.stat)


@attr.s
class SignalQuality:
    """
    Data class for the signal quality.

    The attribute names are the same as in the at-commands documentation
    (https://www.elecrow.com/download/SIM800%20Series_AT%20Command%20Manual_V1.09.pdf).
    """

    rssi: attr.ib()
    ber: attr.ib()


@attr.s
class SMS:
    """
    Data class for a sms.
    """

    index: attr.ib()
    status: attr.ib()
    recipient: attr.ib()
    recipientText: attr.ib()
    time: attr.ib()
    message: attr.ib()


@attr.s
class SubscriberNumber:
    """
    Data class for subscriber number.
    """

    alpha: attr.ib()
    number: attr.ib()
    type: attr.ib()
    speed: attr.ib(default=None)
    service: attr.ib(default=None)

