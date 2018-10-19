const mongoose = require('mongoose');
const uniqueValidator = require('mongoose-unique-validator');


let UserSchema = new mongoose.Schema({
    firstName: String,
    lastName: String,
    mail: {type: String, required: true, unique: true},
    password: {type: String, required: true}
});

UserSchema.plugin(uniqueValidator);

module.exports = mongoose.model('User', UserSchema);