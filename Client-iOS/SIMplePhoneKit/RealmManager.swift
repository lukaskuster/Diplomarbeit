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
        self.realmAdd(call) { error in
            if let error = error {
                // handle error
                SPManager.shared.sendErrorNotification(for: error)
            }
        }
    }
    
    public func deleteRecentCall(_ call: SPRecentCall) {
        self.realmDelete(call) { error in
            if let error = error {
                // handle error
                SPManager.shared.sendErrorNotification(for: error)
            }
        }
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
        self.realmAdd(voicemail) { error in
            if let error = error {
                // handle error
                SPManager.shared.sendErrorNotification(for: error)
            }
        }
    }
    
    public func getVoicemail(byId id: String) -> SPVoicemail? {
        let voicemails = realm.objects(SPVoicemail.self).filter(NSPredicate(format: "id = %@", id))
        return voicemails.first
    }
    
    public func deleteVoicemail(_ voicemail: SPVoicemail) {
        self.realmDelete(voicemail, completion: { error in
            if let error = error {
                // handle error
                SPManager.shared.sendErrorNotification(for: error)
            }
        })
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
    
    public func saveGateways(_ gateways: [SPGateway]?, completion: @escaping (Error?) -> Void) {
        if let gateways = gateways {
            for gateway in gateways {
                self.saveGateway(gateway, completion: completion)
            }
        }
        completion(nil)
    }
    
    public func saveGateway(_ gateway: SPGateway, completion: @escaping (Error?) -> Void) {
        self.realmAdd(gateway, completion: { error in
            if let error = error {
                completion(error)
            }
        })
    }
    
    public func updateGateway(_ gateway: SPGateway, name: String, completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            do {
                try self.realm.write {
                    gateway.name = name
                    completion(nil)
                }
            } catch let error {
                completion(error)
            }
        }
    }
    
    public func updateGateway(_ gateway: SPGateway, color: UIColor, completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            do {
                try self.realm.write {
                    gateway.color = color
                    completion(nil)
                }
            } catch let error {
                completion(error)
            }
        }
    }
    
    func realmAdd(_ object: Object, completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            do {
                try self.realm.write {
                    self.realm.add(object, update: true)
                    completion(nil)
                }
            } catch let error {
                completion(error)
            }
        }
    }
    
    func realmDelete(_ object: Object, completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            do {
                try self.realm.write {
                    self.realm.delete(object)
                    completion(nil)
                }
            } catch let error {
                completion(error)
            }
        }
    }
}
