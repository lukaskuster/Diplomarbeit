from setuptools import setup, Extension, find_packages, Command
from subprocess import call
import configparser

config = configparser.ConfigParser()
config.read('config.ini')


class CythonizeCommand(Command):
    user_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        call(['./compile_cython.sh'], shell=True)


# TODO: Don't hardcode this
networking_extensions = [
    Extension('gateway.networking.signaling', ['src/gateway/networking/signaling.c']),
    Extension('gateway.networking.webrtc', ['src/gateway/networking/webrtc.c']),
    Extension('gateway.networking.track', ['src/gateway/networking/track.c']),
    Extension('gateway.networking.api', ['src/gateway/networking/api.c']),
    Extension('gateway.networking.sse', ['src/gateway/networking/sse.c'])
]

io_extensions = [
    Extension('gateway.io.sim800.at_command', ['src/gateway/io/sim800/at_command.c']),
    Extension('gateway.io.sim800.at_event', ['src/gateway/io/sim800/at_event.c']),
    Extension('gateway.io.sim800.parser', ['src/gateway/io/sim800/parser.c']),
    Extension('gateway.io.sim800.response_objects', ['src/gateway/io/sim800/response_objects.c']),
    Extension('gateway.io.sim800.serial_loop', ['src/gateway/io/sim800/serial_loop.c']),
    Extension('gateway.io.sim800.sim800', ['src/gateway/io/sim800/sim800.c'])
]

utils_extensions = [
    Extension('gateway.utils.config', ['src/gateway/utils/config.c']),
    Extension('gateway.utils.logger', ['src/gateway/utils/logger.c']),
    Extension('gateway.utils.singleton', ['src/gateway/utils/singleton.c']),
    Extension('gateway.utils.string_utils', ['src/gateway/utils/string_utils.c']),
    Extension('gateway.utils.scheduler', ['src/gateway/utils/scheduler.c'])
]

setup(
    cmdclass={
        'cythonize': CythonizeCommand
    },
    name='gateway',
    version="0.0.2",
    ext_modules=[*io_extensions, *networking_extensions, *utils_extensions],
    package_dir={'': 'src'},
    install_requires=['aiortc', 'websockets', 'av', 'pyee', 'attr', 'asyncio',
                      'pyserial', 'requests', 'aioice'],
    packages=find_packages('src'),
    data_files=[('/gateway/utils', ['config.ini']),
                ('/gateway/io/sim800', [config['DEFAULT']['apnfile']]),
                # DEVELOPMENT ONLY
                ('/gateway/networking', ['test_files/' + config['Test']['audiofile']])],
    entry_points={
        'console_scripts': ['gatewayw=gateway.core.main:start'],
    },
    author="Quentin Wendegass",
    author_email="quentin@wendegass.com",
)