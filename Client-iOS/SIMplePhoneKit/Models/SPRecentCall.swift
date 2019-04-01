//
//  SPRecentCall.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 31.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import RealmSwift

/// Data object representing a recent call
public class SPRecentCall: Object {
    /// Direction of the Call
    public enum Direction: Int {
        /// Outgoing Call
        case outgoing
        /// Incoming Call
        case incoming
    }
    
    /// Identifier of the Recent Call
    @objc public dynamic var id: String = NSUUID().uuidString
    /// Indicates whether the call has already been seen by the user or not
    @objc public dynamic var seen: Bool = false
    /// The Date When the call started
    @objc public dynamic var time = Date(timeIntervalSince1970: 1)
    /// The second party (e.g. other caller) of the call
    public var secondParty: SPNumber {
        get { return SPNumber(withNumber: _secondParty) }
        set { _secondParty = newValue.phoneNumber }
    }
    @objc private dynamic var _secondParty = ""
    @objc private dynamic var _duration: Double = 0
    /// The duration of the call
    public var duration: TimeInterval {
        get { return TimeInterval(exactly: _duration)! }
        set { _duration = Double(newValue) }
    }
    @objc private dynamic var _direction = SPRecentCall.Direction.outgoing.rawValue
    /// The direction of the call (e.g. incoming or outgoing)
    public var direction: SPRecentCall.Direction {
        get { return SPRecentCall.Direction(rawValue: _direction)! }
        set { _direction = newValue.rawValue }
    }
    /// Indicates whether the call was missed or not
    @objc public dynamic var missed: Bool = false
    /// The SPGateway that was used for the call
    @objc public dynamic var gateway: SPGateway?
    
    /// Initializes a SPRecentCall object
    ///
    /// - Parameters:
    ///   - secondParty: The second party (e.g. other caller) of the call
    ///   - time: The Date When the call started
    ///   - duration: The duration of the call
    ///   - direction: The direction of the call (e.g. incoming or outgoing)
    ///   - missed: Indicates whether the call was missed or not
    ///   - gateway: The SPGateway that was used for the call
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
        return ["duration", "direction", "secondParty"]
    }
}
