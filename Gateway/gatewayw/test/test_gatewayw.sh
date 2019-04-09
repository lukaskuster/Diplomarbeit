#!/usr/bin/env bash

gatewayw ${1} &
sleep 30

GATEWAYW_PID=$(pgrep -x gatewayw)

if [[ -z "$GATEWAYW_PID" ]]
then
      exit 1
else
    sudo kill -9 ${GATEWAYW_PID}
    exit 0
fi