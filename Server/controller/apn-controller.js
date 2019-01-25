const apn = require('apn');
const util = require('util');


const APN_KEY = 'AuthKey_93W56D4882.p8';
const APN_VOIP_CERT = 'voip.p12';
const APN_VOIP_PASSWORD = "diplomarbeit";
const APN_KEY_ID = '93W56D4882';
const APN_TEAM_ID = 'UBFF39V752';
const APP_BUNDLE_ID = 'com.lukaskuster.diplomarbeit.SIMplePhone';


module.exports.broadcastEventExcept = function(response, {device}, event, data){
    if(!device){
        return response.status(403).json({errorMessage: `NoParameter(device)`, errorCode: 10000});
    }

    let user = response.locals.user;

    if(user.device.length === 0){
        return response.status(404).json({errorMessage: `NoDevicesForUser`, errorCode: 10009});
    }

    let tokens = [];

    for(let i = 0; i < user.device.length; i++){
        if(user.device[i]._id !== device){
            tokens.push(user.device[i].voipToken)
        }
    }

    let payload = { event: event };

    if(data) {
        payload.data = data;
    }

    pushToDevices(response, tokens, payload, null, true, true);
};

module.exports.broadcastEvent = function(req, res){

    if (!req.body.event) {
        return res.status(403).json({errorMessage: `NoParameter(event)`, errorCode: 10000});
    }

    let user = res.locals.user;

    let tokens = [];

    if(user.device.length === 0){
        return res.status(404).json({errorMessage: `NoDevicesForUser`, errorCode: 10009});
    }

    if(Boolean(req.body.voip)){
        for(let i = 0; i < user.device.length; i++){
            if(!user.device[i].voipToken){
                return res.status(404).json({errorMessage: `NoVoipToken(forDevice: ${user.device[i]._id})`, errorCode: 10012});
            }
            tokens.push(user.device[i].voipToken)
        }
    }else{
        for(let i = 0; i < user.device.length; i++){
            tokens.push(user.device[i].apnToken)
        }
    }

    let payload = { event: req.body.event };

    if(req.body.data) {
        payload.data = req.body.data;
    }

    pushToDevices(res, tokens, payload, req.body.alert, Boolean(req.body.silent), Boolean(req.body.voip));
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

    if(Boolean(req.body.voip)){
        if(!device.voipToken){
            return res.status(404).json({errorMessage: `NoVoipToken(forDevice: ${device._id})`, errorCode: 10012});
        }
        pushToDevices(res, device.voipToken, payload, req.body.alert, Boolean(req.body.silent), true);
    }else{
        pushToDevices(res, device.apnToken, payload, req.body.alert, Boolean(req.body.silent), false);
    }
};


function pushToDevices(response, token, data, alert, silent=false, voip=false) {

    const options = {
        production: false
    };

    if(voip){
        options.pfx = APN_VOIP_CERT;
        options.passphrase = APN_VOIP_PASSWORD;
    }else{
        options.token = {
            key: APN_KEY,
            keyId: APN_KEY_ID,
            teamId: APN_TEAM_ID
        };
    }

    let apnProvider = new apn.Provider(options);

    let notificationOptions = {};
    if(silent){
        notificationOptions.contentAvailable = 1;
    }

    let note = new apn.Notification(notificationOptions);

    note.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.

    note.topic = APP_BUNDLE_ID;
    if(voip){
        note.topic += ".voip";
    }

    if(!silent){
        note.sound = "ping.aiff";
        note.alert = alert || "You have a new message";
    }

    note.payload = {
        ...data
    };


    apnProvider.send(note, token).then((result) => {
        response.json(result);
    });


    apnProvider.shutdown();
}