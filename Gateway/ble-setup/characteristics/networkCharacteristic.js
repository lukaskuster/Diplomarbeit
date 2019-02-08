const bleno = require('bleno');
const util = require('util');
const networkInt = require('../networkInterface');

let BlenoCharacteristic = bleno.Characteristic;


let NetworkCharacteristic = function(config){
    NetworkCharacteristic.super_.call(this, {
        uuid: config.uuid,
        properties: config.properties,
    });
};


NetworkCharacteristic.prototype.sendNotification = function(obj){
    if(!self.updateValueCallback){
        return console.error("Client has not subscribed!")
    }

    let buff = new Buffer(JSON.stringify(status));

    console.log(`Send notification: ${buff.toString()}`);

    self.updateValueCallback(buff);
};

NetworkCharacteristic.prototype.onSubscribe = function(maxValueSize, updateValueCallback){
    console.log(`Client subscribed with maxValueSize: ${maxValueSize}!`);
    this.updateValueCallback = updateValueCallback;
};


NetworkCharacteristic.prototype.onUnsubscribe = function(){
    console.log("Client unsubscribed!");
    this.updateValueCallback = null;
};


NetworkCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback){
    let self = this;

    if(!data){
        console.error("No data!");
        return callback(self.RESULT_INVALID_ATTRIBUTE_LENGTH);
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
            self.sendNotification({status: 3});
            return callback(self.RESULT_UNLIKELY_ERROR);
        }
        console.log("Connected to ", network.ssid);
        callback(this.RESULT_SUCCESS);

        setTimeout(function () {
            network.check(function (err) {
                let status = null;
                if(err){
                    console.error(`Connection error: ${err.error}`);
                    status = {status: 1}
                }else {
                    console.log("Connection was successful established!");
                    status = {status: 0};
                }

                self.sendNotification(status);
            });
        }, 5000);
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
