from setuptools import find_packages
from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize


setup(
    name='gateway',
    version='0.1.0',
    ext_modules=cythonize([Extension("gateway.io.pcm.pcm", ["src/gateway/io/pcm/pcm.pyx"])]),
    package_dir={'': 'src'},
    packages=find_packages('src'),
    install_requires=['aiortc', 'websockets', 'av', 'pyee', 'attrs', 'asyncio',
                      'pyserial', 'requests', 'aioice'],
    entry_points={
        'console_scripts': ['gatewayw=gateway.core.main:start'],
    },
    author="Quentin Wendegass",
    author_email="quentin@wendegass.com",
)