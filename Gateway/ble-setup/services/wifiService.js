const bleno = require('bleno');
const util = require('util');

let NetworkCharacteristic = require('../characteristics/networkCharacteristic');


function WifiService(config){
    bleno.PrimaryService.call(this, {
        uuid: config.uuid,
        characteristics: [
            new NetworkCharacteristic(config.characteristic.network),
        ]
    });
}

util.inherits(WifiService, bleno.PrimaryService);
module.exports = WifiService;
