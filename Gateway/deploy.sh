#!/usr/bin/env bash

scp -r sim800 gateway@raspberrypi.local:/home/gateway/src
scp Pipfile gateway@raspberrypi.local:/home/gateway/src
scp Pipfile.lock gateway@raspberrypi.local:/home/gateway/src
scp sim800_test.py gateway@raspberrypi.local:/home/gateway/src