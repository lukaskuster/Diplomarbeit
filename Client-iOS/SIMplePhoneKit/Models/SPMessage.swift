//
//  SPMessage.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 31.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import RealmSwift

public enum SPMessageState: Int {
    case sent
    case failed
}

public class SPMessage: Object {
    @objc dynamic var id: String = NSUUID().uuidString
    @objc public dynamic var time = Date(timeIntervalSince1970: 1)
    @objc public dynamic var text = ""
    @objc private dynamic var _state = SPMessageState.sent.rawValue
    public var type: SPMessageState {
        get { return SPMessageState(rawValue: _state)! }
        set { _state = newValue.rawValue }
    }
    @objc public dynamic var gatewayIsSender = false
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["type"]
    }
}
