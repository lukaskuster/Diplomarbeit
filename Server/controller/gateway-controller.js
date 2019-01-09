module.exports.postGateway = function (req, res) {
    let user = res.locals.user;

    if (!req.body.imei) {
        return res.status(403).json({errorMessage: `NoParameter(imei)`, errorCode: 10000});
    }

    if (user.gateway.id(req.body.imei)) {
        return res.status(409).json({
            errorMessage: `GatewayAlreadyExists(withIMEI: ${req.body.imei})`,
            errorCode: 10001
        });
    }

    user.gateway.push({_id: req.body.imei});
    user.save().then(function () {
        let gateway = user.gateway.id(req.body.imei);
        res.json(gateway.toClient());
    }).catch(function (e) {
        res.status(409).json({errorMessage: `DBError(withName: ${e.name})`, errorCode: 10003});
    });
};

module.exports.getGateways = function (req, res) {
    let user = res.locals.user;

    let gateways = user.gateway.map(gateway => gateway.toClient());

    if (gateways.length === 0) {
        return res.status(404).json({errorMessage: `NoGatewaysForUser`, errorCode: 10008});
    }

    return res.json(gateways);
};

module.exports.getGateway = function (req, res) {
    let user = res.locals.user;

    let gateway = user.gateway.id(req.params.imei);

    if (!gateway) {
        return res.status(404).json({errorMessage: `NoGatewayFound(withIMEI: ${req.body.imei})`, errorCode: 10002});
    }
    return res.json(gateway.toClient());
};

module.exports.deleteGateway = function (req, res) {
    let user = res.locals.user;

    let gateway = user.gateway.id(req.params.imei);

    if (!gateway) {
        return res.status(403).json({errorMessage: `NoGatewayFound(withIMEI: ${req.body.imei})`, errorCode: 10002});
    }

    user.gateway = user.gateway.filter(element => element !== gateway);
    user.save().then(function () {
        res.json({});
    }).catch(function (e) {
        res.status(409).json({errorMessage: `DBError(withName: ${e.name})`, errorCode: 10003});
    });

};

module.exports.putGateway = function (req, res) {
    let user = res.locals.user;

    let gateway = user.gateway.id(req.params.imei);

    if (!gateway) {
        return res.status(404).json({errorMessage: `NoGatewayFound(withIMEI: ${req.body.imei})`, errorCode: 10002});
    }

    let index = user.gateway.indexOf(gateway);

    if (req.body.signalStrength) {
        user.gateway[index].signalStrength = req.body.signalStrength;
    }
    if (req.body.name) {
        user.gateway[index].name = req.body.name;
    }
    if (req.body.phoneNumber) {
        user.gateway[index].phoneNumber = req.body.phoneNumber;
    }
    if (req.body.carrier) {
        user.gateway[index].carrier = req.body.carrier;
    }
    if (req.body.firmwareVersion) {
        user.gateway[index].firmwareVersion = req.body.firmwareVersion;
    }
    if (req.body.color) {
        user.gateway[index].color = req.body.color;
    }

    user.save().then(function () {
        res.json(user.gateway[index].toClient());
    }).catch(function (e) {
        res.status(409).json({errorMessage: `DBError(withName: ${e.name})`, errorCode: 10003});
    });
};