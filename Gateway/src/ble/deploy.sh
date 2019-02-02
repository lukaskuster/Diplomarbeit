#!/usr/bin/env bash

scp -r characteristics gateway@raspberrypi.local:/home/gateway/ble/
scp -r services gateway@raspberrypi.local:/home/gateway/ble/
scp index.js gateway@raspberrypi.local:/home/gateway/ble
scp package.json gateway@raspberrypi.local:/home/gateway/ble
scp package-lock.json gateway@raspberrypi.local:/home/gateway/ble
scp networkInterface.js gateway@raspberrypi.local:/home/gateway/ble