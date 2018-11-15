//
//  SPManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 07.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import KeychainSwift
import CloudKit

@objc public class SPManager: NSObject {
    public static let shared = SPManager()
    private var realmManager: RealmManager
    private var apiClient: APIClient
    private var keychainEnvironment: SPKeychainEnvironment {
        get { return SPKeychainEnvironment(rawValue: UserDefaults.standard.integer(forKey: "keychainEnvironment")) ?? .local }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "keychainEnvironment") }
    }
    private var cloudKeychain: KeychainSwift
    private var localKeychain: KeychainSwift
    private var cloudContainer: CKContainer
    
    private override init() {
        self.realmManager = RealmManager.shared
        self.apiClient = APIClient.shared
        self.cloudKeychain = KeychainSwift()
        self.cloudKeychain.synchronizable = true
        self.localKeychain = KeychainSwift()
        self.localKeychain.synchronizable = false
        self.cloudContainer = CKContainer.default()
    }
    
    // MARK: - Account
    public func registerNewAccount(_ account: SPAccount, keychainEnvironment: SPKeychainEnvironment, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        self.apiClient.registerAccount(account) { (success, error) in
            if success {
                self.loginUser(username: account.username, password: account.password, keychainEnvironment: keychainEnvironment, completion: { (success, error) in
                    if success {
                        switch keychainEnvironment {
                        case .cloud:
                            self.keychainEnvironment = .cloud
                            self.cloudKeychain.set(account.username, forKey: "username")
                            self.cloudKeychain.set(account.password, forKey: "password")
                        case .local:
                            self.keychainEnvironment = .local
                            self.localKeychain.set(account.username, forKey: "username")
                            self.localKeychain.set(account.password, forKey: "password")
                        }
                        completion(true, nil)
                    }else{
                        completion(false, error!)
                    }
                })
            }else{
                completion(false, error!)
            }
        }
    }
    
    // MARK: - iCloud Related
    public enum SPKeychainEnvironment: Int {
        case cloud
        case local
    }
    public enum SPCloudSharingError {
        case cloudAlreadyAssociatedWithDifferentAccount
        case accountAssociatedWithDifferentCloud
    }
    
    public func checkUsernameWithCloud(_ username: String, completion: @escaping (_ error: SPCloudSharingError?) -> Void) {
        if let usernameInKeychain = self.cloudKeychain.get("username") {
            if usernameInKeychain != username {
                completion(.cloudAlreadyAssociatedWithDifferentAccount)
                return
            }
        }
        completion(nil)
    }
    
    private func getCloudUserId(completion: @escaping (_ cloudUserId: String?, _ error: Error?) -> Void) {
        self.cloudContainer.fetchUserRecordID { (recordId, error) in
            if let cloudUserId = recordId?.recordName {
                completion(cloudUserId, nil)
            }else{
                completion(nil, error)
            }
        }
    }
    
    public func loginUser(username: String, password: String, keychainEnvironment: SPKeychainEnvironment, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        self.getCloudUserId { (cloudUserId, error) in
            if let cloudUserId = cloudUserId {
                self.apiClient.loginUser(username: username, password: password, cloudUserId: cloudUserId, environment: keychainEnvironment, completion: { (success, error) in
                    if success {
                        switch keychainEnvironment {
                        case .cloud:
                            self.keychainEnvironment = .cloud
                            self.cloudKeychain.set(username, forKey: "username")
                            self.cloudKeychain.set(password, forKey: "password")
                        case .local:
                            self.keychainEnvironment = .local
                            self.localKeychain.set(username, forKey: "username")
                            self.localKeychain.set(password, forKey: "password")
                        }
                        completion(true, nil)
                    }else{
                        completion(false, error!)
                    }
                })
                
            }else{
                completion(false, APIError.other(desc: error!.localizedDescription))
            }
        }
    }
    
    public func logoutUser(reportToServer: Bool = true, onAllDevices: Bool = false, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        if self.keychainEnvironment == .cloud {
            if onAllDevices {
                if reportToServer {
                    self.apiClient.revokeAllDevicesWithiCloudSyncEnabled { (success, error) in
                        if success {
                            self.cloudKeychain.delete("username")
                            self.cloudKeychain.delete("password")
                        }
                        completion(success, error)
                    }
                }else{
                    self.cloudKeychain.delete("username")
                    self.cloudKeychain.delete("password")
                    completion(true, nil)
                }
            }else{
                if reportToServer {
                    self.apiClient.revokeThisDevice { (success, error) in
                        if success {
                            self.keychainEnvironment = .local
                        }
                        completion(success, error)
                    }
                }else{
                    self.keychainEnvironment = .local
                    completion(true, nil)
                }
            }
        }else{
            self.apiClient.revokeThisDevice { (success, error) in
                if success {
                    self.localKeychain.delete("username")
                    self.localKeychain.delete("password")
                }
                completion(success, error)
            }
        }
    }
    
    // MARK: - User access control
    
    @objc public func isAuthetificated(completion: @escaping (_ loggedIn: Bool) -> Void) {
        let keychain: KeychainSwift
        switch self.keychainEnvironment {
        case .cloud:
            keychain = self.cloudKeychain
        case .local:
            keychain = self.localKeychain
        }
        
        if let username = keychain.get("username"),
            let password = keychain.get("password") {
            self.apiClient.loginUser(username: username, password: password) { (success, error) in
                if success {
                    completion(true)
                }else{
                    print(error!)
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
        let icloudSync = (self.keychainEnvironment == .cloud)
        
        self.apiClient.registerDeviceWithServer(apnToken: token, deviceName: deviceName, modelName: modelName, systemVersion: systemVersion, language: language, icloudSync: icloudSync) { (success, error) in
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
