const basicAuth = require('basic-auth');
const User = require('./model/user-model');
const md5 = require('md5');

module.exports = async function (request, response, next) {
    let requestUser= basicAuth(request);

    let user = await User.findOne({mail: requestUser.name});

    if(!user || !requestUser || user.password !== md5(requestUser.pass)){
        response.set('WWW-Authenticate', 'Basic realm="simplephone"');
        return response.status(401).send();
    }

    response.locals.user = user;
    return next();
};