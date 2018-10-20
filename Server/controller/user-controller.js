const User = require('../model/user');
const md5 = require('md5');

module.exports.getUser = function(req, res){
    return res.json(res.locals.user);
};

module.exports.postUser = function(req, res){
    if(!('mail' in req.body) || !('password' in req.body)){
        return res.status(403).send();
    }

    let user = new User();
    user.password = md5(req.body.password);
    user._id = req.body.mail;
    user.save(function (err) {
        if(err){
            return res.status(403).send()
        }

        res.json(user);
    });
};

module.exports.putUser = function (req, res) {
    let user = res.locals.user;
    console.log(user);

    if('firstName' in req.body){
        user.firstName = req.body.firstName;
    }
    if('lastName' in req.body){
        user.lastName = req.body.lastName;
    }
    if('password' in req.body){
        user.password = md5(req.body.password);
    }

    user.save();

    return res.json(user);
};