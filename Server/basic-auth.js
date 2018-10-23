const basicAuth = require('basic-auth');
const User = require('./model/user');
const md5 = require('md5');

module.exports = async function (request, response, next) {
    let requestUser= basicAuth(request);

    let user = await User.findById(requestUser.name);

    if(!user || !requestUser || user.password !== md5(requestUser.pass)){
        response.set('WWW-Authenticate', 'Basic realm="simplephone"');
        response.status(401);
        return response.json({error: 'Not authorized!'});
    }

    response.locals.user = user;
    return next();
};