//
//  SPRecentCall.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 31.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import RealmSwift

public class SPRecentCall: Object {
    public enum Direction: Int {
        case outgoing
        case incoming
    }
    
    @objc dynamic var id: String = NSUUID().uuidString
    @objc dynamic var seen: Bool = false
    @objc public dynamic var time = Date(timeIntervalSince1970: 1)
    public var secondParty: SPNumber {
        get { return SPNumber(withNumber: _secondParty) }
        set { _secondParty = newValue.phoneNumber }
    }
    @objc private dynamic var _secondParty = ""
    @objc private dynamic var _duration: Double = 0
    public var duration: TimeInterval {
        get { return TimeInterval(exactly: _duration)! }
        set { _duration = Double(newValue) }
    }
    @objc private dynamic var _direction = SPRecentCall.Direction.outgoing.rawValue
    public var direction: SPRecentCall.Direction {
        get { return SPRecentCall.Direction(rawValue: _direction)! }
        set { _direction = newValue.rawValue }
    }
    @objc public dynamic var missed: Bool = false
    @objc public dynamic var gateway: SPGateway?
    
    public convenience init(with secondParty: SPNumber, at time: Date?, for duration: TimeInterval?, direction: SPRecentCall.Direction, missed: Bool, gateway: SPGateway) {
        self.init()
        self.secondParty = secondParty
        self.time = time ?? Date()
        self.duration = duration ?? TimeInterval(0)
        self.direction = direction
        self.missed = missed
        try! realm?.write {
            if let gatewayInDB = realm?.object(ofType: SPGateway.self, forPrimaryKey: gateway.imei) {
                self.gateway = gatewayInDB
            }else{
                self.gateway = gateway
            }
        }
    }
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["duration", "direction", "secondParty"]
    }
}
