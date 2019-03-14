import asyncio
import os
import uuid
import sys
from functools import partial

from gateway.core import get_config, set_config
from gateway.io.sim800 import Sim800, Sim800Error, at_response
from gateway.networking import API, Caller, Role
from gateway.utils import logger, use_config_file


config = None
auth_config = None
config_path = None


async def check_pin_status(sim: Sim800, api: API):
    event = await sim.request_pin_status()
    if event.error_message:
        return logger.error('Sim800', 'RequestPinStatusError({})'.format(event.error_message))

    if event.data != at_response.PINStatus.Ready:
        logger.info('Sim800', 'Sim card locked with {}'.format(event.data))
        api.put_gateway(pin_required=True)
    else:
        logger.info('Sim800', 'Sim card ready!')
        api.put_gateway(pin_required=False)


async def check_imei(sim):
    global config_path, config, auth_config
    if 'imei' not in auth_config:
        event = await sim.request_imei()

        if event.error:
            logger.error('Sim800', 'RequestIMEIError({})'.format(event.error_message))
            auth_config['imei'] = uuid.uuid1()
            logger.info('Gateway', 'Generating unique uuid to replace imei: {}'.format(auth_config['imei']))
        else:
            auth_config['imei'] = event.data.imei
            logger.info('Gateway', 'Set imei: {}'.format(event.data.imei))

    logger.debug('Gateway', 'Open config file...')
    with open(config_path, 'w') as configfile:
        logger.debug('Gateway', 'Write to config file...')
        config.write(configfile)


async def main():
    global config, auth_config, config_path
    API_HOST = config['Server']['apihost']
    SIGNALING_HOST = config['Server']['signalinghost']
    SERIAL_DEBUG = config['DEFAULT'].getboolean('serialdebug')
    SERIAL_PORT = config['DEFAULT']['serialport']
    PCM_DEBUG = config['DEFAULT'].getboolean('pcmdebug')

    logger.info('Gateway', 'Serial debug = {}'.format(SERIAL_DEBUG))
    logger.info('Gateway', 'PCM debug = {}'.format(PCM_DEBUG))
    sim = Sim800(debug=SERIAL_DEBUG, serial_port=SERIAL_PORT)

    if not SERIAL_DEBUG:
        await check_imei(sim)

    logger.info('Gateway', 'Connecting with user: {}'.format(auth_config['user']))

    api = API(auth_config['user'], auth_config['password'], auth_config['imei'], host=API_HOST)

    if not SERIAL_DEBUG:
        pin = None
        if 'pin' in auth_config:
            pin = auth_config['pin']
        try:
            await sim.setup(pin)
        except Sim800Error as e:
            logger.error('Sim800', 'SimSetupError(Name: {}, Message: {})'.format(*e.args))
            logger.info('Gateway', 'Closing Program because Sim800 could not be initialized!')
            sys.exit(-1)

        await check_pin_status(sim, api)

    logger.set_error_handler(api.push_error)

    caller = Caller(auth_config['user'], auth_config['password'], auth_config['imei'], host=SIGNALING_HOST, debug=PCM_DEBUG)

    sim.on('ring', partial(on_outgoing_call, api, caller))

    api.on('holdCall', partial(on_hold_call, sim))
    api.on('resumeCall', partial(on_resume_call, sim))
    api.on('playDTMF', partial(on_play_dtmf, sim))
    api.on('hangUp', partial(on_hang_up, caller))  # Eventually not needed
    api.on('dial', partial(on_dial, sim, caller))
    api.on('clientDidAnswerCall', partial(on_answer_call, sim))
    api.on('requestSignal', partial(on_request_signal, sim, api))
    api.on('sendSMS', partial(on_send_sms, sim))
    api.on('enterPIN', partial(on_enter_pin, sim, api))

    caller.on('connectionClosed', partial(on_connection_closed, sim))
    caller.on('signalingTimeout', on_signaling_timeout)

    api.start()


# TODO: Outsource callbacks

# Sim Callbacks

async def on_outgoing_call(api, caller, data):
    api.push_incoming_call("+436503333997")
    if caller.is_ongoing():
        logger.info('WebRTC', "Already one call is active!")
        return
    caller.start_call(Role.OFFER)


# API Callbacks

async def on_resume_call(sim, data):
    event = await sim.resume_call()

    if event.error:
        logger.error('Sim800', 'ResumeCallError({})'.format(event.error_message))


