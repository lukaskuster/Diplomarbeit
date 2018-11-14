from backend import API
from call.webrtc import WebRTC
from utils import logger, Level
import asyncio
import configparser
import sim800.sim800 as sim800
Sim800 = sim800.Sim800


logger.level = Level.DEBUG

config = configparser.ConfigParser()
config.read('config.ini')

auth_config = config['Auth']
API_HOST = config['Server']['apihost']
SIGNALING_HOST = config['Server']['signalinghost']
SERIAL_DEBUG = config['DEFAULT'].getboolean('serialdebug')
SERIAL_PORT = config['DEFAULT']['serialport']


async def check_imei(sim):
    if 'imei' not in auth_config:
        event = await sim.request_imei()

        if event.error:
            logger.info('Sim800', "Error at request imei at-command: {}".format(event))

        auth_config['imei'] = event.data.imei

        with open('config.ini', 'w') as configfile:
            config.write(configfile)


async def main():
    sim = Sim800(debug=SERIAL_DEBUG, serial_port=SERIAL_PORT)

    await check_imei(sim)

    api = API(auth_config['user'], auth_config['password'], auth_config['imei'], host=API_HOST)
    webrtc = WebRTC(auth_config['user'], auth_config['password'], host=SIGNALING_HOST)

    @sim.on('ring')
    async def on_outgoing_call():

        # TODO: Push notification to device

        if webrtc.is_ongoing():
            logger.info('WebRTC', "Already one call is active!")
            return
        webrtc.start_call('offer')

    @api.on('hangUp')
    async def on_hang_up(data):
        logger.log('SSE', 'Hang up call!')
        if webrtc.is_ongoing():
            webrtc.stop_call()

    @api.on('dial')
    async def on_dial(data):
        logger.log('SSE', 'Initialize Call!')

        if not data:
            return logger.error('SSE', 'Dial Event - No data!')
        if 'number' not in data:
            return logger.error('SSE', 'Dial Event - No "number" property in data!')

        event = await sim.dial_number(data['number'])

        if not event.error:
            if webrtc.is_ongoing():
                logger.info('WebRTC', "Already one call is active!")
                return
            webrtc.start_call('answer')
        else:
            logger.info('Sim800', "Error at dial at-command: {}".format(event))

    @api.on('requestSignal')
    async def on_request_signal(data):
        event = await sim.request_signal_quality()
        if not event.error:
            api.put_gateway(event.data.rssi)
        else:
            logger.info('Sim800', "Error at signal quality at-command: {}".format(event))

    @api.on('sendSMS')
    async def on_send_sms(data):
        if not data:
            return logger.error('SSE', 'Send SMS Event - No data!')
        if 'recipient' not in data:
            return logger.error('SSE', 'SEND SMS EVENT - No "recipient" property in data!')
        if 'message' not in data:
            return logger.error('SSE', 'SEND SMS EVENT - No "message" property in data!')

        event = await sim.set_sms_mode(1)
        if event.error:
            logger.info('Sim800', "Error at set sms mode at-command: {}".format(event))
            return

        event = await sim.send_sms(data['recipient'], data['message'])
        if event.error:
            logger.info('Sim800', "Error at send sms at-command: {}".format(event))
            return

    @webrtc.on('connectionClosed')
    async def on_connection_closed():
        logger.log('WebRTC', 'Conncection Closed!')
        event = await sim.hang_up_call()

        if event.error:
            logger.info('Sim800', "Error at hang up at-command: {}".format(event))

    api.start()


if __name__ == '__main__':
    asyncio.ensure_future(main())
    asyncio.get_event_loop().run_forever()

