const apnController = require("./apn-controller");

let connections = {};

module.exports.stream = function (req, res) {
    if (!req.body.imei) {
        return res.status(403).json({errorMessage: `NoParameter(imei)`, errorCode: 10000});
    }

    let gateway = res.locals.user.gateway.id(req.body.imei);
    if (!gateway) {
        return res.status(404).json({errorMessage: `NoGatewayFound(withIMEI: ${req.body.imei})`, errorCode: 10002});
    }

    res.locals.sse.setup();
    res.on('close', function () {
        res.locals.sse.dispose();
        delete connections[req.body.imei];
    });
    connections[req.body.imei] = res;
};

module.exports.pushEvent = function (req, res) {
    if (!req.body.event) {
        return res.status(403).json({errorMessage: `NoParameter(event)`, errorCode: 10000});
    }
    else if (!req.body.gateway) {
        return res.status(403).json({errorMessage: `NoParameter(gateway)`, errorCode: 10000});
    }

    req.body.data = req.body.data || {};

    let gateway = res.locals.user.gateway.id(req.body.gateway);
    if (!gateway) {
        return res.status(404).json({errorMessage: `NoGatewayFound(withIMEI: ${req.body.gateway})`, errorCode: 10002});
    }

    if (req.body.gateway in connections) {
        connections[req.body.gateway].locals.sse.emit(req.body.event, req.body.data);

        if(req.body.event === "deviceDidAnswerCall"){
            return apnController.broadcastEventExcept(res, req.body.data, 'otherDeviceDidAnswer', {gateway: gateway});
        }else if(req.body.event === "deviceDidDeclineCall"){
            return apnController.broadcastEventExcept(res, req.body.data, 'otherDeviceDidDecline', {gateway: gateway});
        }

        return res.status(200).json({});
    }

    return res.status(404).json({errorMessage: `NoGatewayConnected(withIMEI: ${req.body.gateway})`, errorCode: 10007});
};

