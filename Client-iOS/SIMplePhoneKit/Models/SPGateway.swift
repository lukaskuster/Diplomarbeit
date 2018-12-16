//
//  SPGateway.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 31.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import RealmSwift

public class SPGateway: Object {
    @objc public dynamic var imei = ""
    @objc public dynamic var name: String?
    @objc public dynamic var phoneNumber: String?
    private var _signalStrength = RealmOptional<Double>()
    public var signalStrength: Double? {
        get { return _signalStrength.value }
        set { _signalStrength.value = newValue }
    }
    @objc public dynamic var firmwareVersion: String?
    @objc public dynamic var carrier: String?
    
    public convenience init(withIMEI imei: String, name: String?, phoneNumber: String?, signalStrength: Double?, firmwareVersion: String?, carrier: String?) {
        self.init()
        self.imei = imei
        self.name = name
        self.phoneNumber = phoneNumber
        self._signalStrength.value = signalStrength
        self.firmwareVersion = firmwareVersion
        self.carrier = carrier
    }
    
    override public static func primaryKey() -> String? {
        return "imei"
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["signalStrength"]
    }
}
