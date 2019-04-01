//
//  SPDevice.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 06.12.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation

public class SPDevice: NSObject, Codable {
    @objc public var id: String
    @objc public var name: String
    @objc public var systemVersion: String
    @objc public var deviceModelName: String
    @objc public var language: String
    @objc public var sync: Bool
    @objc public var apnToken: String?
    @objc public var voipToken: String?
    
    public var deviceModel: String {
        switch deviceModelName {
        case "iPhone10,3", "iPhone10,6":
            return "iPhone X"
        case "iPad1,1", "iPad3,1", "iPad3,2", "iPad3,3", "iPad3,4", "iPad3,5", "iPad3,6", "iPad6,11", "iPad6,12", "iPad7,5", "iPad7,6":
            return "iPad"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":
            return "iPad 2"
        case "iPad4,1", "iPad4,2", "iPad4,3":
            return "iPad Air"
        case "iPad5,3", "iPad5,4":
            return "iPad Air 2"
        case "iPad6,7", "iPad6,8", "iPad6,3", "iPad6,4", "iPad7,1", "iPad7,2", "iPad7,3", "iPad7,4", "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4", "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":
            return "iPad Pro"
        default:
            return "unknown device (\(deviceModelName))"
        }
    }
    
    init(withid id: String = UUID().uuidString, name: String, systemVersion: String, deviceModelName: String, language: String, sync: Bool, apnKey: String? = nil) {
        self.id = id
        self.name = name
        self.systemVersion = systemVersion
        self.deviceModelName = deviceModelName
        self.language = language
        self.sync = sync
        self.apnToken = apnKey
    }
    
    
    // MARK: Local Device Info
    public static var local: SPDevice? {
        set {
            print("setting local SPDevice \(newValue?.toData())")
            if let newValue = newValue {
                newValue.setAsLocal()
            }else{
                if let localDevice = SPDevice.local {
                    localDevice.remove()
                }
            }
        }
        get {
            if let loadedData = UserDefaults.standard.data(forKey: "localDevice") {
                if let encodedDevice = try? JSONDecoder().decode(SPDevice.self, from: loadedData) as SPDevice {
                    print("reading local SPDevice \(encodedDevice.toData())")
                    return encodedDevice
                }
            }
            return nil
        }
    }
    
    private func setAsLocal() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "localDevice")
        }
    }
    
    private func remove() {
        UserDefaults.standard.removeObject(forKey: "localDevice")
    }
    
    public func toData() -> [String: Any] {
        var data = ["id": self.id,
                    "deviceModelName": self.deviceModelName,
                    "deviceName": self.name,
                    "systemVersion": self.systemVersion,
                    "language": self.language,
                    "sync": self.sync] as [String : Any]
        if let apnToken = self.apnToken {
            data["apnToken"] = apnToken
        }
        if let voipToken = self.voipToken {
            data["voipToken"] = voipToken
        }
        return data
    }
    
}

extension SPDevice: Comparable {
    public static func < (lhs: SPDevice, rhs: SPDevice) -> Bool {
        return false
    }
    
    public static func == (lhs: SPDevice, rhs: SPDevice) -> Bool {
        if (lhs.id == rhs.id) &&
            (lhs.deviceModelName == rhs.deviceModelName) &&
            (lhs.name == rhs.name) &&
            (lhs.systemVersion == rhs.systemVersion) &&
            (lhs.language == rhs.language) &&
            (lhs.sync == rhs.sync) &&
            (lhs.apnToken == rhs.apnToken) &&
            (lhs.voipToken == rhs.voipToken) {
            return true
        }
        return false
    }
}
