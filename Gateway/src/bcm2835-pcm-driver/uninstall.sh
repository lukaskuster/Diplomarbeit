#!/usr/bin/env bash
sudo rmmod bcm2835_pcm
if [[ -e /dev/pcm ]] ; then
	sudo rm /dev/pcm
fi
if [[ -e bcm2835_pcm.c ]] ; then
	sudo make clean
fi
gpio -g mode 18 in
gpio -g mode 19 in
gpio -g mode 20 in
gpio -g mode 21 in

