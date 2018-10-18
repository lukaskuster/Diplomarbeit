let http = require('http');
let io = require('socket.io');


// Port on that the server listens
const port = 10001;

// Create a http server and pass it to socket.io to get the socket.io server socket
let webServer = http.createServer();
let server = io(webServer, {cookie: false});

// Hardcoded user. ONLY FOR TESTING!
let testUser = {username: 'quentin@wendegass.com', password: 'test123', _id: 'adhudbnsucmsocm'};


let peers = new WeakMap();
let pendingUser = new Map();


// Set a callback to the connection event
server.on('connection', function (socket) {

    // Indicates if the client is authorized to use the exchange events
    let authenticated = false;

    // Custom authenticate event that requires username and password
    socket.on('authenticate', function ({username, password, rule}) {

        // If the rule is not passed, set it to offer
        if(!rule){
            rule = 'offer';
        }

        // Send an authorization error if the username or password is not passed
        if(!username || !password){
            socket.emit('authenticated', {authenticated: false, error: "No username, password or rule was in the request!"});
            return;
        }

        // Send an authorization error if the username doesn't exist
        if(username !== testUser.username){
            socket.emit('authenticated', {authenticated: false, error: "Username does not exist!"});
            return;
        }

        // Send an authorization error if the password is wrong
        if(password !== testUser.password){
            socket.emit('authenticated', {authenticated: false, error: "Wrong password!"});
            return;
        }

        // The authorization was successful
        socket.emit('authenticated', {authenticated: true, error: ""});
        authenticated = true;

        let user = testUser;

        // Check if a socket with that user is already connected.
        if(pendingUser.has(user)){

            // Get the already connected socket
            let peerUser = pendingUser.get(user);

            // Set the remote peer for both sockets
            peers.set(peerUser.socket, socket.id);
            peers.set(socket, peerUser.socket.id);

            // Check if the first user set answer as rule and start the interconnection accordingly
            // The rule of the second connected client is ignored
            if(peerUser.rule === "answer"){
                socket.emit('start');
            }else {
                peerUser.socket.emit('start');
            }

            // Now the first user pending any more
            pendingUser.delete(user);

        }else {
            // If no client with that user is connected, set the current client as pending
            pendingUser.set(user, {socket: socket, rule: rule});
        }
    });


    // Routes the offer to the peer client
    socket.on('offer', function (data) {
        if(authenticated){
            server.to(peers.get(socket)).emit('offer', data);
        }
    });

    // Routes the answer to the peer client
    socket.on('answer', function (data) {
        if(authenticated){
            server.to(peers.get(socket)).emit('answer', data);
        }
    });
});

// Listen on the given port
webServer.listen(port);
