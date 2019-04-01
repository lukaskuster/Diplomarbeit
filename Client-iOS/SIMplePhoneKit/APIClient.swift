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

/// Enum indicating an error returned by the APIClient
public enum APIError: LocalizedError {
    /// Endpoint requested without being authentificated
    case notAuthenticated
    /// Invalid credentials used to authentificate request
    case wrongCredentials
    /// A parameter in the request is missing
    /// - Parameter parameter: Textual representation of the missing parameter
    case missing(parameter: String)
    /// A gateway with the same IMEI already exists for that account
    case gatewayAlreadyExists
    /// The gateway with the supplied IMEI does not exist
    case noGatewayFound
    /// An internal database error occurred
    /// - Parameter desc: Textual description of the error
    case databaseError(desc: String)
    /// The supplied mail address has already been used for an account
    case deviceAlreadyExists
    /// The supplied mail address has already been used for an account
    case mailAlreadyExists
    /// No SPDevice with the supplied identifier was found
    case noDeviceFound
    /// The supplied SPGateway is not connected to the service right now
    /// - Parameter withIMEI: IMEI of the respective SPGateway
    case gatewayNotConnected(withIMEI: String)
    /// The user does not have any SPGateways connected to his/her account
    case noGatewaysForUser
    /// The user does not have any SPDevices conntected to his/her account
    case noDevicesForUser
    /// An error occurred while parsing the response
    case parsingError
    /// The device does not have a network connection and therefore can not reach the API
    case noNetworkConnection
    /// The iCloud User Identifier for this account differs from the one of this devices Apple ID
    case differentCloudUserId
    /// Another error occurred
    /// - Parameter desc: Textual description of the error
    case other(desc: String)
    
    /// Overriding errorDescription to get a better error output
    public var errorDescription: String? {
        return "The operation couldn't be completed. (SIMplePhoneKit.APIError.\(self))"
    }
}

/// Class used to access the API associated with this app
public class APIClient: NSObject {
    /// Shared instance of the APIClient
    public static let shared = APIClient()
    private var numberOfOngoingQueries: Int = 0
    private var username: String?
    private var password: String?
    
