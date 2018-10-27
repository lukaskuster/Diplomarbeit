let connections = {};

module.exports.stream = function(req, res){
    if(!('id' in req.body)){
        res.status(403);
        return res.json({error: 'Parameter id not in request!'});
    }

    let gateway = res.locals.user.gateway.id(req.body.id);
    if(!gateway){
        res.status(404);
        return res.json({error: 'No Gateway with that id!'});
    }

    res.locals.sse.setup();
    res.on('close', function () {
        res.locals.sse.dispose();
        delete connections[req.body.id];
    });
    connections[req.body.id] = res;
};

module.exports.event = function (req, res) {
    if(!req.body.event || !req.body.gateway){
        res.status(403);
        return res.json({error: 'Parameter event or gateway is not in the request!'});
    }

    req.body.data = req.body.data || {};

    let gateway = res.locals.user.gateway.id(req.body.gateway);
    if(!gateway){
        res.status(404);
        return res.json({error: 'No Gateway with that id!'});
    }

    if(req.body.gateway in connections){
        connections[req.body.gateway].locals.sse.emit(req.body.event, req.body.data);
        return res.status(200).send();
    }

    res.status(404);
    return res.json({error: 'Gateway is not connected!'});
};

