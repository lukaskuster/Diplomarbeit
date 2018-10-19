const express = require('express');
const basicAuth = require('../basic-auth');
const userController = require('./user-controller');

const router = express.Router();

router.get('/user', basicAuth, userController.getUser);
router.post('/user', userController.postUser);
router.put('/user', basicAuth, userController.putUser);

module.exports = router;