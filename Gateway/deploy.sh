#!/usr/bin/env bash

# Main Program
scp dist/gateway-0.1.1.tar.gz gateway@raspberrypi.local:/home/gateway

# Config Files
scp apn-conf.json gateway@raspberrypi.local:/home/gateway
scp config.ini gateway@raspberrypi.local:/home/gateway

# PCM Driver
scp -r src/bcm2835-pcm-driver gateway@raspberrypi.local:/home/gateway

# Only for development
# Tests
scp -r tests gateway@raspberrypi.local:/home/gateway

# BLE Setup Program
cd src/ble
./deploy.sh

