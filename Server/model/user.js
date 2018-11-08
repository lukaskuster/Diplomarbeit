const mongoose = require('mongoose');
const uniqueValidator = require('mongoose-unique-validator');
const gateway = require('./_gateway');
const device = require('./_device');


let UserSchema = new mongoose.Schema({
    _id: String,
    firstName: String,
    lastName: String,
    password: {type: String, required: true},
    gateway: [gateway],
    device: [device]
},{ _id: false });

UserSchema.method('toClient', function() {
    let obj = this.toObject({ versionKey: false });

    obj.mail = obj._id;
    delete obj._id;
    delete obj.password;
    delete obj.gateway;
    delete obj.device;

    return obj;
});

UserSchema.plugin(uniqueValidator);

module.exports = mongoose.model('User', UserSchema);