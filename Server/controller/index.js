const express = require('express');
const basicAuth = require('../middleware/basic-auth');
const sse = require('../middleware/sse');
const userController = require('./user-controller');
const gatewayController = require('./gateway-controller');
const streamController = require('./stream-controller');
const deviceController = require('./device-controller');


const router = express.Router();

router.get('/user', basicAuth, userController.getUser);
router.post('/user', userController.postUser);
router.put('/user', basicAuth, userController.putUser);

router.post('/gateway', basicAuth, gatewayController.postGateway);
router.get('/gateway/:id', basicAuth, gatewayController.getGateway);
router.get('/gateways', basicAuth, gatewayController.getGateways);
router.delete('/gateway/:id', basicAuth, gatewayController.deleteGateway);
router.put('/gateway/:id', basicAuth, gatewayController.putGateway);

router.get('/stream', basicAuth, sse, streamController.stream);
router.post('/event', basicAuth, streamController.event);

router.post('/device', basicAuth, deviceController.postDevice);
router.get('/devices', basicAuth, deviceController.getDevices);
router.get('/device/:id', basicAuth, deviceController.getDevice);
router.delete('/device/:id', basicAuth, deviceController.deleteDevice);
router.put('/device/:id', basicAuth, deviceController.putDevice);


module.exports = router;