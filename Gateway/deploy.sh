#!/usr/bin/env bash

# Install scripts and res
scp res/gpio_alt.c gateway@raspberrypi.local:/home/gateway
scp res/install_gpio_alt.sh gateway@raspberrypi.local:/home/gateway
scp res/install_python3.6.sh gateway@raspberrypi.local:/home/gateway
scp res/install_wiringpi.sh gateway@raspberrypi.local:/home/gateway
scp install.sh gateway@raspberrypi.local:/home/gateway

# Main Program
scp dist/gateway-0.1.1.tar.gz gateway@raspberrypi.local:/home/gateway/gatewayw
scp gatewayw.service gateway@raspberrypi.local:/home/gateway/gatewayw

# Config Files
scp apn-conf.json gateway@raspberrypi.local:/home/gateway
scp config.ini gateway@raspberrypi.local:/home/gateway

# PCM Driver
scp -r src/bcm2835-pcm-driver gateway@raspberrypi.local:/home/gateway

# BLE Setup Program
cd src/ble
./deploy.sh
cd ../..


# Only for development
# Tests
scp -r tests gateway@raspberrypi.local:/home/gateway
