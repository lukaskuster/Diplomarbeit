const bleno = require('bleno');
const util = require('util');
const networkInt = require('../networkInterface');

let BlenoCharacteristic = bleno.Characteristic;


let NetworkCharacteristic = function(){
    NetworkCharacteristic.super_.call(this, {
        uuid: 'ff51b30e-d7e2-4d93-8842-a7c4a57dfb09',
        properties: ['write', 'read'],
    });
};

NetworkCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback){
    let self = this;
    console.log(`Network: ${data}`);

    if(!data){
        return callback(self.RESULT_UNLIKELY_ERROR);
    }

    let net;
    try {
        net = JSON.parse(data);
    }catch (e) {
        return callback(self.RESULT_UNLIKELY_ERROR);
    }

    if(!net.ssid || !net.psk){
        return callback(self.RESULT_UNLIKELY_ERROR);
    }

    let network = networkInt.Network(net.ssid);
    network.psk = net.psk;
    network.connect(function (err) {
        if(err){
            return callback(self.RESULT_UNLIKELY_ERROR);
        }
        callback(this.RESULT_SUCCESS);
    });
};

NetworkCharacteristic.prototype.onReadRequest = function(offset, callback){
    let self = this;
    networkInt.getAvailableNetworks(function (err, networks) {
        if(err){
            return callback(self.RESULT_UNLIKELY_ERROR);
        }

        let networkText = JSON.stringify(networks);

        while (Buffer.byteLength(networkText) > 512){
            networks.pop();
            networkText = JSON.stringify(networks);
        }

        let buf = new Buffer(networkText);

        console.log(buf.toString());
        callback(self.RESULT_SUCCESS, buf);
    });
};

util.inherits(NetworkCharacteristic, BlenoCharacteristic);
module.exports = NetworkCharacteristic;



