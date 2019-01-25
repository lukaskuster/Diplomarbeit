import configparser

config = None


def get_config():
    return config


def set_config(path):
    global config
    config = configparser.ConfigParser()
    config.read(path)
