//
//  SPVoicemail.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 31.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import RealmSwift
import AVFoundation

public class SPVoicemail: Object {
    @objc dynamic var id: String = NSUUID().uuidString
    @objc public dynamic var heard = false
    @objc public dynamic var time = Date(timeIntervalSince1970: 1)
    public var secondParty: SPNumber {
        get { return SPNumber(withNumber: _secondParty) }
        set { _secondParty = newValue.phoneNumber }
    }
    @objc private dynamic var _secondParty = ""
    @objc public dynamic var gateway: SPGateway?
    @objc public dynamic var duration: Double = 0.0
    @objc private dynamic var _audioFilePath = ""
    
    public convenience init(_ gateway: SPGateway, date: Date, origin: SPNumber, audio audioURL: URL) {
        self.init()
        self.heard = false
        self.time = date
        self.secondParty = origin
        self.gateway = gateway
        self._audioFilePath = audioURL.absoluteString
        self.duration = calcDuration(forPath: audioURL)
    }
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["secondParty"]
    }
}

extension SPVoicemail {
    public func getAudioFilePath() -> URL {
        return URL(fileURLWithPath: self._audioFilePath)
    }
    
    private func calcDuration(forPath fileURL: URL) -> Double {
        let asset = AVURLAsset(url: fileURL)
        let duration = asset.duration
        return duration.seconds
    }
}
