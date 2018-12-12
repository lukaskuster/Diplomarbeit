#!/usr/bin/env bash

scp dist/gateway-0.0.2.tar.gz gateway@raspberrypi.local:/home/gateway

# Only for development
scp -r tests gateway@raspberrypi.local:/home/gateway
