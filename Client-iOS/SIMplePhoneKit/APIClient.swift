//
//  APIClient.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 08.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import AlamofireSwiftyJSON
import SystemConfiguration

public enum APIError: LocalizedError {
    case notAuthenticated
    case wrongCredentials
    case missing(parameter: String)
    case gatewayAlreadyExists
    case noGatewayFound
    case databaseError(desc: String)
    case deviceAlreadyExists
    case mailAlreadyExists
    case noDeviceFound
    case noGatewaysForUser
    case noDevicesForUser
    case parsingError
    case noNetworkConnection
    case differentCloudUserId
    case other(desc: String)
    
    public var errorDescription: String? {
        return "The operation couldn't be completed. (SIMplePhoneKit.APIError.\(self))"
    }
}

class APIClient: NSObject {
    public static let shared = APIClient()
    private var numberOfOngoingQueries: Int = 0
    private var username: String?
    private var password: String?
    
    private override init() {
        
    }
    
    /**
     Authenticates user with server (needs to be done before other requests, otherwise .notAuthenticated error9
     - Parameters:
         - username: username of user
         - password: password of user
         - completion: Closure which is called after server response
            - success: Bool indicating operation success
            - error: Error, if operation unsuccessful
     */
    public func loginUser(username: String, password: String, cloudUserId: String? = nil, environment: SPManager.SPKeychainEnvironment = .local, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        self.username = username
        self.password = password
        self.request(API.authenticate, type: .get, parameters: nil) { (success, response, error) in
            if success {
                if let cloudUserId = cloudUserId {
                    if let accountCloudUserId = response!["cloudUserId"].string {
                        if accountCloudUserId != cloudUserId && environment == .cloud {
                            self.username = nil
                            self.password = nil
                            completion(false, APIError.differentCloudUserId)
                            return
                        }
                    }
                }
                SignalingClient.shared.setCredentials(username: username, password: password)
                completion(true, nil)
            }else{
                self.username = nil
                self.password = nil
                completion(false, error!)
            }
        }
    }
    
    /**
     Fetches all gateways associated with user
     - Parameters:
     - completion: Closure which is called after server response
        - success: Bool indicating operation success
        - gateways: all SPGateways associated with current user
        - error: Error, if operation unsuccessful
    */
    public func getAllGateways(completion: @escaping (_ success: Bool, _ gateways: [SPGateway]?, _ error: APIError?) -> Void) {
        self.request(API.gateways, type: .get, parameters: nil) { (success, json, error) in
            if success {
                if let error = error {
                    completion(false, nil, error)
                    return
                }
                
                if let error = json!["error"].string {
                    let cerror = APIError.other(desc: error)
                    completion(false, nil, cerror)
                    return
                }
                
                if let gateways = json!.array {
                    var returnGateways = [SPGateway]()
                    for gateway in gateways {
                        if let imei = gateway["imei"].string {
                            let name = gateway["name"].string
                            let phoneNumber = gateway["phoneNumber"].string
                            let colorString = gateway["color"].string
                            let signalStrength = gateway["signalStrength"].double
                            let firmwareVersion = gateway["firmwareVersion"].string
                            let carrier = gateway["carrier"].string
                            returnGateways.append(SPGateway(withIMEI: imei, name: name, phoneNumber: phoneNumber, colorString: colorString, signalStrength: signalStrength, firmwareVersion: firmwareVersion, carrier: carrier))
                        }else{
                            completion(false, nil, APIError.parsingError)
                            return
                        }
                    }
                    completion(true, returnGateways, nil)
                    return
                }
            }
        }
    }
    
    /**
     Fetches a gateway by its IMEI
     - Parameters:
     - imei: IMEI of the gateway
     - completion: Closure which is called after server response
     - success: Bool indicating operation success
     - gateways: all SPGateways associated with current user
     - error: Error, if operation unsuccessful
     */
    public func getGateway(imei: String, completion: @escaping (_ success: Bool, _ gateway: SPGateway?, _ error: APIError?) -> Void) {
        self.request(API.gateway(imei), type: .get, parameters: nil) { (success, response, error) in
            if success {
                if let gateway = response {
                    if let imei = gateway["imei"].string {
                        let name = gateway["name"].string
                        let phoneNumber = gateway["phoneNumber"].string
                        let colorString = gateway["color"].string
                        let signalStrength = gateway["signalStrength"].double
                        let firmwareVersion = gateway["firmwareVersion"].string
                        let carrier = gateway["carrier"].string
                        let gateway = SPGateway(withIMEI: imei, name: name, phoneNumber: phoneNumber, colorString: colorString, signalStrength: signalStrength, firmwareVersion: firmwareVersion, carrier: carrier)
                        completion(true, gateway, nil)
                    }else{
                        completion(false, nil, APIError.parsingError)
                    }
                }
            }else{
                completion(false, nil, error!)
            }
        }
    }
    
