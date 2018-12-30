#!/usr/bin/env bash

# Set GPIO alternate functions
gpio_alt -p 18 -f 0
gpio_alt -p 19 -f 0
gpio_alt -p 20 -f 0
gpio_alt -p 21 -f 0

# Build and install PCM kernel module
if [[ -e bcm2835_pcm.c ]] ; then
	sudo make
else
	echo "No source found. Continuing..."
fi

if [[ -e bcm2835_pcm.ko ]] ; then
	sudo insmod bcm2835_pcm.ko
	MAJOR="$(grep bcm2835_pcm /proc/devices | awk '{print $1}')"
	sudo mknod /dev/pcm c ${MAJOR} 0
	sudo chmod 666 /dev/pcm
else
	echo "bcm2835_pcm.ko doesn't exist. Exiting."
	exit 1
fi
