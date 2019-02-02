const bleno = require('bleno');
const util = require('util');

let NetworkCharacteristic = require('../characteristics/networkCharacteristic');


function WifiService(){
    bleno.PrimaryService.call(this, {
        uuid: 'ff51b30e-d7e2-4d93-8842-a7c4a57dfb08',
        characteristics: [
            new NetworkCharacteristic(),
        ]
    });
}

util.inherits(WifiService, bleno.PrimaryService);
module.exports = WifiService;