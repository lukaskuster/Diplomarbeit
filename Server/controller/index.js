const express = require('express');
const basicAuth = require('../middleware/basic-auth');
const sse = require('../middleware/sse');
const userController = require('./user-controller');
const gatewayController = require('./gateway-controller');
const streamController = require('./stream-controller');
const deviceController = require('./device-controller');
const apnController = require('./apn-controller');

const router = express.Router();

router.get('/user', basicAuth, userController.getUser);
router.post('/user', userController.postUser);
router.put('/user', basicAuth, userController.putUser);
router.delete('/user', basicAuth, userController.deleteUser);


router.get('/gateway/stream', basicAuth, sse, streamController.stream);
router.post('/gateway/push', basicAuth, streamController.pushEvent);

router.post('/device/push', basicAuth, apnController.pushEvent);
router.post('/device/broadcast', basicAuth, apnController.broadcastEvent);

router.post('/gateway', basicAuth, gatewayController.postGateway);
router.get('/gateway/:imei', basicAuth, gatewayController.getGateway);
router.get('/gateways', basicAuth, gatewayController.getGateways);
router.delete('/gateway/:imei', basicAuth, gatewayController.deleteGateway);
router.put('/gateway/:imei', basicAuth, gatewayController.putGateway);

router.post('/device', basicAuth, deviceController.postDevice);
router.get('/devices', basicAuth, deviceController.getDevices);
router.get('/device/:id', basicAuth, deviceController.getDevice);
router.delete('/device/:id', basicAuth, deviceController.deleteDevice);
router.delete('/devices', basicAuth, deviceController.deleteDevices);
router.put('/device/:id', basicAuth, deviceController.putDevice);

router.get('/authenticate', basicAuth, (req, res) => {
    if(res.locals.user.cloudUserId) {
        return res.status(200).json({'cloudUserId': res.locals.user.cloudUserId})
    }
    res.status(200).json({})
});


module.exports = router;