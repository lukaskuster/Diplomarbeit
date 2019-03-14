const bleno = require('bleno');
const util = require('util');
const userInt = require('../userInterface');
const { exec } = require('child_process');


let BlenoCharacteristic = bleno.Characteristic;


let AuthenticationCharacteristic = function(config){
    AuthenticationCharacteristic.super_.call(this, {
        uuid: config.uuid,
        properties: config.properties
    });
};

AuthenticationCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback){  
    if(!data){
        console.error("No data!");
        return this.RESULT_INVALID_ATTRIBUTE_LENGTH;
    }

    console.log(`Network: ${data}`);

    let credentials;
    try {
        credentials = JSON.parse(data);
    }catch (e) {
        console.error("Can't parse JSON!");
        return callback(self.RESULT_UNLIKELY_ERROR);
    }

    if(!credentials.user || !credentials.password){
        console.error("No username or password in JSON!");
        return callback(self.RESULT_UNLIKELY_ERROR);
    }

    userInt.setCredentials(credentials.user, credentials.password);

    console.log("Restart gatewayw service...");
    exec('sudo systemctl restart gatewayw', (err, stdout, stderr) => {
        if (err) {
            console.error(`Could not restart gatewayw: ${err}`);
            callback(this.RESULT_UNLIKELY_ERROR);
            return;
        }

        console.log("gatewayw successfully restarted!");
        callback(this.RESULT_SUCCESS);
    });
};


util.inherits(AuthenticationCharacteristic, BlenoCharacteristic);
module.exports = AuthenticationCharacteristic;
