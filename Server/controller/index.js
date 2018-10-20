const express = require('express');
const basicAuth = require('../basic-auth');
const userController = require('./user-controller');
const gatewayController = require('./gateway-controller');

const router = express.Router();

router.get('/user', basicAuth, userController.getUser);
router.post('/user', userController.postUser);
router.put('/user', basicAuth, userController.putUser);

router.post('/gateway', basicAuth, gatewayController.postGateway);
router.get('/gateway/:id', basicAuth, gatewayController.getGateway);
router.get('/gateways', basicAuth, gatewayController.getGateways);
router.delete('/gateway/:id', basicAuth, gatewayController.deleteGateway);


module.exports = router;