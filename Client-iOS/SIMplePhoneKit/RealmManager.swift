//
//  RealmManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 07.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import RealmSwift

class RealmManager: NSObject {
    public static let shared = RealmManager()
    private var realm: Realm
    
    private override init() {
        self.realm = try! Realm()
    }
    
    public func getAllRecentCalls() -> [SPRecentCall]? {
        let calls = self.realm.objects(SPRecentCall.self).toArray(ofType: SPRecentCall.self) as [SPRecentCall]
        for call in calls {
            try! self.realm.write {
                call.seen = true
            }
        }
        return calls.count > 0 ? calls.sorted(by: {$0.time.timeIntervalSince1970 > $1.time.timeIntervalSince1970}) : nil
    }
    
    public func addNewRecentCall(_ call: SPRecentCall) {
        self.realmAdd(call)
    }
    
    public func deleteRecentCall(_ call: SPRecentCall) {
        self.realmDelete(call)
    }
    
    public func getCountOfUnseenRecentCalls() -> Int {
        let recentCalls = realm.objects(SPRecentCall.self).filter("seen = false")
        return recentCalls.count
    }
    
    public func getAllChats() -> [SPChat]? {
        let chats = self.realm.objects(SPChat.self).toArray(ofType: SPChat.self) as [SPChat]
        return chats.count > 0 ? chats : nil
    }
    
    public func getAllVoicemails() -> [SPVoicemail]? {
        let voicemails = self.realm.objects(SPVoicemail.self).sorted(byKeyPath: "time", ascending: false).toArray(ofType: SPVoicemail.self) as [SPVoicemail]
        return voicemails.count > 0 ? voicemails : nil
    }
    
    public func getCountOfUnheardVoicemails() -> Int {
        let voicemails = realm.objects(SPVoicemail.self).filter("heard = false")
        return voicemails.count
    }
    
    public func addNewVoicemail(_ voicemail: SPVoicemail) {
        self.realmAdd(voicemail)
    }
    
    public func getVoicemail(byId id: String) -> SPVoicemail? {
        let voicemails = realm.objects(SPVoicemail.self).filter("id = '\(id)'")
        return voicemails.first
    }
    
    public func deleteVoicemail(_ voicemail: SPVoicemail) {
        self.realmDelete(voicemail)
    }
    
    public func markVoicemailAs(_ voicemail: SPVoicemail, heard: Bool) {
        try! self.realm.write {
            voicemail.heard = heard
        }
    }
    
    public func addMessageToChat(message: SPMessage, chat: SPChat) {
        try! self.realm.write {
//            chat.messages.append(message)
        }
    }
    
    func realmAdd(_ object: Object) {
        try! self.realm.write {
            self.realm.add(object)
        }
    }
    
    func realmDelete(_ object: Object) {
        try! self.realm.write {
            self.realm.delete(object)
        }
    }
}
