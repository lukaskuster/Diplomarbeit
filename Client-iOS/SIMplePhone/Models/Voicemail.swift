//
//  Voicemail.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 17.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import Contacts
import AVFoundation

@objc class Voicemail: NSObject {
    var heard: Bool
    var date: Date
    var originPhoneNumber: String
    var gateway: Gateway
    var audioFilePath: String
    var duration: TimeInterval?
    
    @objc init(_ gateway: Gateway, date: Date, origin originNumber: String, audio audioPath: String) {
        self.heard = false
        self.date = date
        self.originPhoneNumber = originNumber
        self.gateway = gateway
        self.audioFilePath = audioPath
        
        super.init()
        self.duration = calcDuration(forPath: audioPath)
    }
}

extension Voicemail {
    private func calcDuration(forPath fileURL: String) -> TimeInterval {
        let asset = AVURLAsset(url: URL(fileURLWithPath: fileURL))
        let duration = asset.duration
        return duration.seconds
    }
    
//    private func findContactForNumber(_ phoneNumber: String) -> CNContact? {
//
//    }
}
