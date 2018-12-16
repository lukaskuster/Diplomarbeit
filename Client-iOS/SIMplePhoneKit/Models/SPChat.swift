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
    @objc public var secondParty: SPNumber {
        get { return SPNumber(withNumber: _secondParty) }
        set { _secondParty = newValue.phoneNumber }
    }
    @objc private dynamic var _secondParty = ""
    private let messages = List<SPMessage>()
    
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
    @objc public func latestMessage() -> SPMessage? {
        return realm?.objects(SPMessage.self).filter("chats.id = '\(self.id)'").sorted(byKeyPath: "time", ascending: false).first
    }
}
