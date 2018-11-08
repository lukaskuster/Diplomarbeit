const mongoose = require('mongoose');
const sms = require('./_sms');


let GatewaySchema = new mongoose.Schema({
    _id: String,
    signalStrength: Number,
    newSMS: [sms]
},{ _id: false });

GatewaySchema.method('toClient', function() {
    let obj = this.toObject({ versionKey: false });

    obj.id = obj._id;
    delete obj._id;

    return obj;
});

module.exports = GatewaySchema;

