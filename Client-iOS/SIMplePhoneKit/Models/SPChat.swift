//
//  SPChat.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 31.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import RealmSwift

public class SPChat: Object {
    @objc public dynamic var id: String = NSUUID().uuidString
    @objc public dynamic var gateway: SPGateway?
    public var secondParty: SPNumber {
        get { return SPNumber(withNumber: _secondParty) }
        set { _secondParty = newValue.phoneNumber }
    }
    @objc private dynamic var _secondParty = ""
    public let messages = List<SPMessage>()
    
    public convenience init(with secondParty: SPNumber, on gateway: SPGateway, messages: [SPMessage]) {
        self.init()
        self.secondParty = secondParty
        self.gateway = gateway
        for message in messages {
            self.messages.append(message)
        }
    }
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["secondParty"]
    }
}

extension SPChat {
    public func latestMessage() -> SPMessage? {
        return messages.sorted(byKeyPath: "time", ascending: false).first
    }
    
    public func matches(_ searchTerm: String) -> Bool {
        if let contact = self.secondParty.contact {
            if contact.givenName.contains(searchTerm) {
                return true
            }
            if contact.familyName.contains(searchTerm) {
                return true
            }
            if contact.organizationName.contains(searchTerm) {
                return true
            }
        }else{
            if self.secondParty.phoneNumber.contains(searchTerm) {
                return true
            }
        }
        
        if let gatewayName = self.gateway?.name {
            if gatewayName.contains(searchTerm) {
                return true
            }
        }
        
        // Not included
//        for message in self.messages {
//            if message.text.contains(searchTerm) {
//                return (true, message)
//            }
//        }
        
        return false
    }
}