    /// Authenticates user with server (needs to be done before other requests, otherwise an APIError.notAuthenticated occurs)
    ///
    /// - Parameters:
    ///   - username: Username of user
    ///   - password: Password of user
    ///   - cloudUserId: Associated Cloud User Id
    ///   - environment: Environment to use
    ///   - completion: Completion block that gets called on response
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
                PeerConnectionManager.shared.setSignalingCredentials(username: username, password: password)
                completion(true, nil)
            }else{
                self.username = nil
                self.password = nil
                completion(false, error!)
            }
        }
    }
    
    /// Fetches all gateways associated with user
    ///
    /// - Parameter completion: Completion block that gets called on response (either an error or an array of SPGateways
    public func getAllGateways(completion: @escaping (_ gateways: [SPGateway]?, _ error: APIError?) -> Void) {
        self.request(API.gateways, type: .get, parameters: nil) { (success, json, error) in
            if success {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                if let error = json!["error"].string {
                    let cerror = APIError.other(desc: error)
                    completion(nil, cerror)
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
                            completion(nil, APIError.parsingError)
                            return
                        }
                    }
                    completion(returnGateways, nil)
                    return
                }
            }
        }
    }
    
    /// Fetches a gateway by its IMEI
    ///
    /// - Parameters:
    ///   - imei: IMEI of the gateway
    ///   - completion: Completion block that gets called on response
    public func getGateway(imei: String, completion: @escaping (_ gateway: SPGateway?, _ error: APIError?) -> Void) {
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
                        completion(gateway, nil)
                    }else{
                        completion(nil, APIError.parsingError)
                    }
                }
            }else{
                completion(nil, error!)
            }
        }
    }
    
    /// Update name of gateway
    ///
    /// - Parameters:
    ///   - newName: New name of the gateway
    ///   - gateway: The gateway to update
    ///   - completion: Completion block that gets called on response
    public func updateGateway(name newName: String, of gateway: SPGateway, completion: @escaping (APIError?) -> Void) {
        let data = ["name": newName]
        self.request(API.gateway(gateway.imei), type: .put, parameters: data) { (success, json, error) in
            if success {
                completion(nil)
            }else{
                completion(error!)
            }
        }
    }
    
    /// Update color of gateway
    ///
    /// - Parameters:
    ///   - newColor: New color of the gateway
    ///   - gateway: The gateway to update
    ///   - completion: Completion block that gets called on response
    public func updateGateway(color newColor: UIColor, of gateway: SPGateway, completion: @escaping (APIError?) -> Void) {
        let data = ["color": newColor.toHexString()]
        self.request(API.gateway(gateway.imei), type: .put, parameters: data) { (success, json, error) in
            if success {
                completion(nil)
            }else{
                completion(error!)
            }
        }
    }
    
    /// Creates a new account for the service
    ///
    /// - Parameters:
    ///   - account: SPAccount representing new account
    ///   - completion: Completion block that gets called on response
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
    
    /// Type of push notification (SSE) to the gateway
    public enum GatewayPushEvent {
        /// Dial the provided phone number
        /// - Parameter number: String of the number to be called
        case dial(number: String)
        /// Hang up the currently connected call
        case hangUp
        /// Inform the gateway about the answer action
        /// - Parameter client: SPDevice object of the local device
        case deviceDidAnswerCall(client: SPDevice)
        /// Inform the gateway about the decline action
        /// - Parameter client: SPDevice object of the local device
        case deviceDidDeclineCall(client: SPDevice)
        /// Hold the currently connected call
        case holdCall
        /// Resume the currently connected call
        case resumeCall
        /// Send a certain DTMF number
        /// - Parameter digits: The respective DTMF "keys" to transmit
        case playDTMF(digits: String)
        /// Send out a SMS Message
        /// - Parameters:
        ///   - to: Number of the recipient
        ///   - message: Message to send
        case sendSMS(to: String, message: String)
        /// Request an update of the gateways signal strength
        case updateSignalStrength
    }
    
    /// Push event to gateway (SSE)
    ///
    /// - Parameters:
    ///   - gateway: SPGateway that should receive the notification
    ///   - event: The type of the notification
    ///   - completion: Completion block that gets called on response
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
        case .resumeCall:
            data["event"] = "resumeCall"
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
    
    /// Sends a SMS message to the provided receiver
    ///
    /// - Parameters:
    ///   - message: The message
    ///   - receiver: SPNumber that should receive the message
    ///   - gateway: SPGateway that should send out the message
    ///   - completion: Completion block that gets called on response
    public func sendSMS(message: String, to receiver: SPNumber, on gateway: SPGateway, completion: @escaping (Error?) -> Void) {
        self.pushEventToGateway(gateway, event: .sendSMS(to: receiver.phoneNumber, message: message)) { (success, json, error) in
            if let error = error {
                completion(error)
                return
            }
            if let error = json!["error"].string {
                let cerror = APIError.other(desc: error)
                completion(cerror)
                return
            }
            // TO-DO: If send
            completion(nil)
        }
    }
    
    
    /// Gives back all the SPDevices connected to an user
    ///
    /// - Parameter completion: Completion block that gets called on response (either an error or an array of SPDevices)
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
    
    /// Cross-checks local device info and registers/updates info on server (gives back an error if the device got revoked by server)
    ///
    /// - Parameters:
    ///   - device: SPDevice object of the current device
    ///   - completion: Closure that gets called after server response
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
    
    /// Cross-checks local device info and registers/updates VoIP APN Token of device
    ///
    /// - Parameters:
    ///   - token: VoIP APN Token provided by PushKit
    ///   - completion: Closure that gets called after server response
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
    
    /// Sets the iCloud Sync State of the current device (either sync or keep data local)
    ///
    /// - Parameters:
    ///   - newState: New state. Either synced by iCloud (true) or not (false).
    ///   - completion: Closure that gets called after server response
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
    
    /// Revokes a device using its Identifier
    ///
    /// - Parameters:
    ///   - id: Identifier of the device
    ///   - completion: Closure that gets called after server response
    public func revokeDevice(withId id: String, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        request(API.device(id), type: .delete, parameters: nil) { (success, response, error) in
            completion(success, error)
        }
    }
    
    /// Revokes all devices with iCloud Sync enabled of the provided account
    ///
    /// - Parameter completion: Closure that gets called after server response
    public func revokeAllDevicesWithiCloudSyncEnabled(completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        let data: [String: Bool] = ["sync": true]
        request(API.devices, type: .delete, parameters: data) { (success, response, error) in
            completion(success, error)
        }
    }
    
    /// Rekoves the device that makes the request
    ///
    /// - Parameter completion: Closure that gets called after server response
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
        case 10007:
            let parameter = String(response["errorMessage"].string!.components(separatedBy: "(withIMEI: ")[1].dropLast())
            return APIError.gatewayNotConnected(withIMEI: parameter)
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
