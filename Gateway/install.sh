#!/usr/bin/env bash

MODULE_PATH=/usr/lib/
SCRIPT_PATH=/usr/bin/

# Install the pcm driver and dependencies
./install_wiringpi.sh
./install_gpio_alt.sh

cd bcm2835-pcm-driver/
./bcm2835-pcm-driver install
cd ..


# Install Python 3.6 and the main gateway worker
./install_python3.6.sh

cd gatewayw/
sudo pip3.6 install $(ls gateway*.tar.gz)
sudo chmod 777 gatewayw.service
sudo cp gatewayw.service /lib/systemd/system/
sudo ln -s /lib/systemd/system/gatewayw.service /etc/systemd/system/
sudo systemctl enable gatewayw.service
cd ..


# Install the BLE Setup program
sudo cp ble-setup ${MODULE_PATH}
cd ${MODULE_PATH}ble-setup/
sudo npm install
sudo chmod 777 ble-setup.service
sudo cp ble-setup.service /lib/systemd/system/
sudo ln -s /lib/systemd/system/ble-setup.service /etc/systemd/system/
sudo systemctl enable ble-setup.service
cd /home/gateway









