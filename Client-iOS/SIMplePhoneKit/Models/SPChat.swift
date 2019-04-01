//
//  SPChat.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 31.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import RealmSwift

/// Data object representing a chat conversation
public class SPChat: Object {
    /// Identifier of the conversation
    @objc public dynamic var id: String = NSUUID().uuidString
    /// The SPGateway used for the transfer of the messages
    @objc public dynamic var gateway: SPGateway?
    /// The other party of the conversation
    public var secondParty: SPNumber {
        get { return SPNumber(withNumber: _secondParty) }
        set { _secondParty = newValue.phoneNumber }
    }
    @objc private dynamic var _secondParty = ""
    /// A list of all the SPMessages of the conversation
    public let messages = List<SPMessage>()
    
    /// Initializes a SPChat object
    ///
    /// - Parameters:
    ///   - secondParty: The other party of the conversation
    ///   - gateway: The SPGateway used for the transfer of the messages
    ///   - messages: A list of all the SPMessages of the conversation
    public convenience init(with secondParty: SPNumber, on gateway: SPGateway, messages: [SPMessage]) {
        self.init()
        self.secondParty = secondParty
        self.gateway = gateway
        for message in messages {
            self.messages.append(message)
        }
    }
    
    /// Defines the primary key of the object
    ///
    /// - Returns: String representation of the primary key
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    /// Defines ignored properties by Realm
    ///
    /// - Returns: String array of the properties names
    override public static func ignoredProperties() -> [String] {
        return ["secondParty"]
    }
}

extension SPChat {
    /// Gives back the most recent message of the all the messages in the conversation
    ///
    /// - Returns: The most recent SPMessage
    public func latestMessage() -> SPMessage? {
        return messages.sorted(byKeyPath: "time", ascending: false).first
    }
    
    /// Checks whether a SPChat suites a given search term
    ///
    /// - Parameter searchTerm: The string that should be matched
    /// - Returns: Whether the chat is a appropriate search result
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
