const User = require('../model/user');
const md5 = require('md5');

module.exports.getUser = function(req, res){
    let user = res.locals.user;
    return res.json(user.toClient());
};

module.exports.postUser = function(req, res){
    if(!('mail' in req.body) || !('password' in req.body)){
        res.status(403);
        return res.json({error: 'Parameter mail or password is not in the request!'});
    }

    let user = new User();
    user.password = md5(req.body.password);
    user._id = req.body.mail;
    user.save(function (err) {
        if(err){
            res.status(409);
            res.json({error: 'Mail already in use!'});
        }

        res.json(user.toClient());
    });
};

module.exports.putUser = function (req, res) {
    let user = res.locals.user;

    if ('firstName' in req.body) {
        user.firstName = req.body.firstName;
    }
    if ('lastName' in req.body) {
        user.lastName = req.body.lastName;
    }
    if ('password' in req.body) {
        user.password = md5(req.body.password);
    }

    user.save();

    return res.json(user.toClient());
};