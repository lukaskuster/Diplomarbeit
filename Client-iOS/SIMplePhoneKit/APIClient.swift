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

enum APIError: Error {
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
    case other(desc: String)
}

class APIClient: NSObject {
    public static let shared = APIClient()
    private var numberOfOngoingQueries: Int = 0
    
    private override init() {
        
    }
    
    /**
     Fetches all gateways associated with user
     - Returns: Completion handler (success, gateways?, error?)
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
                        if let imei = gateway["imei"].string,
                            let name = gateway["name"].string,
                            let phoneNumber = gateway["phoneNumber"].string,
                            let signalStrength = gateway["signalStrength"].double {
                            returnGateways.append(SPGateway(withIMEI: imei, name: name, phoneNumber: phoneNumber, signalStrength: signalStrength))
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
                print(error!)
            }
        }
    }
    
    public enum GatewayPushEvent {
        case dial(number: String)
        case sendSMS(to: String, message: String)
        case updateSignalStrength
    }
    
    /**
     Push event to gateway
     - Parameters:
        - gateway: SPGateway that receives push notification
        - event: the push event
        - completion: Closure which is called after server response
     */
    public func pushEventToGateway(_ gateway: SPGateway, event: GatewayPushEvent, completion: @escaping (_ success: Bool, _ response: JSON?, _ error: APIError?) -> Void) {
        var data: [String: Any] = ["gateway": gateway.imei]
        
        switch event {
        case .dial(let number):
            data["event"] = "dial"
            data["data"] = ["number": number]
        case .updateSignalStrength:
            data["event"] = "requestSignal"
        case .sendSMS(let phoneNumber, let message):
            data["event"] = "sendSMS"
            data["data"] = ["recipient": phoneNumber,
                            "message": message]
        }
        
        self.request(API.event, type: .post, parameters: data) { (success, response, error) in
            if let error = error {
                completion(false, nil, APIError.other(desc: error.localizedDescription))
                return
            }
            completion(success, response, nil)
            return
        }
    }
    
    
    /**
     Cross-checks local device info and registers/updates info on server (Error if revoked by server)
     - Parameters:
        - apnToken: APN token of the current device
        - deviceName: device name of the current device, as specified in settings (e.g. "Joe's iPhone")
        - modelName: the model name of the current device (e.g. "iPad7,5")
        - systemVersion: the iOS version running on the current device (e.g. "12.1")
        - language: the system language of the current device
     */
    public func registerDeviceWithServer(apnToken: String, deviceName: String, modelName: String, systemVersion: String, language: String?, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        // Check if local data exists, otherwise register on server
        if let localDeviceInfo = UserDefaults.standard.dictionary(forKey: "localDeviceInfo") as! [String:String]? {
            self.request(API.device(localDeviceInfo["id"]!), type: .get, parameters: nil) { success, response, error in
                if success {
                    var dataToCompare = ["id": localDeviceInfo["id"]!,
                                "apnToken": apnToken,
                                "deviceModelName": modelName,
                                "deviceName": deviceName,
                                "systemVersion": systemVersion]
                    if let language = language {
                        dataToCompare["language"] = language
                    }
                    
                    // Check if change in local data (e.g. ios version update, language changed...)
                    if dataToCompare != localDeviceInfo {
                        self.request(API.device(localDeviceInfo["id"]!), type: .put, parameters: dataToCompare) { success, device, error in
                            if success {
                                UserDefaults.standard.set(dataToCompare, forKey: "localDeviceInfo")
                                completion(true, nil)
                                return
                            }else{
                                completion(false, error!)
                                return
                            }
                        }
                    }
                }else{
                    // Check whether device got revoked
                    if case APIError.noDeviceFound = error! {
                        UserDefaults.standard.removeObject(forKey: "localDeviceInfo")
                    }
                    
                    completion(false, error!)
                    return
                }
            }
        }else{
            var data = ["id": UUID().uuidString,
                        "apnToken": apnToken,
                        "deviceModelName": modelName,
                        "deviceName": deviceName,
                        "systemVersion": systemVersion]
            if let language = language {
                data["language"] = language
            }
            
            self.request(API.device, type: .post, parameters: data) { success, response, error in
                if success {
                    UserDefaults.standard.set(data, forKey: "localDeviceInfo")
                    completion(true, nil)
                    return
                }else{
                    completion(false, error!)
                    return
                }
            }
        }
    }


}

extension APIClient {
    private func request(_ endpoint: String, type: HTTPMethod, parameters: [String:Any]?, completion: @escaping (_ success: Bool, _ result: JSON?, _ error: APIError?) -> Void) {
        // Check whether internet connection is available
        if !self.isConnectedToNetwork() {
            completion(false, nil, APIError.noNetworkConnection)
            return
        }
        
        self.visualizeOngoingQueries()
        let queue = DispatchQueue(label: "com.lukaskuster.diplomarbeit.SIMplePhone.apirequest", qos: .userInitiated, attributes: .concurrent)
        Alamofire.request(API.base+endpoint, method: type, parameters: parameters, encoding: JSONEncoding.default, headers: self.getAuthHeader())
            .validate(contentType: ["application/json"])
            .responseSwiftyJSON(queue: queue, completionHandler: { (response) in
                self.visualizeOngoingQueries(removeQuery: true)
                
                if let error = response.value!["errorCode"].int {
                    let apiError = self.getError(withCode: error, response: response.value!)
                    completion(false, nil, apiError)
                    return
                }
                
                if let error = response.error {
                    completion(false, nil, APIError.other(desc: error.localizedDescription))
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
    
    private func getAuthHeader() -> [String:String] {
        let plainString = "quentin@wendegass.com:test123" as NSString
        let plainData = plainString.data(using: String.Encoding.utf8.rawValue)!
        let base64String = plainData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        
        var header = [String:String]()
        header["Authorization"] = "Basic " + base64String
        return header
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
}

public struct API {
    static let base = "https://api.da.digitalsubmarine.com/v1"
    static let user = "/user"
    static let device = "/device"
    static let devices = "/devices"
    static func device(_ id: String) -> String { return "/device/\(id)" }
    static let gateway = "/gateway"
    static let gateways = "/gateways"
    static func gateway(_ id: String) -> String { return "/gateway/\(id)" }
    static let event = "/event"
    
    public struct Headers {
        static let Default = [
            "Content-Type": "application/json",
        ]
        
        static func Authorization() -> [String:String] {
            var Authorization = Default
            Authorization["Authorization"] = "Basic \(1+1)"
            return Authorization
        }
    }
}
