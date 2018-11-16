const apn = require('apn');


const APN_KEY = 'AuthKey_93W56D4882.p8';
const APN_KEY_ID = '93W56D4882';
const APN_TEAM_ID = 'UBFF39V752';
const APP_BUNDLE_ID = 'com.lukaskuster.diplomarbeit.SIMplePhone';


module.exports.broadcastEvent = function(req, res){
    if (!req.body.event) {
        return res.status(403).json({errorMessage: `NoParameter(event)`, errorCode: 10000});
    }

    let user = res.locals.user;

    let tokens = [];

    if(user.device.length === 0){
        return res.status(404).json({errorMessage: `NoDevicesForUser`, errorCode: 10009});
    }

    for(let i = 0; i < user.device.length; i++){
        tokens.push(user.device[i].apnToken)
    }

    let payload = { event: req.body.event };

    if(req.body.data) {
        payload.data = req.body.data;
    }

    pushToDevice(tokens, payload, req.body.alert, Boolean(req.body.silent))
};

module.exports.pushEvent = function(req, res) {
    if (!req.body.event) {
        return res.status(403).json({errorMessage: `NoParameter(event)`, errorCode: 10000});
    }else if (!req.body.device) {
        return res.status(403).json({errorMessage: `NoParameter(device)`, errorCode: 10000});
    }

    let user = res.locals.user;

    let device = user.device.id(req.body.device);

    if (!device) {
        return res.status(404).json({errorMessage: `NoDeviceFound(withID: ${req.body.device})`, errorCode: 10005});
    }

    let payload = { event: req.body.event };

    if(req.body.data){
        payload.data = req.body.data;
    }

    pushToDevice(device.apnToken, payload, req.body.alert, Boolean(req.body.silent))
};


function pushToDevice(deviceToken, data, alert, silent=false) {
    const options = {
        token: {
            key: APN_KEY,
            keyId: APN_KEY_ID,
            teamId: APN_TEAM_ID
        },
        production: false
    };

    if(silent){
        options.aps = {
            'content-available' : 1
        }
    }

    let apnProvider = new apn.Provider(options);

    let note = new apn.Notification();

    note.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
    note.topic = APP_BUNDLE_ID;

    note.alert = alert | 'You have a new message';

    note.payload = {
        ...data
    };

    apnProvider.send(note, deviceToken).then((result) => {
        console.log(result);
    });


    apnProvider.shutdown();
}