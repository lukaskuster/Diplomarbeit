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
    @objc public dynamic var name = ""
    @objc public dynamic var phoneNumber = ""
    @objc public dynamic var signalStrength: Double = 0.0
    
    public convenience init(withIMEI imei: String, name: String, phoneNumber: String) {
        self.init()
        self.imei = imei
        self.name = name
        self.phoneNumber = phoneNumber
    }
    
    override public static func primaryKey() -> String? {
        return "imei"
    }
}
