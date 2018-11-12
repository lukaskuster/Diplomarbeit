from enum import IntEnum, Enum
import attr


class PINStatus(Enum):
    Ready = 'READY'
    Pin = 'SIM PIN'
    Puk = 'SIM PUK'
    PHPin = 'PH_SIM PIN'
    PHPuk = 'PH_SIM PUK'
    Pin2 = 'SIM PIN2'


@attr.s
class NetworkStatus:
    class Status(IntEnum):
        NotRegistered = 0
        RegisteredHome = 1
        Searching = 2
        Denied = 3
        Unknown = 4
        RegisteredRoaming = 5
    n = attr.ib()
    stat = attr.ib()
    lac = attr.ib(default=None)
    ci = attr.ib(default=None)

    def __attrs_post_init__(self):
        self.stat = self.Status(self.stat)


@attr.s
class SignalQuality:
    rssi: attr.ib()
    ber: attr.ib()


class SMS:
    pass
