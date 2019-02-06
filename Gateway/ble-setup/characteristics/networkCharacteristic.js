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

    if(!data){
        console.error("No data!");
        return callback(self.RESULT_UNLIKELY_ERROR);
    }

    console.log(`Network: ${data}`);

    let net;
    try {
        net = JSON.parse(data);
    }catch (e) {
        console.error("Can't parse JSON!");
        return callback(self.RESULT_UNLIKELY_ERROR);
    }

    if(!net.ssid || !net.psk){
        console.error("No ssid or psk in JSON!");
        return callback(self.RESULT_UNLIKELY_ERROR);
    }

    let network = new networkInt.Network(net.ssid);
    network.psk = net.psk;
    console.log("Connecting to ", net.ssid);
    network.connect(function (err) {
        if(err){
            console.error("Failed to connect to ", network.ssid);
            console.error(err.error);
            return callback(self.RESULT_UNLIKELY_ERROR);
        }
        console.log("Connected to ", network.ssid);
        callback(this.RESULT_SUCCESS);
    });
};

NetworkCharacteristic.prototype.onReadRequest = function(offset, callback){
    let self = this;

    if(offset === 0) {
        console.log("Requested Networks...");
        networkInt.getAvailableNetworks(function (err, networks) {
            if (err) {
                console.error("Failed to get networks!");
                console.error(err.error);
                return callback(self.RESULT_UNLIKELY_ERROR);
            }

            let minNetworks = [];
            let ssids = new Set();

            for(let n of networks){
                if(!ssids.has(n.ssid)){
                    ssids.add(n.ssid);
                    minNetworks.push({
                        ssid: n.ssid,
                        rssi: n.signal,
                        auth: true
                    });
                }
            }

            let networkStr = JSON.stringify(minNetworks);

            while (Buffer.byteLength(networkStr) > 512) {
                minNetworks.pop();
                networkStr = JSON.stringify(minNetworks);
            }

            self.networkBuffer = new Buffer(networkStr, 'utf8');

            console.log("Sending gathered networks...");
            console.debug("Networks: ", self.networkBuffer.toString());
            callback(self.RESULT_SUCCESS, self.networkBuffer);
        });
    }else if(offset > self.networkBuffer.length){
        console.error("Invalid offset while requesting networks!");
        callback(self.RESULT_INVALID_OFFSET, null);
    }else{
        console.log("Collecting chunk of data...");
        callback(self.RESULT_SUCCESS, self.networkBuffer.slice(offset));
    }
};

util.inherits(NetworkCharacteristic, BlenoCharacteristic);
module.exports = NetworkCharacteristic;



