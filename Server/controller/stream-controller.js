let connections = [];

module.exports.stream = function(req, res){
    if(!('id' in req.body)){
        res.status(403);
        return res.json({error: 'Parameter id not in request!'});
    }
    res.locals.sse.setup();
    res.on('close', function () {
        res.locals.sse.dispose();
        let index = connections.indexOf(res);
        if (index >= 0) {
            connections.splice(index, 1);
        }
    });
    connections.push(res);
};

module.exports.test = function (req, res) {
    console.log(connections.length);
    connections[0].locals.sse.emit('test', {some: 'data', for: 'you'});
    res.status(200).send();
};