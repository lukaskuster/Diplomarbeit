#!/usr/bin/env bash

# Install the required build-tools
sudo apt-get update
sudo apt-get install build-essential tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libssl-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev libffi-dev libsrtp2-dev

# Download and install Python 3.6
wget https://www.python.org/ftp/python/3.6.5/Python-3.6.5.tar.xz
tar xf Python-3.6.5.tar.xz
cd Python-3.6.5
./configure
make
sudo make altinstall

# Clean up and remove unused packages
# TODO: Only remove packages that were not installed previously on the system
sudo rm -r Python-3.6.5
rm Python-3.6.5.tar.xz
sudo apt-get --purge remove build-essential tk-dev
sudo apt-get --purge remove libncurses5-dev libncursesw5-dev libreadline6-dev
sudo apt-get --purge remove libdb5.3-dev libgdbm-dev libsqlite3-dev
sudo apt-get --purge remove libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev
sudo apt-get autoremove
sudo apt-get clean

# Upgrade pip
sudo pip3.6 install --upgrade pip