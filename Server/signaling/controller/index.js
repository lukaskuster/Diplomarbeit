const express = require('express');
const userController = require('./userController');

const router = express.Router();

router.get('/user', userController.getUser);

module.exports = router;