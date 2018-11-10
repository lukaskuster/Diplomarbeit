//
//  SPManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 07.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import KeychainSwift

@objc public class SPManager: NSObject {
    public static let shared = SPManager()
    private var realmManager: RealmManager
    private var apiClient: APIClient
    private var keychain: KeychainSwift
    private var keychainSync: Bool {
        didSet {
            self.keychain.synchronizable = keychainSync
        }
    }
    
    private override init() {
        self.realmManager = RealmManager.shared
        self.apiClient = APIClient.shared
        self.keychain = KeychainSwift()
        self.keychainSync = true
    }
    
    // MARK: - User access control
    public func disableiCloudSync(_ disable: Bool = true) {
        if disable {
            self.keychainSync = true
            self.keychain.delete("username")
            self.keychain.delete("password")
        }
        self.keychainSync = disable ? false : true
    }
    
    public func loginWithiCloudAvailable() -> Bool {
        self.keychainSync = true
        if self.keychain.get("username") != nil && self.keychain.get("password") != nil {
            self.keychainSync = false
            return true
        }else{
            self.keychainSync = false
            return false
        }
    }
    
    public func loginWithiCloud(completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        self.keychainSync = true
        if let username = self.keychain.get("username"),
            let password = self.keychain.get("password") {
            self.apiClient.loginUser(username: username, password: password) { (success, error) in
                completion(success, error)
            }
        }
    }
    
    public func loginUser(username: String, password: String, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        self.apiClient.loginUser(username: username, password: password) { (success, error) in
            if success {
                self.keychainSync = true
                self.keychainSync = (self.keychain.get("username") != nil && self.keychain.get("password") != nil) ? false : true
                self.keychain.set(username, forKey: "username")
                self.keychain.set(password, forKey: "password")
                completion(true, nil)
            }else{
                completion(false, error!)
            }
        }
    }
    
    public func logoutUser(reportToServer: Bool = true, onAllDevices: Bool = false, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        if onAllDevices {
            self.keychain.delete("username")
            self.keychain.delete("password")
        }else{
            self.keychainSync = false
            self.keychain.delete("username")
            self.keychain.delete("password")
        }
        
        if reportToServer {
            self.apiClient.revokeThisDevice { (success, error) in
                completion(success, error)
            }
        }else{
            completion(true, nil)
        }
    }
    
    @objc public func isAuthetificated(completion: @escaping (_ loggedIn: Bool) -> Void) {
        if let username = self.keychain.get("username"),
            let password = self.keychain.get("password") {
            self.apiClient.loginUser(username: username, password: password) { (success, error) in
                if success {
                    completion(true)
                }else{
                    completion(false)
                }
            }
        }else{
            completion(false)
        }
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
        self.apiClient.pushEventToGateway(chat.gateway!, event: APIClient.GatewayPushEvent.sendSMS(to: chat.secondParty.phoneNumber, message: message.text)) { (success, response, error) in
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
        self.apiClient.getAllGateways { (success, gateways, error) in
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
    @objc public func receivedPushDeviceToken(_ data: Data, completion: @escaping (_ gotRevoked: Bool) -> Void) {
        let token = data.reduce("", {$0 + String(format: "%02X", $1)})
        let modelName = UIDevice().modelName
        let deviceName = UIDevice().name
        let systemVersion = UIDevice().systemVersion
        let language = Locale.current.languageCode
        
        self.apiClient.registerDeviceWithServer(apnToken: token, deviceName: deviceName, modelName: modelName, systemVersion: systemVersion, language: language) { (success, error) in
            if !success {
                if case APIError.noDeviceFound = error! {
                    self.logoutUser(reportToServer: false, completion: { (success, error) in
                        if success {
                            completion(true)
                        }else{
                            fatalError("Error while acting on device revocation (\(error!.localizedDescription))")
                        }
                    })
                }else{
                    completion(true)
                }
            }else{
                completion(false)
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