    /**
     Update name of gateway
     - Parameters:
     - completion: Closure which is called after server response
     - success: Bool indicating operation success
     - error: Error, if operation unsuccessful
     */
    public func updateGateway(name newName: String, of gateway: SPGateway, completion: @escaping (_ success: Bool,  _ error: APIError?) -> Void) {
        let data = ["name": newName]
        self.request(API.gateway(gateway.imei), type: .put, parameters: data) { (success, json, error) in
            if success {
                completion(true, nil)
            }else{
                completion(false, error!)
            }
        }
    }
    
    /**
     Update color of gateway
     - Parameters:
     - completion: Closure which is called after server response
     - success: Bool indicating operation success
     - error: Error, if operation unsuccessful
     */
    public func updateGateway(color newColor: UIColor, of gateway: SPGateway, completion: @escaping (_ success: Bool,  _ error: APIError?) -> Void) {
        let data = ["color": newColor.toHexString()]
        self.request(API.gateway(gateway.imei), type: .put, parameters: data) { (success, json, error) in
            if success {
                completion(true, nil)
            }else{
                completion(false, error!)
            }
        }
    }
    
    /**
     Creates account on server
     - Parameters:
        - account: SPAccount representing new account
        - completion: Closure which is called after server response
            - success: Bool indicating operation success
            - error: Error, if operation unsuccessful
     */
    public func registerAccount(_ account: SPAccount, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        let data = ["mail": account.username,
                    "password": account.password,
                    "firstName": account.givenName,
                    "lastName": account.familyName]
        
        self.request(API.user, type: .post, parameters: data, authRequired: false) { (success, response, error) in
            if success {
                completion(true, nil)
            }else{
                completion(false, error!)
            }
        }
    }
    
    /**
     Updates commited gateway on server (change in name or phoneNumber)
     - Parameters:
        - gateway: SPGateway to be updated
        - completion: Closure which is called after server response
            - success: Bool indicating operation success
            - error: Error, if operation unsuccessful
    */
    public func updateGateway(_ gateway: SPGateway, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        let data = ["name": gateway.name,
                    "phoneNumber": gateway.phoneNumber] as [String:Any]
        
        self.request(API.gateway(gateway.imei), type: .put, parameters: data) { (success, response, error) in
            if success {
                completion(true, nil)
                return
            }else{
                // TODO: Error handling
                print(error!)
            }
        }
    }
    
    public enum GatewayPushEvent {
        case dial(number: String)
        case hangUp
        case deviceDidAnswerCall(client: SPDevice)
        case deviceDidDeclineCall(client: SPDevice)
        case holdCall
        case continueCall
        case playDTMF(digits: String)
        case sendSMS(to: String, message: String)
        case updateSignalStrength
    }
    
    /**
     Push event to gateway
     - Parameters:
        - gateway: SPGateway that receives push notification
        - event: the push event
        - completion: Closure which is called after server response
            - success: Bool indicating operation success
            - error: Error, if operation unsuccessful
     */
    public func pushEventToGateway(_ gateway: SPGateway, event: GatewayPushEvent, completion: @escaping (_ success: Bool, _ response: JSON?, _ error: APIError?) -> Void) {
        var data: [String: Any] = ["gateway": gateway.imei]
        
        switch event {
        case .dial(let number):
            data["event"] = "dial"
            data["data"] = ["number": number]
        case .hangUp:
            data["event"] = "hangUp"
        case .updateSignalStrength:
            data["event"] = "requestSignal"
        case .sendSMS(let phoneNumber, let message):
            data["event"] = "sendSMS"
            data["data"] = ["recipient": phoneNumber,
                            "message": message]
        case .deviceDidAnswerCall(let client):
            data["event"] = "deviceDidAnswerCall"
            data["data"] = ["device": client.id]
        case .deviceDidDeclineCall(let client):
            data["event"] = "deviceDidDeclineCall"
            data["data"] = ["device": client.id]
        case .holdCall:
            data["event"] = "holdCall"
        case .continueCall:
            data["event"] = "continueCall"
        case .playDTMF(let digits):
            data["event"] = "playDTMF"
            data["data"] = ["digits": digits]
        }
        
        self.request(API.event, type: .post, parameters: data) { (success, response, error) in
            if let error = error {
                print(error)
                completion(false, nil, error)
                return
            }
            completion(success, response, nil)
            return
        }
    }
    
    
    public func getAllDevices(completion: @escaping (_ success: Bool, _ devices: [SPDevice]?, _ error: APIError?) -> Void) {
        self.request(API.devices, type: .get, parameters: nil) { (success, json, error) in
            if success {
                if let error = error {
                    completion(false, nil, error)
                    return
                }
                
                if let error = json!["error"].string {
                    let cerror = APIError.other(desc: error)
                    completion(false, nil, cerror)
                    return
                }
                
                if let devices = json!.array {
                    var returnDevices = [SPDevice]()
                    for device in devices {
                        if let id = device["id"].string,
                            let deviceName = device["deviceName"].string,
                            let systemVersion = device["systemVersion"].string,
                            let deviceModelName = device["deviceModelName"].string,
                            let language = device["language"].string,
                            let sync = device["sync"].bool {
                            
                            returnDevices.append(SPDevice(withid: id, name: deviceName, systemVersion: systemVersion, deviceModelName: deviceModelName, language: language, sync: sync))
                        }else{
                            completion(false, nil, APIError.parsingError)
                            return
                        }
                    }
                    completion(true, returnDevices, nil)
                    return
                }
            }else{
                completion(false, nil, error!)
            }
        }
    }
    
