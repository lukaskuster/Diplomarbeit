process.env['BLENO_DEVICE_NAME'] = 'Gateway';

const bleno = require('bleno');
const WifiSerivce = require('./services/wifiService');

let wifiService = new WifiSerivce();

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
            wifiService
        ]);
    }
});
