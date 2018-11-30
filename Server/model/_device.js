const mongoose = require('mongoose');


DeviceSchema = new mongoose.Schema({
    _id: String,
    language: {type: String, default: 'en'},
    deviceModelName: String,
    systemVersion: String,
    apnToken: String,
    deviceName: String,
    isSync: {type: Boolean, default: false}
}, {_id: false});

DeviceSchema.method('toClient', function () {
    let obj = this.toObject({versionKey: false});

    obj.id = obj._id;
    obj.sync = obj.isSync;
    delete obj._id;
    delete obj.apnToken;
    delete obj.isSync;

    return obj;
});

module.exports = DeviceSchema;