    /**
     Cross-checks local device info and registers/updates info on server (Error if revoked by server)
     - Parameters:
     - device: SPDevice object of current device
     - completion: Closure which is called after server response
     - success: Bool indicating operation success
     - error: Error, if operation unsuccessful
     */
    public func register(deviceWithServer device: SPDevice, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        // Check if local data exists, otherwise register in server
        if let localDevice = SPDevice.local {
            self.request(API.device(localDevice.id), type: .get, parameters: nil) { (success, response, error) in
                if success, let response = response {
                    
                    // Compare local with remote data
                    
                    
                    if let id = response["id"].string,
                        let name = response["deviceName"].string,
                        let systemVersion = response["systemVersion"].string,
                        let deviceModelName = response["deviceModelName"].string,
                        let language = response["language"].string,
                        let sync = response["language"].bool {
                        
                        let apnKey = response["apnToken"].string
                        
                        let remote = SPDevice(withid: id, name: name, systemVersion: systemVersion, deviceModelName: deviceModelName, language: language, sync: sync, apnKey: apnKey)
                        
                        if device != remote {
                            self.request(API.device(id), type: .put, parameters: device.toData(), completion: { (success, response, error) in
                                SPDevice.local = device
                                completion(success, error)
                            })
                        }
                        
                    }
                    
                    
                }else{
                    // Check whether device got revoked
                    if case APIError.noDeviceFound = error! {
                        SPDevice.local = nil
                    }
                    completion(false, error!)
                    return
                }
            }
            
        }else{
            // Device does not exist locally
            self.request(API.device, type: .post, parameters: device.toData()) { (success, response, error) in
                if success {
                    SPDevice.local = device
                    completion(true, nil)
                    return
                }else{
                    completion(false, error!)
                    return
                }
            }
            
        }
    }
    
    /**
     Cross-checks local device info and registers/updates VoIP APN Token of device
     - Parameters:
     - token: VoIP APN Token provided by PushKit
     - completion: Closure which is called after server response
     - success: Bool indicating operation success
     - error: Error, if operation unsuccessful
     */
    public func register(voipToken token: String, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        if let localDevice = SPDevice.local {
            let tokenDevice = localDevice
            tokenDevice.voipToken = token
            if localDevice != tokenDevice {
                SPDevice.local = tokenDevice
            }
            let data = ["voipToken": token]
            self.request(API.device(localDevice.id), type: .put, parameters: data) { (success, response, error) in
                completion(success, error)
            }
        }
    }
    
    public func setiCloudSyncState(_ newState: Bool, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        if let localDevice = SPDevice.local {
            localDevice.sync = newState
            self.request(API.device(localDevice.id), type: .put, parameters: localDevice.toData()) { (success, response, error) in
                if success {
                    SPDevice.local = localDevice
                }
                completion(success, error)
            }
            
        }
    }
    
    /**
     Revokes a device using its id
     - Parameters:
     - withId: the id of the device
     - completion: Closure which is called after server response
        - success: Bool indicating operation success
        - error: Error, if operation unsuccessful
     */
    public func revokeDevice(withId id: String, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        request(API.device(id), type: .delete, parameters: nil) { (success, response, error) in
            completion(success, error)
        }
    }
    
    /**
     Revokes all devices of an account that have iCloud Sync enabled
     - completion: Closure which is called after server response
        - success: Bool indicating operation success
        - error: Error, if operation unsuccessful
     */
    public func revokeAllDevicesWithiCloudSyncEnabled(completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        let data: [String: Bool] = ["sync": true]
        request(API.devices, type: .delete, parameters: data) { (success, response, error) in
            completion(success, error)
        }
    }
    
