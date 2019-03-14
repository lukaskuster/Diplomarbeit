# Gateway

## Programs
* ble-setup
* gatewayw
* bcm2835-pcm-driver

## Build source

To build the source to a installable package use: 
`./build (gatewayw|pcm-driver|ble-setup|all) [deploy]`

The first argument is the program to build. As second argument deploy can be used to transfer it directly with *scp*. For more details read the docstring in the build script.


## Install and build binaries

Use the installation scripts in the *bin* directory to install or uninstall the packages correctly. 

`./[gatewayw|bcm2835-pcm-driver|ble-setup] install /path/to/package.tar.gz`
