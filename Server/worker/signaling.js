const http = require('http');
const io = require('socket.io');
const User = require('../model/user-model');
const md5 = require('md5');
const mongoose = require('mongoose');


// Port on that the server listens
const port = 10001;

// Collection name of the mongo db
const collection = 'simple-phone';


// Connect to the database
mongoose.connect('mongodb://localhost/'+ collection);
mongoose.Promise = global.Promise;
let db = mongoose.connection;

// Check for errors
db.on('error', console.error.bind(console, 'MongoDB connection error:'));


// Create a http server and pass it to socket.io to get the socket.io server socket
let webServer = http.createServer();
let server = io(webServer, {cookie: false});


let peers = new WeakMap();
let pendingUser = {};


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

        // Search mongo db for the requested mail
        User.findOne({mail: username}, function (err, user) {
            if(err || !user){
                // Send an authorization error if the username doesn't exist
                socket.emit('authenticated', {authenticated: false, error: "Username does not exist!"});
                return;
            }

            if(md5(password) !== user.password){
                // Send an authorization error if the password is wrong
                socket.emit('authenticated', {authenticated: false, error: "Wrong password!"});
                return;
            }

            // The authorization was successful
            socket.emit('authenticated', {authenticated: true, error: ""});
            authenticated = true;

            // Check if a socket with that user is already connected.
            if(user.id in pendingUser){

                // Get the already connected socket
                let peerUser = pendingUser[user.id];

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
                delete pendingUser[user._id];

            }else {
                // If no client with that user is connected, set the current client as pending
                pendingUser[user.id] = {socket: socket, rule: rule};
            }
        });
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
