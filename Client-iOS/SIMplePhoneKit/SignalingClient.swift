//
//  SignalingClient.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 23.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON

public enum SignalingClientError: Error {
    case jsonDecodingFailed
    case unableToSignIn(reason: String)
}

public class SignalingClient: NSObject {    
    private var username: String?
    private var password: String?
    private let socket: WebSocket
    
    private var candidateCache = SynchronizedArray<String>()
    
    private let serverUrl = URL(string: "wss://signaling.da.digitalsubmarine.com:443")!

    private enum SignalingType: String {
        case offer = "offer"
        case answer = "answer"
        case addCandidate = "sendIce"
    }
    
    
    public override init() {
        socket = WebSocket(url: self.serverUrl)
        super.init()
    }
    
    public func setCredentials(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    public func close() {
        self.socket.disconnect()
    }
    
    public func post(offer: String, completion: @escaping (_ success: Bool, _ answer: String?, _ error: Error?) -> Void) {
        self.socket.onConnect = {
            self.authenticate(type: .offer, completion: { error in
                if let error = error {
                    completion(false, nil, error)
                }
            })
        }
        
        self.socket.onText = { (response: String) in
            if let data = response.data(using: .utf8) {
                if let json = try? JSON(data: data) {
                    if let event = json["event"].string {
                        print(json.debugDescription)
                        // TO-DO: Monitor socket responses and tidy up here
                        switch event {
                        case "authenticate":
                            if let authenticated = json["authenticated"].bool {
                                if !authenticated {
                                    self.socket.disconnect()
                                    completion(false, nil, SignalingClientError.unableToSignIn(reason: json["error"].string!))
                                }
                            }
                            break
                            
                        case "start":
                            self.write(type: .offer, payload: offer, completion: { error in
                                if let error = error {
                                    completion(false, nil, error)
                                }
                            })
                            break
                            
                            
                        case "answer":
                            if let sdp = json["sdp"].string {
                                print("candidates : \(self.candidateCache.count)")
                                while self.candidateCache.count > 0 {
                                    let index = self.candidateCache.count-1
                                    self.write(type: .addCandidate, payload: self.candidateCache[index], completion: { error in
                                        self.candidateCache.removeAtIndex(index: index)
                                        if let error = error {
                                            completion(false, nil, error)
                                        }
                                    })
                                }
                                completion(true, sdp, nil)
                            }
                            break
                            
                        default:
                            break
                        }
                    }
                    
                }
            }
        }
        
        if !self.socket.isConnected {
            socket.connect()
        }
    }
    
//    private func sendCandidates() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            for candidate in self.candidateCache {
//                self.write(type: .addCandidate, payload: candidate) { (error) in
//                    if let error = error {
//                        print("error")
//                    }
//                }
//            }
//        }
//    }
    
    public func postCandidate(candidate: String, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        print("postCandidate \(candidate)")
        if !self.socket.isConnected {
            print("append")
            let sdp = candidate.replacingOccurrences(of: "candidate:", with: "")
            self.candidateCache.append(newElement: sdp)
        }
        completion(true, nil)
    }
    
    public func getOffer(completion: @escaping (_ success: Bool, _ offer: String?, _ error: Error?) -> Void) {
        let socket = WebSocket(url: self.serverUrl)
        
        socket.onConnect = {
            self.authenticate(type: .answer, completion: { error in
                if let error = error {
                    completion(false, nil, error)
                }
            })
        }
        
        socket.onText = { (response: String) in
            if let data = response.data(using: .utf8) {
                if let json = try? JSON(data: data) {
                    if let event = json["event"].string {
                        print(json.debugDescription)
                        // TO-DO: Monitor socket responses and tidy up here
                        switch event {
                        case "authenticate":
                            if let authenticated = json["authenticated"].bool {
                                if authenticated {
                                    
                                }else{
                                    self.socket.disconnect()
                                    completion(false, nil, SignalingClientError.unableToSignIn(reason: json["error"].string!))
                                }
                            }
                            break
                            
                        case "offer":
                            if let sdp = json["sdp"].string {
                                completion(true, sdp, nil)
                            }
                            break
                            
                        default:
                            break
                        }
                    }
                    
                }
            }
        }
        
        if !self.socket.isConnected {
            socket.connect()
        }
    }
    
    public func post(answer: String, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        self.write(type: .answer, payload: answer) { error in
            if let error = error {
                completion(false, error)
            }
        }
        
        socket.onText = { (response: String) in
            if let data = response.data(using: .utf8) {
                if let json = try? JSON(data: data) {
                    if let event = json["event"].string {
                        print(json.debugDescription)
                        // TO-DO: Monitor socket responses and tidy up here
                        switch event {
                        case "authenticate":
                            if let authenticated = json["authenticated"].bool {
                                if authenticated {
                                    
                                    // Send offer
                                    
                                }else{
                                    self.socket.disconnect()
                                    completion(false, SignalingClientError.unableToSignIn(reason: json["error"].string!))
                                }
                            }
                            break
                            
                        default:
                            break
                        }
                    }
                    
                }
            }
        }
        
        if !self.socket.isConnected {
            socket.connect()
        }
    }

    private func authenticate(type: SignalingType, completion: @escaping (_ error: Error?) -> Void) {
        let request: [String: String] = [
            "event": "authenticate",
            "username": self.username!,
            "password": self.password!,
            "role": "\(type.rawValue)"
        ]
        
        do {
            let data = try JSON(request).rawData()
            self.socket.write(data: data)
            completion(nil)
        }catch{
            completion(SignalingClientError.jsonDecodingFailed)
        }
    }
    
    private func write(type: SignalingType, payload: String, completion: @escaping (_ error: Error?) -> Void) {
        let request: [String: String] = [
            "event": "\(type.rawValue)",
            "\(type == .addCandidate ? "ice" : "sdp")": payload
        ]
        
        do {
            let data = try JSON(request).rawData()
            print("Signaling write \(type) \(request)")
            self.socket.write(data: data)
            completion(nil)
        }catch{
            completion(SignalingClientError.jsonDecodingFailed)
        }
    }
}

public class SynchronizedArray<T> {
    private var array: [T] = []
    private let accessQueue = DispatchQueue(label: "SynchronizedArrayAccess", attributes: .concurrent)
    
    public func append(newElement: T) {
        
        self.accessQueue.async(flags:.barrier) {
            self.array.append(newElement)
        }
    }
    
    public func removeAtIndex(index: Int) {
        
        self.accessQueue.async(flags:.barrier) {
            self.array.remove(at: index)
        }
    }
    
    public var count: Int {
        var count = 0
        
        self.accessQueue.sync {
            count = self.array.count
        }
        
        return count
    }
    
    public func first() -> T? {
        var element: T?
        
        self.accessQueue.sync {
            if !self.array.isEmpty {
                element = self.array[0]
            }
        }
        
        return element
    }
    
    public subscript(index: Int) -> T {
        set {
            self.accessQueue.async(flags:.barrier) {
                self.array[index] = newValue
            }
        }
        get {
            var element: T!
            self.accessQueue.sync {
                element = self.array[index]
            }
            
            return element
        }
    }
}
