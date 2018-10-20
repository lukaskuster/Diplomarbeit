const mongoose = require('mongoose');
const sms = require('./_sms');


module.exports = new mongoose.Schema({
    _id: {type: String},
    signalStrength: Number,
    newSMS: [sms]
},{ _id: false });

