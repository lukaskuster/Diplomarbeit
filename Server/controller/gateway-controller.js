module.exports.postGateway = function (req, res) {
    let user = res.locals.user;

    if(!('id' in req.body)){
        res.status(403);
        return res.json({error: 'Parameter id not in request!'});
    }

    if(user.gateway.id(req.body.id)) {
        res.status(409);
        return res.json({error: 'A gateway with this id is already existing on this user!'});
    }

    user.gateway.push({_id: req.body.id});
    user.save();

    let gateway = user.gateway.id(req.body.id);

    return res.json(gateway.toClient());
};

module.exports.getGateways = function (req, res) {
    let user = res.locals.user;

    let gateways = user.gateway.map(gateway => gateway.toClient());
    return res.json(gateways);
};

module.exports.getGateway = function (req, res) {
    let user = res.locals.user;

    let gateway = user.gateway.id(req.params.id);

    if(!gateway){
        res.status(404);
        return res.json({error: 'No gateway found with id ' + req.params.id + "!"});
    }
    return res.json(gateway.toClient());
};

module.exports.deleteGateway = function (req, res) {
    let user = res.locals.user;

    let gateway = user.gateway.id(req.params.id);

    if(!gateway){
        res.status(403);
        return res.json({error: 'No gateway found with id ' + req.params.id + "!"});
    }

    user.gateway = user.gateway.filter(element => element !== gateway);
    user.save();
    return res.json();
};

module.exports.putGateway = function (req, res) {
    let user = res.locals.user;

    let gateway = user.gateway.id(req.params.id);

    if(!gateway){
        res.status(404);
        return res.json({error: 'No gateway found with id ' + req.params.id + "!"});
    }

    let index = user.gateway.indexOf(gateway);

    if ('signalStrength' in req.body) {
        user.gateway[index].signalStrength = req.body.signalStrength;
    }

    user.save();

    return res.json(user.gateway[index].toClient());
};