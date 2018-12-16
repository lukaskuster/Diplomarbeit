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
        get { return (SPDevice.local?.sync ?? true) ? .cloud : .local }
        set { SPDevice.local?.sync = (newValue == .cloud) }
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
    
    public func getUsername() -> String? {
        switch keychainEnvironment {
        case .cloud:
            return self.cloudKeychain.get("username")
        case .local:
            return self.localKeychain.get("username")
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
                completion(false, APIError.other(desc: "\(error!)"))
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
            if reportToServer {
                self.apiClient.revokeThisDevice { (success, error) in
                    if success {
                        self.localKeychain.delete("username")
                        self.localKeychain.delete("password")
                    }
                    completion(success, error)
                }
            }else{
                self.localKeychain.delete("username")
                self.localKeychain.delete("password")
                completion(true, nil)
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
    @objc public func getAllChats(completion: @escaping (_ success: Bool, _ chats: [SPChat]?, _ error: Error?) -> Void) {
        let gateway = SPGateway(withIMEI: NSUUID().uuidString, name: "Main-Gateway", phoneNumber: "00436648338455", signalStrength: 0.0, firmwareVersion: "0.0.1", carrier: "spusu")
        let secondParty1 = SPNumber(withNumber: "00436643038891")
        let secondParty2 = SPNumber(withNumber: "00436644523954")
        let msgs = [SPMessage("test msg", state: .sent), SPMessage("test msg 2", state: .sent)]
        let chat1 = SPChat(with: secondParty1, on: gateway, messages: msgs)
        let chat2 = SPChat(with: secondParty2, on: gateway, messages: msgs)
        
        let chats = [chat1, chat2]
        
        completion(true, chats, nil)
    }
    
    public func sendSMS(_ message: SPMessage, in chat: SPChat, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        self.apiClient.pushEventToGateway(chat.gateway!, event: APIClient.GatewayPushEvent.sendSMS(to: chat.secondParty.phoneNumber, message: message.text)) { (success, response, error) in
            if success {
                message.state = SPMessageState.sent
                RealmManager.shared.addMessageToChat(message: message, chat: chat)
                completion(true, nil)
            }else{
                message.state = SPMessageState.failed
                RealmManager.shared.addMessageToChat(message: message, chat: chat)
                completion(false, error!)
            }
        }
    }
    
    public func dial(number: SPNumber, with gateway: SPGateway, completion: @escaping (_ success: Bool, _ response: String?, _ error: Error?) -> Void) {
        self.apiClient.pushEventToGateway(gateway, event: .dial(number: number.phoneNumber)) { (success, response, error) in
            completion(success, String(describing: response?.array), error)
        }
    }
    
    public func hangUpCurrentCall(on gateway: SPGateway, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        self.apiClient.pushEventToGateway(gateway, event: .hangUp) { (success, response, error) in
            completion(success, error)
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
    
    public func updateGatewayName(_ name: String, of gateway: SPGateway, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        self.apiClient.updateGateway(name: name, of: gateway) { (success, error) in
            completion(success, error)
        }
    }
    
    // MARK: - Just for testing purposes (Will be deleted)
    public func addRecentCall(_ call: SPRecentCall) {
        self.realmManager.addNewRecentCall(call)
    }

    public func addVoicemail(_ voicemail: SPVoicemail) {
        self.realmManager.addNewVoicemail(voicemail)
    }
    
    public func getiCloudSyncState() -> Bool? {
        if let localDevice = SPDevice.local {
            return localDevice.sync
        }else{
            return nil
        }
    }
    
    public func setiCloudSyncState(_ newState: Bool, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        self.apiClient.setiCloudSyncState(newState) { (success, error) in
            if success {
                SPDevice.local?.sync = newState
                completion(true, nil)
            }else{
                completion(false, error!)
            }
        }
    }
    
    public func getAllDevices(completion: @escaping (_ success: Bool, _ devices: [SPDevice]?, _ error: APIError?) -> Void) {
        self.apiClient.getAllDevices { (success, devices, error) in
            completion(success, devices, error)
        }
        
    }
    
    public func revoke(device: SPDevice, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        self.apiClient.revokeDevice(withId: device.id) { (success, error) in
            completion(success, error)
        }
    }
    
    
    
    // MARK: - Push notification related
    @objc public func receivedPushDeviceToken(_ data: Data, completion: @escaping (_ gotRevoked: Bool) -> Void) {
        let token = data.reduce("", {$0 + String(format: "%02X", $1)})
        let modelName = UIDevice().modelName
        let deviceName = UIDevice().name
        let systemVersion = UIDevice().systemVersion
        let language = Locale.current.languageCode ?? "en"
        let icloudSync = (self.keychainEnvironment == .cloud)
        
        let device = SPDevice(name: deviceName, systemVersion: systemVersion, deviceModelName: modelName, language: language, sync: icloudSync, apnKey: token)
        
        self.apiClient.register(deviceWithServer: device) { (success, error) in
            if success {
                completion(false)
            }else{
                if case APIError.noDeviceFound = error! {
                    self.logoutUser(reportToServer: false, completion: { (success, error) in
                        if success {
                            completion(true)
                        }else{
                            fatalError("Error while acting on device revocation (\(error!))")
                        }
                    })
                }else{
                    print("receivedPushDeviceToken \(error!)")
                    completion(false)
                }
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
