#!/usr/bin/env bash

scp -r controller quentin@128.199.42.182:/home/quentin/app
scp -r model quentin@128.199.42.182:/home/quentin/app
scp -r worker quentin@128.199.42.182:/home/quentin/app
scp -r middleware quentin@128.199.42.182:/home/quentin/app
scp package.json quentin@128.199.42.182:/home/quentin/app
scp package-lock.json quentin@128.199.42.182:/home/quentin/app
scp AuthKey_93W56D4882.p8 quentin@128.199.42.182:/home/quentin/app
scp voip.pem quentin@128.199.42.182:/home/quentin/app
scp voip.p12 quentin@128.199.42.182:/home/quentin/app




