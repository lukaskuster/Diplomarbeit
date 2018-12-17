from gateway.networking import WebRTC, Role
from gateway.utils import logger, Level
from gateway.core import set_config
import asyncio
import sys

logger.level = Level.DEBUG

USERNAME = 'quentin@wendegass.com'
PASSWORD = 'test123'
HOST = 'wss://signaling.da.digitalsubmarine.com:443'


def test_answer():
    con = WebRTC(USERNAME, PASSWORD, HOST)
    con.start_call(Role.ANSWER)


def test_offer():
    con = WebRTC(USERNAME, PASSWORD, HOST)
    con.start_call(Role.OFFER)


if __name__ == '__main__':
    if len(sys.argv) >= 2:
        if sys.argv[1] == 'offer':
            test_offer()
        elif sys.argv[1] == 'answer':
            test_answer()
        else:
            raise ValueError('No proper role!')
    else:
        test_offer()

    set_config('config.ini')
    asyncio.get_event_loop().run_forever()
