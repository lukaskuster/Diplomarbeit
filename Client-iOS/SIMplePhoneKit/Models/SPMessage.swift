//
//  SPMessage.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 31.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import RealmSwift

public class SPMessage: Object {
    public enum Status: Int {
        case sent
        case failed
    }
    
    public enum Direction: Int {
        case sent
        case received
    }
    
    @objc public dynamic var id: String = NSUUID().uuidString
    @objc public dynamic var time = Date(timeIntervalSince1970: 1)
    @objc public dynamic var text = ""
    @objc private dynamic var _status = Status.sent.rawValue
    public var status: Status {
        get { return Status(rawValue: _status)! }
        set { _status = newValue.rawValue }
    }
    @objc private dynamic var _direction = Direction.received.rawValue
    public var direction: Direction {
        get { return Direction(rawValue: _direction)! }
        set { _direction = newValue.rawValue }
    }
    let chats = LinkingObjects(fromType: SPChat.self, property: "messages")
    
    public convenience init(_ text: String, time: Date, status: SPMessage.Status, direction: SPMessage.Direction = .received) {
        self.init()
        self.text = text
        self.time = time
        self.status = status
        self.direction = direction
    }
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["status", "direction"]
    }
}
