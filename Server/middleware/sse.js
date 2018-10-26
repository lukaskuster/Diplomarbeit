module.exports = function (req, res, next) {
    res.locals.sse = {};

    res.locals.sse.setup = function(){
        res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive'
        });

        res.locals.sse.timeout = setInterval(() => res.write("\n\n"), 5000);
    };

    res.locals.sse.dispose = function(){
        clearInterval(res.locals.sse.timeout)
    };

    res.locals.sse.emit = function(event, data){
        let notification = {event: event, data: data};
        res.write(JSON.stringify(notification) + "\n\n");
    };

    next()
};