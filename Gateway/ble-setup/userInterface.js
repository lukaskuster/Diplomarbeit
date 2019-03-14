const fs = require('fs');
const ini = require('ini');
const path = require('path');

const CONFIG_PATH = process.env['GATEWAYCONFIGPATH'] || '/etc/gateway/';

module.exports.getIMEI = function () {
    let config = ini.parse(fs.readFileSync(path.join(CONFIG_PATH, 'config.ini'), 'utf-8'));
    let auth = config['Auth'];

    if(!('imei' in auth)){
        return null
    }

    return auth.imei;
};

module.exports.setCredentials = function (username, password) {
    console.log(`Read config file at ${path.join(CONFIG_PATH, 'config.ini')}`);
    let config = ini.parse(fs.readFileSync(path.join(CONFIG_PATH, 'config.ini'), 'utf-8'));
    let auth = config['Auth'];

    console.log(`Set Credentials for ${username}`);
    auth.user = username;
    auth.password = password;

    console.log(`Save config file to ${path.join(CONFIG_PATH, 'config.ini')}`);
    fs.writeFileSync(path.join(CONFIG_PATH, 'config.ini'), ini.stringify(config, { section: '' }));
};


