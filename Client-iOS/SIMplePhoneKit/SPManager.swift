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

    // MARK: - Recent Calls
    public func getRecentCalls() -> [SPRecentCall]? {
        return self.realmManager.getAllRecentCalls()
    }
    
    public func deleteRecentCall(_ call: SPRecentCall) {
        self.realmManager.deleteRecentCall(call)
    }
    
    @objc public func getCountOfUnseenRecentCalls() -> Int {
        return self.realmManager.getCountOfUnseenRecentCalls()
    }
    
    // MARK: - Chats
    public func sendSMS(_ message: SPMessage, in chat: SPChat, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        APIClient.shared.pushEventToGateway(chat.gateway!, event: APIClient.GatewayPushEvent.sendSMS(to: chat.secondParty.phoneNumber, message: message.text)) { (success, response, error) in
            if success {
                message.type = SPMessageState.sent
                RealmManager.shared.addMessageToChat(message: message, chat: chat)
                completion(true, nil)
            }else{
                message.type = SPMessageState.failed
                RealmManager.shared.addMessageToChat(message: message, chat: chat)
                completion(false, error!)
            }
        }
    }
    
    // MARK: - Voicemail
    public func getVoicemails() -> [SPVoicemail]? {
        if let voicemails = self.checkForNewVoicemails() {
            for voicemail in voicemails {
                self.realmManager.addNewVoicemail(voicemail)
            }
        }
        return self.realmManager.getAllVoicemails()
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
    
    func checkForNewVoicemails() -> [SPVoicemail]? {
        // TODO: Implement
        return nil
    }
    
    // MARK: - Settings
    public func changeUserPassword(new: String, old: String, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        completion(false, APIError.other(desc: "not yet implemented"))
    }
    
    public func getUserData(completion: @escaping (_ user: [String:String]?, _ error: Error?) -> Void) {
        completion(nil, APIError.other(desc: "not yet implemented"))
    }
    
    public func getAllGateways(completion: @escaping (_ success: Bool, _ gateways: [SPGateway]?, _ error: Error?) -> Void) {
        APIClient.shared.getAllGateways { (success, gateways, error) in
            completion(success, gateways, error)
        }
    }
    
    // MARK: - Just for testing purposes (Will be deleted)
    public func addRecentCall(_ call: SPRecentCall) {
        self.realmManager.addNewRecentCall(call)
    }

    public func addVoicemail(_ voicemail: SPVoicemail) {
        self.realmManager.addNewVoicemail(voicemail)
    }
    
    // MARK: - Push notification related
    @objc public func receivedPushDeviceToken(_ data: Data) {
        let token = data.reduce("", {$0 + String(format: "%02X", $1)})
        let modelName = UIDevice().modelName
        let deviceName = UIDevice().name
        let systemVersion = UIDevice().systemVersion
        let language = Locale.current.languageCode
        
        APIClient.shared.registerDeviceWithServer(apnToken: token, deviceName: deviceName, modelName: modelName, systemVersion: systemVersion, language: language) { (success, error) in
            if !success {
                if case APIError.noDeviceFound = error! {
                    // TODO: Shit just hit the fan!!! Device got revoked. Figure out what the fuck to do!
                    print("device got revoked")
                }
                print(error!.localizedDescription)
            }
        }
    }
    
    // MARK: Obj-C related
    @objc public class func sharedInstance() -> SPManager {
        return self.shared
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
