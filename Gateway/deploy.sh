#!/usr/bin/env bash

scp -r sim800 gateway@raspberrypi.local:/home/gateway/src
scp -r backend gateway@raspberrypi.local:/home/gateway/src
scp -r call gateway@raspberrypi.local:/home/gateway/src
scp main.py gateway@raspberrypi.local:/home/gateway/src
scp config.ini gateway@raspberrypi.local:/home/gateway/src
scp Pipfile gateway@raspberrypi.local:/home/gateway/src
scp Pipfile.lock gateway@raspberrypi.local:/home/gateway/src
scp apn-conf.json gateway@raspberrypi.local:/home/gateway/src

# Only for development
scp -r tests gateway@raspberrypi.local:/home/gateway/src
