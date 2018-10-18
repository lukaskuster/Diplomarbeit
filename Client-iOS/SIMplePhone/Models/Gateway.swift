//
//  Gateway.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 18.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import Contacts

class Gateway: NSObject {
    var imei: String
    var name: String
    var phoneNumber: CNPhoneNumber
    
    init(imei: String, name: String, number phoneNumber: CNPhoneNumber) {
        self.imei = imei
        self.name = name
        self.phoneNumber = phoneNumber
        super.init()
    }
    
}
