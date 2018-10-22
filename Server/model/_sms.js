const mongoose = require('mongoose');


module.exports = new mongoose.Schema({
    date: Date,
    message: String,
    number: String
});
