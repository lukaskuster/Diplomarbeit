const User = require('../model/user');
const md5 = require('md5');

module.exports.getUser = function (req, res) {
    let user = res.locals.user;
    return res.json(user.toClient());
};

module.exports.postUser = function (req, res) {
    if (!req.body.mail) {
        return res.status(403).json({errorMessage: `NoParameter(mail)`, errorCode: 10000});
    } else if (!req.body.password) {
        return res.status(403).json({errorMessage: `NoParameter(password)`, errorCode: 10000});
    } else if (!req.body.firstName) {
        return res.status(403).json({errorMessage: `NoParameter(firstName)`, errorCode: 10000});
    } else if (!req.body.lastName) {
        return res.status(403).json({errorMessage: `NoParameter(lastName)`, errorCode: 10000});
    }

    let user = new User();
    user.password = md5(req.body.password);
    user._id = req.body.mail;
    user.firstName = req.body.firstName;
    user.lastName = req.body.lastName;
    user.save(function (err) {
        if (err) {
            return res.status(409).json({
                errorMessage: `MailAlreadyExists(withMail: ${req.body.mail})`,
                errorCode: 10006
            });
        }

        res.json(user.toClient());
    });
};

module.exports.putUser = function (req, res) {
    let user = res.locals.user;

    if (req.body.firstName) {
        user.firstName = req.body.firstName;
    }
    if (req.body.lastName) {
        user.lastName = req.body.lastName;
    }
    if (req.body.password) {
        user.password = md5(req.body.password);
    }

    user.save().then(function () {
        res.json(user.toClient());
    }).catch(function (e) {
        res.status(409).json({errorMessage: `DBError(withName: ${e.name})`, errorCode: 10003});
    });
};