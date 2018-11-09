module.exports.postDevice = function (req, res) {
    let user = res.locals.user;

    if (!req.body.id) {
        return res.status(403).json({errorMessage: `NoParameter(id)`, errorCode: 10000});
    } else if (!req.body.deviceName) {
        return res.status(403).json({errorMessage: `NoParameter(deviceName)`, errorCode: 10000});
    } else if (!req.body.apnToken) {
        return res.status(403).json({errorMessage: `NoParameter(apnToken)`, errorCode: 10000});
    } else if (!req.body.systemVersion) {
        return res.status(403).json({errorMessage: `NoParameter(systemVersion)`, errorCode: 10000});
    } else if (!req.body.deviceModelName) {
        return res.status(403).json({errorMessage: `NoParameter(deviceModelName)`, errorCode: 10000});
    }

    if (user.device.id(req.body.id)) {
        return res.status(409).json({errorMessage: `DeviceAlreadyExists(withID: ${req.body.id})`, errorCode: 10004});
    }

    let deviceDocument = {
        _id: req.body.id,
        deviceName: req.body.deviceName,
        apnToken: req.body.apnToken,
        systemVersion: req.body.systemVersion,
        deviceModelName: req.body.deviceModelName
    };

    if (req.body.language) {
        deviceDocument.language = req.body.language;
    } else {
        deviceDocument.language = 'en';
    }

    user.device.push(deviceDocument);
    user.save().then(function () {
        let device = user.device.id(req.body.id);
        res.json(device.toClient());
    }).catch(function (e) {
        res.status(409).json({errorMessage: `DBError(withName: ${e.name})`, errorCode: 10003});
    });
};

module.exports.getDevices = function (req, res) {
    let user = res.locals.user;

    let devices = user.device.map(device => device.toClient());

    if (devices.length === 0) {
        return res.status(404).json({errorMessage: `NoDevicesForUser`, errorCode: 10009});
    }

    return res.json(devices);
};

module.exports.getDevice = function (req, res) {
    let user = res.locals.user;

    let device = user.device.id(req.params.id);

    if (!device) {
        return res.status(404).json({errorMessage: `NoDeviceFound(withID: ${req.params.id})`, errorCode: 10005});
    }
    return res.json(device.toClient());
};

module.exports.deleteDevice = function (req, res) {
    let user = res.locals.user;

    let device = user.device.id(req.params.id);

    if (!device) {
        return res.status(403).json({errorMessage: `NoDeviceFound(withID: ${req.params.id})`, errorCode: 10005});
    }

    user.device = user.device.filter(element => element !== device);
    user.save().then(function () {
        res.json({});
    }).catch(function (e) {
        res.status(409).json({errorMessage: `DBError(withName: ${e.name})`, errorCode: 10003});
    });
};

module.exports.putDevice = function (req, res) {
    let user = res.locals.user;

    let device = user.device.id(req.params.id);

    if (!device) {
        return res.status(404).json({errorMessage: `NoDeviceFound(withID: ${req.params.id})`, errorCode: 10005});
    }

    let index = user.device.indexOf(device);

    if (req.body.language) {
        user.device[index].language = req.body.language;
    }
    if (req.body.deviceName) {
        user.device[index].deviceName = req.body.deviceName;
    }
    if (req.body.apnToken) {
        user.device[index].apnToken = req.body.apnToken;
    }
    if (req.body.systemVersion) {
        user.device[index].systemVersion = req.body.systemVersion;
    }

    user.save().then(function () {
        res.json(user.device[index].toClient());
    }).catch(function (e) {
        res.status(409).json({errorMessage: `DBError(withName: ${e.name})`, errorCode: 10003});
    });
};