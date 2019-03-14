const bleno = require('bleno');
const util = require('util');

let AuthenticationCharacteristic = require('../characteristics/authenticationCharacteristic');


function UserService(config){
    bleno.PrimaryService.call(this, {
        uuid: config.uuid,
        characteristics: [
            new AuthenticationCharacteristic(config.characteristic.authentication),
        ]
    });
}

util.inherits(UserService, bleno.PrimaryService);
module.exports = UserService;
