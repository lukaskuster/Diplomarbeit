const auth = require('basic-auth');
const User = require('./model/user')

module.exports = async function (request, response, next) {
    let requestUser= auth(request);

    let user = await User.findOne({mail: requestUser.name});

    if(!user || !requestUser || user.password !== requestUser.pass){
        response.set('WWW-Authenticate', 'Basic realm="example"');
        return response.status(401).send();
    }

    response.locals.user = user;
    return next();
};