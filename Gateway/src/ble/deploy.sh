#!/usr/bin/env bash

scp -r characteristics gateway@raspberrypi.local:/home/gateway/ble-setup/
scp -r services gateway@raspberrypi.local:/home/gateway/ble-setup/
scp index.js gateway@raspberrypi.local:/home/gateway/ble-setup/
scp package.json gateway@raspberrypi.local:/home/gateway/ble-setup/
scp package-lock.json gateway@raspberrypi.local:/home/gateway/ble-setup/
scp networkInterface.js gateway@raspberrypi.local:/home/gateway/ble-setup/