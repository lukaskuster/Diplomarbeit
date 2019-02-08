#!/usr/bin/env node

const path = require('path');

process.env['BLENO_DEVICE_NAME'] = 'Gateway';

const bleno = require('bleno');
const WifiSerivce = require('./services/wifiService');
const UserService = require('./services/userService');

let config;

if('GATEWAYCONFIGPATH' in process.env){
    config = require(path.join(process.env['GATEWAYCONFIGPATH'], 'ble-config.json'));
}else{
    config = require('/etc/gateway/ble-config.json')
}

let wifiService = new WifiSerivce(config.service.wifi);
let userService = new UserService(config.service.user);

bleno.on('stateChange', function(state) {
    console.log('on -> stateChange: ' + state);

    if (state === 'poweredOn') {
        bleno.startAdvertising('Gateway', [wifiService.uuid]);
    }
    else {
        bleno.stopAdvertising();
    }
});

bleno.on('advertisingStart', function(error) {
    console.log('on -> advertisingStart: ' +
        (error ? 'error ' + error : 'success')
    );

    if (!error) {
        bleno.setServices([
            wifiService,
            userService
        ]);
    }
});
