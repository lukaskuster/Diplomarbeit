#!/usr/bin/env bash

scp -r src gateway@raspberrypi.local:/home/gateway
scp setup.py gateway@raspberrypi.local:/home/gateway
scp apn-conf.json gateway@raspberrypi.local:/home/gateway
scp config.ini gateway@raspberrypi.local:/home/gateway


# Only for development
scp -r tests gateway@raspberrypi.local:/home/gateway
scp test_files/bubble.wav gateway@raspberrypi.local:/home/gateway
