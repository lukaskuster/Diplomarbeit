from setuptools import find_packages
from distutils.core import setup
from distutils.extension import Extension

try:
    from Cython.Build import cythonize
    ext = cythonize([Extension("gateway.io.pcm.pcm", ["src/gateway/io/pcm/pcm.pyx"]),
                     Extension("gateway.utils.string_utils", ["src/gateway/utils/string_utils.pyx"])])
except ImportError:
    ext = [Extension('gateway.io.pcm.pcm', ['src/gateway/io/pcm/pcm.c', 'src/pcmlib/pcmlib.c'], ['src/pcmlib/']),
           Extension('gateway.utils.string_utils', ['src/gateway/utils/string_utils.c', 'src/stringlib/stringlib.c'],
                     ['src/stringlib/'])]


setup(
    name='gateway',
    version='0.1.1',
    ext_modules=ext,
    package_dir={'': 'src'},
    packages=find_packages('src'),
    install_requires=['websockets', 'av', 'pyee', 'attrs', 'asyncio',
                      'pyserial', 'requests', 'aioice',
                      'aiortc-custom @ http://github.com/quentinwendegass/aiortc/tarball/master#egg=aiortc-custom-0.9.18'],
    entry_points={
        'console_scripts': ['gatewayw=gateway.core.main:start'],
    },
    author="Quentin Wendegass",
    author_email="quentin@wendegass.com",
)