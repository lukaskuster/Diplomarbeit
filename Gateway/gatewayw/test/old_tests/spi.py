"""
To run the codec in PCM mode, pull SDI to High on power up or reset.


Pins on Raspberry Pi for SPI:

MISO: 9
MOSI: 10
SCLK: 11
CE0 (CS): 8


Copy script to raspberry (local):

scp spi_interface.py gateway@raspberrypi.local:/home/gateway/src


Install pigpio (remote):

sudo apt-get update
sudo apt-get install pigpio 
sudo systemctl start pigpiod
sudo systemctl enable pigpiod


Enter virtual environment and install pgpio for python (remote):

cd /home/gateway/src
sudo -E pipenv shell
pipenv install pigpio


Run test script (remote):

python spi_interface.py 
"""

import time
import pigpio

CHANNEL = 0     # For CE0
BAUD_RATE = 5000000


def address(addr):
    def decorator(cls):
        setattr(cls, '_address', addr)
        setattr(cls, 'address', property(lambda x: getattr(cls, '_address')))
        return cls
    return decorator


def null_bits(*args):
    def decorator(cls):
        setattr(cls, '_null_bits', args)
        return cls
    return decorator


class Register(object):

    def write(self, connection, handle):
        data = [getattr(self, k) for k in self.__class__.__dict__.keys() if not k.startswith('_')
                and k not in ['write', 'read', 'address']]

        if hasattr(self, '_null_bits'):
            for i in self._null_bits:
                data.insert(i, 0)

        if len(data) != 8:
            raise ValueError('Length of data should be 8!')

        if hasattr(self, 'address'):
            print(int(''.join([str(x) for x in data]), 2))
            connection.spi_write(handle, [(0xB << 4) | self.address, int(''.join([str(x) for x in data]), 2)])
        else:
            raise AttributeError('Address not defined!')

    def read(self, connection, handle):
        if hasattr(self, 'address'):
            count, data = connection.spi_xfer(handle, [(0xA << 4) | self.address])
            print('Got {} bytes with data: {}'.format(count, data))
            #connection.spi_write(handle, [(0xA << 4) | self.address])
            #count, data = connection.spi_read(handle, 2)
            #print('Got {} bytes with data: {}'.format(count, data))

        else:
            raise AttributeError('Address not defined!')


@address(0x0)
@null_bits(1, 7)
class ModeControlRegister(Register):
    COMPANDING = 0
    ALB = 0
    DLB = 0
    PD = 0
    CPB = 0
    TXZ = 0


if __name__ == '__main__':
    pi = pigpio.pi()

    if not pi.connected:
        raise ConnectionError('Could not connect to pigpio!')

    h = pi.spi_open(CHANNEL, BAUD_RATE, pigpio.SPI_MODE_0)

    reg = ModeControlRegister()
    reg.PD = 0
    reg.write(pi, h)

    #pi.spi_write(h, b'\xB0\x08')
    #time.sleep(0.01)
    #pi.spi_write(h, b'\xA0')

    #m = ModeControlRegister()
    #m.read(pi, h)

    pi.spi_close(h)
    pi.stop()
