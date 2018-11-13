from backend import API
from call.webrtc import WebRTC
from utils import logger, Level
import asyncio
import sim800.sim800 as sim800
Sim800 = sim800.Sim800


logger.level = Level.DEBUG

GATEWAY_ID = 'd5df5dfc-d374-4158-918e-2051a2f0793b'
USER = 'quentin@wendegass.com'
PASSWORD = 'test123'
HOST = 'http://localhost:3000/v1'


def main():
    # Pass no gateway id on first start and save the id (imei) that gets set
    api = API(USER, PASSWORD, GATEWAY_ID)
    sim = Sim800(debug=True)
    webrtc = WebRTC(USER, PASSWORD)

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
    asyncio.get_event_loop().run_forever()


if __name__ == '__main__':
    main()
