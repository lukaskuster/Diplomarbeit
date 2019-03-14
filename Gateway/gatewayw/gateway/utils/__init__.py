import configparser

from gateway.utils.logger import Logger, Level, AnsiEscapeSequence
from gateway.utils.scheduler import Task, Scheduler
from gateway.utils.singleton import Singleton
from gateway.utils.string_utils import clear_str, split_str


logger = Logger()


def use_config_file(path):
    logger.config = configparser.RawConfigParser()
    logger.config.read(path)
    logger.use_config_options()
