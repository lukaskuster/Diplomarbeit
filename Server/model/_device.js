const mongoose = require('mongoose');


DeviceSchema = new mongoose.Schema({
    _id: String,
    language: String,
    deviceModelName: String,
    systemVersion: String,
    apnToken: String,
    deviceName: String
}, {_id: false});

DeviceSchema.method('toClient', function() {
    let obj = this.toObject({ versionKey: false });

    obj.id = obj._id;
    delete obj._id;

    return obj;
});

module.exports = DeviceSchema;