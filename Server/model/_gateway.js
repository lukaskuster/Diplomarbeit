const mongoose = require('mongoose');
const sms = require('./_sms');


let GatewaySchema = new mongoose.Schema({
    _id: String,
    name: String,
    phoneNumber: String,
    signalStrength: Number,
    carrier: String,
    firmwareVersion: String,
    color: String,
    newSMS: [sms]
}, {_id: false});

GatewaySchema.method('toClient', function () {
    let obj = this.toObject({versionKey: false});

    obj.imei = obj._id;
    delete obj._id;
    delete obj.newSMS;

    return obj;
});

module.exports = GatewaySchema;

