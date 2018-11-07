//
//  SPManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 07.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation

@objc public class SPManager: NSObject {
    public static let shared = SPManager()
    private var realmManager: RealmManager
    
    private override init() {
        self.realmManager = RealmManager.shared
    }

    public func getRecentCalls() -> [SPRecentCall]? {
        return self.realmManager.getAllRecentCalls()
    }
    
    public func deleteRecentCall(_ call: SPRecentCall) {
        self.realmManager.deleteRecentCall(call)
    }
    
    public func getVoicemails() -> [SPVoicemail]? {
        if let voicemails = self.checkForNewVoicemails() {
            for voicemail in voicemails {
                self.realmManager.addNewVoicemail(voicemail)
            }
        }
        return self.realmManager.getAllVoicemails()
    }
    
    @objc public func getCountOfUnseenRecentCalls() -> Int {
        return self.realmManager.getCountOfUnseenRecentCalls()
    }
    
    public func markVoicemailAsHeard(_ voicemail: SPVoicemail) {
        self.realmManager.markVoicemailAs(voicemail, heard: true)
    }
    
    public func markVoicemailAsUnheard(_ voicemail: SPVoicemail) {
        self.realmManager.markVoicemailAs(voicemail, heard: false)
    }
    
    @objc public func getCountOfUnheardVoicemails() -> Int {
        return self.realmManager.getCountOfUnheardVoicemails()
    }
    
        // MARK: Just for testing purposes (Will be deleted)
        public func addRecentCall(_ call: SPRecentCall) {
            self.realmManager.addNewRecentCall(call)
        }
    
        public func addVoicemail(_ voicemail: SPVoicemail) {
            self.realmManager.addNewVoicemail(voicemail)
        }
    
    // MARK: API related
    func checkForNewVoicemails() -> [SPVoicemail]? {
        return nil
    }
    
    // MARK: Push notification related
    @objc public func receivedPushDeviceToken(_ data: Data) {
        let token = data.reduce("", {$0 + String(format: "%02X", $1)})
        print("Received Push Token: \(token)")
    }
    
    // MARK: Obj-C related
    @objc public class func sharedInstance() -> SPManager {
        return self.shared
    }
}

