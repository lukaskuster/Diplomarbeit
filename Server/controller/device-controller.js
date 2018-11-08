module.exports.postDevice = function (req, res) {
    let user = res.locals.user;

    if(!('id' in req.body)){
        return res.status(403).json({error: 'Parameter id not in request!'});
    }else if(!('deviceName' in req.body)){
        return res.status(403).json({error: 'Parameter deviceName not in request!'});
    }else if(!('apnToken' in req.body)){
        return res.status(403).json({error: 'Parameter apnToken not in request!'});
    }else if(!('language' in req.body)){
        return res.status(403).json({error: 'Parameter language not in request!'});
    }else if(!('systemVersion' in req.body)){
        return res.status(403).json({error: 'Parameter systemVersion not in request!'});
    }else if(!('deviceModelName' in req.body)){
        return res.status(403).json({error: 'Parameter deviceModelName not in request!'});
    }

    if(user.device.id(req.body.id)) {
        return res.status(409).json({error: 'A Device with this id is already existing on this user!'});
    }

    user.device.push(
        {
            _id: req.body.id,
            deviceName: req.body.deviceName,
            apnToken: req.body.apnToken,
            language: req.body.language,
            systemVersion: req.body.systemVersion,
            deviceModelName: req.body.deviceModelName
        });
    user.save();

    let device = user.device.id(req.body.id);

    return res.json(device.toClient());
};

module.exports.getDevices = function (req, res) {
    let user = res.locals.user;

    let devices = user.device.map(device => device.toClient());
    return res.json(devices);
};

module.exports.getDevice = function (req, res) {
    let user = res.locals.user;

    let device = user.device.id(req.params.id);

    if(!device){
        return res.status(404).json({error: 'No device found with id ' + req.params.id + "!"});
    }
    return res.json(device.toClient());
};

module.exports.deleteDevice = function (req, res) {
    let user = res.locals.user;

    let device = user.device.id(req.params.id);

    if(!device){
        return res.status(403).json({error: 'No device found with id ' + req.params.id + "!"});
    }

    user.device = user.device.filter(element => element !== device);
    user.save();
    return res.json({});
};

module.exports.putDevice = function (req, res) {
    let user = res.locals.user;

    let device = user.device.id(req.params.id);

    if(!device){
        return res.status(404).json({error: 'No device found with id ' + req.params.id + "!"});
    }

    let index = user.device.indexOf(device);

    if ('language' in req.body) {
        user.device[index].language = req.body.language;
    }
    if ('deviceName' in req.body) {
        user.device[index].deviceName = req.body.deviceName;
    }
    if ('apnToken' in req.body) {
        user.device[index].apnToken = req.body.apnToken;
    }
    if ('systemVersion' in req.body) {
        user.device[index].systemVersion = req.body.systemVersion;
    }

    user.save();

    return res.json(user.device[index].toClient());
};