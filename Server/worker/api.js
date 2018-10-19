const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const routes = require('../controller');

const app = express();

const collection = 'simple-phone';
const port = 3000;

mongoose.connect('mongodb://localhost/' + collection);
mongoose.Promise = global.Promise;

let db = mongoose.connection;

db.on('error', console.error.bind(console, 'MongoDB connection error:'));

app.use(bodyParser.json());
app.use('/v1', routes);

app.listen(port, function () {
    console.log('Listening on port ' + port);
});