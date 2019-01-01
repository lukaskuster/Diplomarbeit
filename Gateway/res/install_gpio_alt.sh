gcc -o gpio_alt gpio_alt.c
sudo chown root:root gpio_alt
sudo chmod u+s gpio_alt
sudo mv gpio_alt /usr/local/bin/