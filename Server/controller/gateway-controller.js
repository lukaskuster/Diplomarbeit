module.exports.postGateway = function (req, res) {
    let user = res.locals.user;

    if(!('id' in req.body)) return res.status(403).send();


    if(user.gateway.find((element) => element._id === req.body.id)) {
        return res.status(409).send();
    }

    user.gateway.push({_id: req.body.id});
    user.save();

    return res.json(user);
};

module.exports.getGateways = function (req, res) {
    let user = res.locals.user;

    return res.json(user.gateway);
};

module.exports.getGateway = function (req, res) {
    let user = res.locals.user;

    let gateway = user.gateway.id(req.params.id);

    if(!gateway){
        return res.status(404).send();
    }
    return res.json(gateway);
};

module.exports.deleteGateway = function (req, res) {
    let user = res.locals.user;

    let gateway = user.gateway.id(req.params.id);

    if(!gateway){
        return res.status(404).send();
    }

    user.gateway = user.gateway.filter(element => element !== gateway);
    user.save();
    return res.json(user);
};