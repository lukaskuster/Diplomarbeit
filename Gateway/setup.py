from setuptools import setup, Extension, find_packages, Command

from subprocess import call
import configparser
from os import path, walk

config = configparser.ConfigParser()
config.read('config.ini')

try:
    from Cython.Build import cythonize
except ImportError:
    use_cython = False
else:
    use_cython = True


def after(value, a):
    pos_a = value.rfind(a)
    if pos_a == -1:
        return ""
    adjusted_pos_a = pos_a + len(a)
    if adjusted_pos_a >= len(value):
        return ""
    return value[adjusted_pos_a:]


if use_cython:
    extensions = cythonize('src/**/*.py', exclude='src/**/__init__.py')
else:
    extensions = []

    dir_path = path.dirname(path.realpath(__file__))
    for subdir, dirs, files in walk(path.join(dir_path, 'src', 'gateway')):
        for file in files:
            file_path = path.join(subdir, file)
            filename, file_extension = path.splitext(file_path)
            if file_extension == '.c':
                extensions.append(Extension(after(filename.replace(path.sep, '.'), 'src.'), [file_path]))


class CythonizeCommand(Command):
    user_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        call(['./compile_cython.sh'], shell=True)


setup(
    cmdclass={
        'cythonize': CythonizeCommand
    },
    name='gateway',
    # TODO: Not working with pip install, because config.ini is not present
    # version=config['DEFAULT']['version'],
    version='0.0.3',
    ext_modules=extensions,
    package_dir={'': 'src'},
    packages=find_packages('src'),
    install_requires=['aiortc', 'websockets', 'av', 'pyee', 'attr', 'asyncio',
                      'pyserial', 'requests', 'aioice'],
    entry_points={
        'console_scripts': ['gatewayw=gateway.core.main:start'],
    },
    author="Quentin Wendegass",
    author_email="quentin@wendegass.com",
)