const WebSocket = require('ws');
const User = require('../model/user');
const md5 = require('md5');
const mongoose = require('mongoose');


// Port on that the server listens
const port = 10001;

// Collection name of the mongo db
const collection = 'simple-phone';


// Connect to the database
mongoose.connect('mongodb://localhost/' + collection);
mongoose.Promise = global.Promise;
let db = mongoose.connection;

// Check for errors
db.on('error', console.error.bind(console, 'MongoDB connection error:'));


const server = new WebSocket.Server({port: port, keepAlive: true});

let peers = new WeakMap();
let pendingUser = {};

server.on('connection', function connection(socket) {

    // Indicates if the client is authorized to use the exchange events
    let authenticated = false;

    // Authentication event that requires username and password
    const authenticate = function ({username, password, role}) {

        // If the role is not passed, set it to offer
        if (!role) {
            role = 0;
        }
        console.log('Role: ' + role);

        let response = {
            event: 'authenticate',
            authenticated: false,
            error: ''
        };

        // Send an authorization error if the username or password is not passed
        if (!username || !password) {
            response.error = 'No username or password was in the request!';
            socket.send(JSON.stringify(response));
            return;
        }

        // Search mongo db for the requested mail
        User.findById(username, function (err, user) {
            if (err || !user) {
                // Send an authorization error if the username doesn't exist
                response.error = 'Username does not exist!';
                socket.send(JSON.stringify(response));
                return;
            }

            if (md5(password) !== user.password) {
                // Send an authorization error if the password is wrong
                response.error = 'Wrong password!';
                socket.send(JSON.stringify(response));
                return;
            }

            // The authorization was successful
            authenticated = true;
            response.authenticated = true;
            socket.send(JSON.stringify(response));

            socket.on('close', function () {

            });
            // Check if a socket with that user is already connected.
            if (user._id in pendingUser) {

                // Get the already connected socket
                let peerUser = pendingUser[user._id];

                // Set the remote peer for both sockets
                peers.set(peerUser.socket, socket);
                peers.set(socket, peerUser.socket);

                // Check if the peer user is still connected
                try {
                    peerUser.socket.send('');
                } catch (e) {
                    // If the peer user is disconnected
                    pendingUser[user._id] = {socket: socket, role: role};
                    return;
                }

                // Check if the first user set answer as role and start the interconnection accordingly
                // The role of the second connected client is ignored
                // Role: 1 = Answer
                //       0 = Offer
                if (peerUser.role === 1) {
                    socket.send(JSON.stringify({event: 'start'}))
                } else {
                    peerUser.socket.send(JSON.stringify({event: 'start'}));
                }

                // Now the first user pending any more
                delete pendingUser[user._id];

            } else {
                // If no client with that user is connected, set the current client as pending
                pendingUser[user._id] = {socket: socket, role: role};
            }
        });
    };

    // Routes the message to the peer client
    const forwardMessage = function (data) {
        if (authenticated) {
            peers.get(socket).send(JSON.stringify(data));
        }
    };


    socket.on('message', function incoming(message) {
        try {
            // Get the data as object
            let data = JSON.parse(message);

            // Call the event methods
            if ('event' in data) {
                switch (data['event']) {
                    case 'authenticate':
                        authenticate(data);
                        break;
                    case 'offer':
                        forwardMessage(data);
                        break;
                    case 'answer':
                        forwardMessage(data);
                        break
                }
            }
        } catch (e) {
            console.log(e)
        }
    });
});