async def on_hold_call(sim, data):
    event = await sim.hold_call()

    if event.error:
        logger.error('Sim800', 'HoldCallError({})'.format(event.error_message))


async def on_play_dtmf(sim, data):
    if not data:
        return logger.error('SSE', 'ArgumentError(data)')
    if 'digits' not in data:
        return logger.error('SSE', 'ArgumentError(digits)')

    event = await sim.transmit_dtmf_tone(data['digits'])

    if event.error:
        logger.error('Sim800', 'PlayDTMFError({})'.format(event.error_message))


async def on_hang_up(caller, data):
    logger.log('GATEWAY', 'Hang up call!')
    if caller.is_ongoing():
        caller.stop_call()


async def on_answer_call(sim, data):
    logger.log('GATEWAY', 'Answer call!')
    event = await sim.answer_call()
    if event.error:
        logger.error('Sim800', 'AnswerCallError({})'.format(event.error_message))


async def on_dial(sim, caller, data):
    logger.log('GATEWAY', 'Initialize Call!')

    if not data:
        return logger.error('SSE', 'ArgumentError(data)')
    if 'number' not in data:
        return logger.error('SSE', 'ArgumentError(number)')

    async def on_connection():
        logger.log('Sim800', 'Dial Number!')

        event = await sim.dial_number(data['number'])

        if event.error:
            logger.error('Sim800', 'DialError({})'.format(event.error_message))
            caller.stop_call()

    if caller.is_ongoing():
        logger.info('WebRTC', "Already one call is active!")
        return

    caller.once('connected', on_connection)
    caller.start_call(Role.ANSWER)


async def on_request_signal(sim, api, data):
    event = await sim.request_signal_quality()
    if not event.error:
        api.put_gateway(signal_strength=event.data.rssi)
    else:
        logger.error('Sim800', 'RequestSignalQualityError({})'.format(event.error_message))


async def on_send_sms(sim, data):
    if not data:
        return logger.error('SSE', 'ArgumentError(data)')
    if 'recipient' not in data:
        return logger.error('SSE', 'ArgumentError(recipient)')
    if 'message' not in data:
        return logger.error('SSE', 'ArgumentError(message)')

    event = await sim.send_sms(data['recipient'], data['message'])
    if event.error:
        logger.error('Sim800', 'SendSMSError({})'.format(event.error_message))


async def on_enter_pin(sim: Sim800, api: API, data):
    if not data:
        return logger.error('SSE', 'ArgumentError(data)')
    if 'pin' not in data:
        return logger.error('SSE', 'ArgumentError(pin)')

    event = await sim.enter_pin(data['pin'])
    if event.error:
        return logger.error('Sim800', 'EnterPINError({})'.format(event.error_message))

    event = await sim.request_pin_status()
    if event.error:
        return logger.error('Sim800', 'RequestPINStatusError({})'.format(event.error_message))

    if event.data == at_response.PINStatus.Ready:
        logger.info('Gateway', 'PIN was entered successful!')
        auth_config['pin'] = data['pin']
        api.put_gateway(pin_required=False)
    else:
        logger.error('Gateway', 'WrongPINError')
        api.broadcast_notification('invalidPIN', silent=True, voip=True)


# WebRTC Callbacks

async def on_connection_closed(sim):
    logger.log('WebRTC', 'Connection Closed!')
    event = await sim.hang_up_call()

    if event.error:
        logger.error('Sim800', 'HangUpError({})'.format(event.error_message))


async def on_signaling_timeout():
    pass


def start():
    global config, auth_config, config_path
    config_env = os.environ.get('GATEWAYCONFIGPATH')

    if len(sys.argv) > 1:
        config_path = os.path.join(sys.argv[1], 'config.ini')
    elif config_env:
        config_path = os.path.join(config_env, 'config.ini')
    elif os.path.isfile('/etc/gateway/config.ini'):
        config_path = '/etc/gateway/config.ini'
    else:
        raise FileNotFoundError('Config file not found!')

    set_config(config_path)

    if os.path.isfile('/etc/gateway/log-config.ini'):
        use_config_file('/etc/gateway/log-config.ini')
    elif config_env:
        use_config_file(os.path.join(config_env, 'log-config.ini'))

    config = get_config()
    auth_config = config['Auth']

    asyncio.ensure_future(main())
    try:
        asyncio.get_event_loop().run_forever()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    start()
