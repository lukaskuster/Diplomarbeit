const basicAuth = require('basic-auth');
const User = require('../model/user');
const md5 = require('md5');


module.exports = async function (request, response, next) {
    let requestUser = basicAuth(request);

    if (!requestUser) {
        response.set('WWW-Authenticate', 'Basic realm="simplephone"');
        return response.status(401).json({errorMessage: `NotAuthenticated`, errorCode: 10010});
    }

    let user = await User.findById(requestUser.name);

    if (!user || user.password !== md5(requestUser.pass)) {
        response.set('WWW-Authenticate', 'Basic realm="simplephone"');
        return response.status(401).json({errorMessage: `WrongCredentials`, errorCode: 10011});
    }

    response.locals.user = user;
    return next();
};