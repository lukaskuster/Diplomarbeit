const mongoose = require('mongoose');

let UserSchema = new mongoose.Schema({
    ip: String
});

module.exports = mongoose.model('User', UserSchema);