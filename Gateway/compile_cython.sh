#!/usr/bin/env bash

find src -type f -name "*.py" ! -name "*__init__.py" -exec cython -3 {} \;
