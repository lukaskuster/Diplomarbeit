from backend import API
from utils import logger


def run():
    api = API('quentin@wendegass.com', 'test123', 'wed', host='http://localhost:3000/v1')

    @api.on('test')
    def test_notification(data):
        logger.info('Test', 'Received notification {}'.format(str(data)))

    @api.on('connectionstatechange')
    def on_connection_state_change(state):
        state = logger.AnsiEscapeSequence.UNDERLINE + state + logger.AnsiEscapeSequence.DEFAULT
        logger.info('Connection State', 'Connection state changed to ' + state)

    @api.on('connectionfailed')
    def on_connection_failed(error):
        logger.error('Connection', 'An error occurred (' + error['error'] + ')')

    @api.on('connectionaborted')
    def on_connection_aborted():
        logger.error('Connection', 'Connection was aborted!')

    @api.on('connectionrefused')
    def on_connection_refused():
        logger.error('Connection', 'Can not connect to host!')

    @api.once('connect')
    def on_connect():
        logger.info('Connection', 'Connected with host!')
        logger.log('Tests[Put User]', 'Response = ' + str(api.put_user('Quentin', 'Wendegass')))
        logger.log('Tests[Get User]', 'Response = ' + str(api.get_user()))
        logger.log('Tests[Post Gateway]', 'Response = ' + str(api.post_gateway('test1231231')))
        logger.log('Tests[Put Gateway]', 'Response = ' + str(api.put_gateway('test1231231', 4423)))
        logger.log('Tests[Get Gateway]', 'Response = ' + str(api.get_gateway('test1231231')))
        logger.log('Tests[Delete Gateway]', 'Response = ' + str(api.delete_gateway('test1231231')))
        logger.log('Tests[Get Gateways]', 'Response = ' + str(api.get_gateways()))

    api.start()


if __name__ == '__main__':
    logger.level = logger.Level.DEBUG

    try:
        run()
    except Exception as e:
        print(e)
