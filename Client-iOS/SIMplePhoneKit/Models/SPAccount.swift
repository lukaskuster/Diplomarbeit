//
//  SPAccount.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 13.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation

public class SPAccount: NSObject {
    public var givenName: String
    public var familyName: String
    public var username: String
    public var password: String
    
    public init(givenName: String, familyName: String, username: String, password: String) {
        self.givenName = givenName
        self.familyName = familyName
        self.username = username
        self.password = password
    }
}
