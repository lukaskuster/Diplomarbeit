#!/usr/bin/env bash

find src -type f -name "*.pyx" ! -name "__init__.py" -exec cython -3 {} \;
