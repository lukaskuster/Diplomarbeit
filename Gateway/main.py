from backend import API
from call.webrtc import WebRTC
from utils import logger, Level
import sim800.sim800 as sim800
Sim800 = sim800.Sim800


logger.level = Level.DEBUG

GATEWAY_ID = 'd5df5dfc-d374-4158-918e-2051a2f0793b'
USER = 'quentin@wendegass.com'
PASSWORD = 'test123'
HOST = 'http://localhost:3000/v1'


def main():
    # Pass no gateway id on first start and save the id (imei) that gets set
    api = API(USER, PASSWORD)
    sim = Sim800(debug=True)
    webrtc = WebRTC(USER, PASSWORD)

    @sim.on('ring')
    def on_outgoing_call():
        if webrtc.is_ongoing():
            logger.info('WebRTC', "Already one call is active!")
        webrtc.start_call('offer')

    @api.on('hangUp')
    def on_hang_up(data):
        logger.log('SSE', 'Hang up call!')
        if webrtc.is_ongoing():
            webrtc.stop_call()

    @api.on('dial')
    def on_dial(data):
        logger.log('SSE', 'Initialize Call!')

        if not data:
            logger.error('SSE', 'Dial Event - No data!')
            return
        if 'number' not in data:
            logger.error('SSE', 'Dial Event - No "number" property in data!')
            return

        if webrtc.is_ongoing():
            logger.info('WebRTC', "Already one call is active!")
        webrtc.start_call('answer')

        def dial_number_callback(e):
            if e.error_message:
                logger.error('Sim800', 'Failed to dial number: ' + e.error_message)

        sim.dial_number(data['number'], callback=dial_number_callback)

    @api.on('requestSignal')
    def on_request_signal(data):
        def signal_quality_callback(e):
            if e.error:
                logger.error('Sim800', 'Failed to get signal strength: ' + e.error_message)
                return
            api.put_gateway(e.data['rssi'])

        sim.request_signal_quality(callback=signal_quality_callback)

    @api.on('sendSMS')
    def on_send_sms(data):
        # recipient: phone number
        # message: message
        pass

    @webrtc.on('connectionClosed')
    def on_connection_closed():
        logger.log('WebRTC', 'Conncection Closed!')
        sim.hang_up_call()

    api.start()
    webrtc.run_forever()


if __name__ == '__main__':
    main()
