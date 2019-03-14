import configparser
from gateway.utils import logger, AnsiEscapeSequence

config = None


def get_config():
    return config


def set_config(path):
    logger.info('Gateway', 'Using config path: {}{}{}'
                .format(AnsiEscapeSequence.HEADER, path, AnsiEscapeSequence.DEFAULT))
    global config
    config = configparser.ConfigParser()
    config.read(path)