    /**
     Rekoves current device
     - Parameters:
     - completion: Closure which is called after server response
        - success: Bool indicating operation success
        - error: Error, if operation unsuccessful
     */
    public func revokeThisDevice(completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        if let localDevice = SPDevice.local {
            self.revokeDevice(withId: localDevice.id) { (success, error) in
                completion(success, error)
            }
        }else{
            fatalError("error while revoking device")
        }
    }

    // MARK: - API routing
    private struct API {
        static let base = "https://api.da.digitalsubmarine.com/v1"
        static let authenticate = "/authenticate"
        static let user = "/user"
        static let device = "/device"
        static let devices = "/devices"
        static func device(_ id: String) -> String { return "/device/\(id)" }
        static let gateway = "/gateway"
        static let gateways = "/gateways"
        static func gateway(_ id: String) -> String { return "/gateway/\(id)" }
        static let event = "/gateway/push"
        
        public struct Headers {
            static let Default = [
                "Content-Type": "application/json",
                ]
            
            static func Authorization(_ username: String, _ password: String) -> [String:String] {
                var header = Default
                let plainString = username+":"+password as NSString
                let plainData = plainString.data(using: String.Encoding.utf8.rawValue)!
                let base64String = plainData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
                header["Authorization"] = "Basic " + base64String
                return header
            }
        }
    }
    
}

extension APIClient {
    private func request(_ endpoint: String, type: HTTPMethod, parameters: [String:Any]?, authRequired: Bool = true, completion: @escaping (_ success: Bool, _ result: JSON?, _ error: APIError?) -> Void) {
        print("\(type) \(endpoint): \(parameters?.debugDescription)")
        
        // Check whether internet connection is available
        if !self.isConnectedToNetwork() {
            completion(false, nil, APIError.noNetworkConnection)
            return
        }
        
        if authRequired && (self.username == nil || self.username == nil) {
            completion(false, nil, APIError.notAuthenticated)
            return
        }
        
        self.visualizeOngoingQueries()
        let queue = DispatchQueue(label: "com.lukaskuster.diplomarbeit.SIMplePhone.apirequest", qos: .userInitiated, attributes: .concurrent)
        Alamofire.request(API.base+endpoint, method: type, parameters: parameters, encoding: JSONEncoding.default, headers: (authRequired ? API.Headers.Authorization(self.username!, self.password!) : API.Headers.Default))
            .validate(contentType: ["application/json"])
            .responseSwiftyJSON(queue: queue, completionHandler: { (response) in
                self.visualizeOngoingQueries(removeQuery: true)
                
                if let error = response.error {
                    completion(false, nil, APIError.other(desc: "\(error)"))
                    return
                }
                
                if let error = response.value!["errorCode"].int {
                    let apiError = self.getError(withCode: error, response: response.value!)
                    completion(false, nil, apiError)
                    return
                }
                
                if let response = response.value {
                    completion(true, response, nil)
                    return
                }
            })
    }
    
    private func getError(withCode code: Int, response: JSON) -> APIError {
        switch code {
        case 10000:
            let parameter = String(response["errorMessage"].string!.split(separator: "(")[1].dropLast())
            return APIError.missing(parameter: parameter)
        case 10001:
            return APIError.gatewayAlreadyExists
        case 10002:
            return APIError.noGatewayFound
        case 10003:
            let parameter = String(response["errorMessage"].string!.components(separatedBy: "(withName: ")[1].dropLast())
            return APIError.databaseError(desc: parameter)
        case 10004:
            return APIError.deviceAlreadyExists
        case 10005:
            return APIError.noDeviceFound
        case 10006:
            return APIError.mailAlreadyExists
        case 10008:
            return APIError.noGatewaysForUser
        case 10009:
            return APIError.noDevicesForUser
        case 10010:
            return APIError.notAuthenticated
        case 10011:
            return APIError.wrongCredentials
        default:
            return APIError.other(desc: response["errorMessage"].string!)
        }
    }
    
    private func visualizeOngoingQueries(removeQuery: Bool = false) {
        if removeQuery {
            numberOfOngoingQueries -= 1
            if numberOfOngoingQueries < 1 {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }else{
            if numberOfOngoingQueries < 1 {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
            }
            numberOfOngoingQueries += 1
        }
    }
    
    private func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return (isReachable && !needsConnection)
    }
    
    private func compareDeviceData(_ a: [String: Any], _ b: [String: Any]) -> Bool {
        for (i, key) in a.enumerated() {
            if (key.value as! NSObject) != (Array(b)[i].value as! NSObject) {
                return false
            }
        }
        return true
    }
}
