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

enum APIError: Error {
    case deviceGotRevokedFromAccount
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
    public func getAllGateways(completion: @escaping (_ success: Bool, _ gateways: [SPGateway]?, _ error: Error?) -> Void) {
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
                        // TODO: Remove optionals after quentin adjusts API
                        let imei = gateway["imei"].string ?? "no imei found"
                        let name = gateway["name"].string ?? "no name found"
                        let phoneNumber = gateway["phoneNumber"].string ?? "00436641817908"
                        let signalStrength = gateway["signalStrength"].double ?? 0.0
                        returnGateways.append(SPGateway(withIMEI: imei, name: name, phoneNumber: phoneNumber, signalStrength: signalStrength))
                    }
                    completion(true, returnGateways, nil)
                }
            }
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
        // TODO: make this function prettier
        if let localDeviceInfo = UserDefaults.standard.dictionary(forKey: "localDeviceInfo") as! [String:String]? {
            self.request(API.device(localDeviceInfo["id"]!), type: .get, parameters: nil) { success, response, error in
                if success {
                    if let error = response?["error"].string {
                        // TODO: Device not found, e.g. revoked (logout user / show alert)
                        UserDefaults.standard.removeObject(forKey: "localDeviceInfo")
                        completion(false, APIError.other(desc: error))
                        return
                    }
                    print(response!)
                }else{
                    completion(false, APIError.other(desc: error!.localizedDescription))
                }
            }
            
            var data = ["id": localDeviceInfo["id"]!,
                        "apnToken": apnToken,
                        "deviceModelName": modelName,
                        "deviceName": deviceName,
                        "systemVersion": systemVersion]
            if let language = language {
                data["language"] = language
            }
            
            if localDeviceInfo == data {
                // Nothing to do
            }else{
                // Update
                self.request(API.device(localDeviceInfo["id"]!), type: .put, parameters: data) { success, device, error in
                    if success {
                        UserDefaults.standard.set(data, forKey: "localDeviceInfo")
                        completion(true, nil)
                    }else{
                        completion(false, APIError.other(desc: error!.localizedDescription))
                    }
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
                }else{
                    completion(false, APIError.other(desc: error!.localizedDescription))
                }
            }
        }
    }


}

extension APIClient {
    private func request(_ endpoint: String, type: HTTPMethod, parameters: [String:String]?, completion: @escaping (_ success: Bool, _ result: JSON?, _ error: Error?) -> Void) {
        self.visualizeOngoingQueries()
        let queue = DispatchQueue(label: "com.lukaskuster.diplomarbeit.SIMplePhone.apirequest", qos: .userInitiated, attributes: .concurrent)
        Alamofire.request(API.base+endpoint, method: type, parameters: parameters, encoding: JSONEncoding.default, headers: self.getAuthHeader())
            .validate(contentType: ["application/json"])
            .responseSwiftyJSON(queue: queue, completionHandler: { (response) in
                if let error = response.error {
                    completion(false, nil, error)
                }
                
                if let response = response.value {
                    completion(true, response, nil)
                }
                self.visualizeOngoingQueries(removeQuery: true)
            })
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
