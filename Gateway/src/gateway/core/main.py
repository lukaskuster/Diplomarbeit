import asyncio
import os
import sys
from functools import partial

from gateway.core import get_config, set_config
from gateway.io.sim800 import Sim800, Sim800Error
from gateway.networking import API, WebRTC, Role
from gateway.utils import logger, Level

logger.level = Level.DEBUG


if len(sys.argv) > 1:
    set_config(sys.argv[1])
elif os.path.isfile('config.ini'):
    set_config('config.ini')
else:
    raise FileNotFoundError('Config file not found!')


config = get_config()
auth_config = config['Auth']
API_HOST = config['Server']['apihost']
SIGNALING_HOST = config['Server']['signalinghost']
SERIAL_DEBUG = config['DEFAULT'].getboolean('serialdebug')
SERIAL_PORT = config['DEFAULT']['serialport']
PCM_DEBUG = config['DEFAULT'].getboolean('pcmdebug')


async def check_imei(sim):
    if 'imei' not in auth_config:
        event = await sim.request_imei()

        if event.error:
            logger.error('Sim800', 'RequestIMEIError({})'.format(event.error))

        auth_config['imei'] = event.data.imei

        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'config.ini'), 'w') as configfile:
            config.write(configfile)


async def main():
    sim = Sim800(debug=SERIAL_DEBUG, serial_port=SERIAL_PORT)

    if not SERIAL_DEBUG:
        try:
            await sim.setup(config['Test']['pin'])
        except Sim800Error as e:
            logger.error('Sim800', 'SimSetupError(Name: {}, Message: {})'.format(*e.args))
            logger.info('Gateway', 'Closing Program because Sim800 could not be initialized!')
            sys.exit(-1)

    await check_imei(sim)

    api = API(auth_config['user'], auth_config['password'], auth_config['imei'], host=API_HOST)

    logger.set_error_handler(api.push_error)

    webrtc = WebRTC(auth_config['user'], auth_config['password'], host=SIGNALING_HOST, debug=PCM_DEBUG)

    sim.on('ring', partial(on_outgoing_call, api, webrtc))

    api.on('holdCall', partial(on_hold_call, sim))
    api.on('resumeCall', partial(on_resume_call, sim))
    api.on('playDTMF', partial(on_play_dtmf, sim))
    api.on('hangUp', partial(on_hang_up, webrtc))  # Eventually not needed
    api.on('dial', partial(on_dial, sim, webrtc))
    api.on('clientDidDeclineCall', partial(on_hang_up, webrtc))
    api.on('clientDidAnswerCall', partial(on_answer_call, sim))
    api.on('requestSignal', partial(on_request_signal, sim, api))
    api.on('sendSMS', partial(on_send_sms, sim))

    webrtc.on('connectionClosed', partial(on_connection_closed, sim))
    webrtc.on('signalingTimeout', on_signaling_timeout)

    api.start()


# TODO: Outsource callbacks

# Sim Callbacks

async def on_outgoing_call(api, webrtc):
    api.push_incoming_call("+43111111111")
    if webrtc.is_ongoing():
        logger.info('WebRTC', "Already one call is active!")
        return
    webrtc.start_call(Role.OFFER)


# API Callbacks

async def on_resume_call(sim, data):
    event = await sim.resume_call()

    if event.error:
        logger.error('Sim800', 'ResumeCallError({})'.format(event.error))


async def on_hold_call(sim, data):
    event = await sim.hold_call()

    if event.error:
        logger.error('Sim800', 'HoldCallError({})'.format(event.error))


async def on_play_dtmf(sim, data):
    if not data:
        return logger.error('SSE', 'ArgumentError(data)')
    if 'digits' not in data:
        return logger.error('SSE', 'ArgumentError(digits)')

    event = await sim.transmit_dtmf_tone(data['digits'])

    if event.error:
        logger.error('Sim800', 'PlayDTMFError({})'.format(event.error))


async def on_hang_up(webrtc, data):
    logger.log('GATEWAY', 'Hang up call!')
    if webrtc.is_ongoing():
        webrtc.stop_call()


async def on_answer_call(sim, data):
    logger.log('GATEWAY', 'Answer call!')
    event = await sim.answer_call()
    if event.error:
        logger.error('Sim800', 'AnswerCallError({})'.format(event.error))


async def on_dial(sim, webrtc, data):
    logger.log('GATEWAY', 'Initialize Call!')

    if not data:
        return logger.error('SSE', 'ArgumentError(data)')
    if 'number' not in data:
        return logger.error('SSE', 'ArgumentError(number)')

    async def on_connection():
        logger.log('Sim800', 'Dial Number!')

        event = await sim.dial_number(data['number'])

        if event.error:
            logger.error('Sim800', 'DialError({})'.format(event.error))
            webrtc.stop_call()

    if webrtc.is_ongoing():
        logger.info('WebRTC', "Already one call is active!")
        return

    webrtc.once('connected', on_connection)
    webrtc.start_call(Role.ANSWER)


async def on_request_signal(sim, api, data):
    event = await sim.request_signal_quality()
    if not event.error:
        api.put_gateway(signal_strength=event.data.rssi)
    else:
        logger.error('Sim800', 'RequestSignalQualityError({})'.format(event.error))


async def on_send_sms(sim, data):
    if not data:
        return logger.error('SSE', 'ArgumentError(data)')
    if 'recipient' not in data:
        return logger.error('SSE', 'ArgumentError(recipient)')
    if 'message' not in data:
        return logger.error('SSE', 'ArgumentError(message)')

    event = await sim.send_sms(data['recipient'], data['message'])
    if event.error:
        logger.error('Sim800', 'SendSMSError({})'.format(event.error))


# WebRTC Callbacks

async def on_connection_closed(sim):
    logger.log('WebRTC', 'Conncection Closed!')
    event = await sim.hang_up_call()

    if event.error:
        logger.error('Sim800', 'HangUpError({})'.format(event.error))


async def on_signaling_timeout():
    pass


def start():
    asyncio.ensure_future(main())
    asyncio.get_event_loop().run_forever()


if __name__ == '__main__':
    start()
