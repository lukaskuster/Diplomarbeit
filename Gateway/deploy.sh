#!/usr/bin/env bash

scp dist/gateway-0.1.0.tar.gz gateway@raspberrypi.local:/home/gateway
scp apn-conf.json gateway@raspberrypi.local:/home/gateway
scp config.ini gateway@raspberrypi.local:/home/gateway


# Only for development
scp -r tests gateway@raspberrypi.local:/home/gateway
