const mongoose = require('mongoose');

let UserSchema = new mongoose.Schema({
    mail: String,
    password: String
});

module.exports = mongoose.model('User', UserSchema);