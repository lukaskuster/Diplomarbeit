const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const routes = require('./controller');


const app = express();

const HOST = '127.0.0.1';
const COLLECTION_NAME = 'simple-phone';
const PORT = 3000;

mongoose.connect('mongodb://' + HOST + '/' + COLLECTION_NAME);
mongoose.Promise = global.Promise;

let db = mongoose.connection;

db.on('error', console.error.bind(console, 'MongoDB connection error:'));

app.use(bodyParser.json());
app.use('/api', routes);

app.listen(PORT, function () {
    console.log('Listening on port ' + PORT);
});