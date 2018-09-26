#!/usr/bin/env bash

scp -r sim800 gateway@10.68.42.60:/home/gateway/src
scp Pipfile gateway@10.68.42.60:/home/gateway/src
scp Pipfile.lock gateway@10.68.42.60:/home/gateway/src
scp sim800_test.py gateway@10.68.42.60:/home/gateway/src