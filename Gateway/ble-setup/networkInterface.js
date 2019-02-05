const piWifi = require('pi-wifi');


function Network(ssid) {
    this.ssid = ssid;
    this.psk = null;
    this.flags = null;
    this.signal = null;
    this.connect = connectToNetwork.bind(this);
    this.check = checkNetwork.bind(this);
}

function checkNetwork(callback) {
    let self = this;
    piWifi.check(this.ssid, function (err, status) {
        if (!err && status.connected) {
            console.log(`Connected to the network ${self.ssid}!`);
            callback(null)
        } else {
            let error = `Not connected to the network ${self.ssid}!`;
            console.error(error);
            callback({error: error})
        }
    });
}

function connectToNetwork(callback, check=false, timeout=2000){
    let self = this;
    piWifi.connectTo({ssid: self.ssid, password: self.psk}, function(err) {
        if (!err) { //Network created correctly
            if(check) {
                setTimeout(function () {
                    checkNetwork(function (err) {
                        if(err){
                            return callback(err)
                        }
                        callback(null)
                    })
                }, timeout);
            }else {
                callback(null);
            }
        } else {
            let error = `Unable to create the network ${self.ssid}.`;
            console.error(error);
            callback({error: error})
        }
    });
}


function getAvailableNetworks(callback) {

    let networks = [];
    piWifi.scan((err, nets) => {
        if (err) {
            console.error(err.message);
            return callback({error: err.message})
        }

        for(let i = 0; i < nets.length; i++){
            let n = new Network(nets[i].ssid);
            n.signal = nets[i].signalLevel;
            n.flags = nets[i].flags;
            networks.push(n);
        }
        callback(null, networks)
    });
}


module.exports.getAvailableNetworks = getAvailableNetworks;
module.exports.connectToNetwork = connectToNetwork;
module.exports.Network = Network;
