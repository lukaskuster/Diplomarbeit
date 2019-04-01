//
//  SPAccount.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 13.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation

/// Data object representing an users account
public class SPAccount: NSObject {
    /// The given name of the user
    public var givenName: String
    /// The family name of the user
    public var familyName: String
    /// The username of the user
    public var username: String
    /// The password of the user
    public var password: String
    
    /// Initializer of SPAccount
    ///
    /// - Parameters:
    ///   - givenName: The given name of the user
    ///   - familyName: The family name of the user
    ///   - username: The username of the user
    ///   - password: The password of the user
    public init(givenName: String, familyName: String, username: String, password: String) {
        self.givenName = givenName
        self.familyName = familyName
        self.username = username
        self.password = password
    }
}
