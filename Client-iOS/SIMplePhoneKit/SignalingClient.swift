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
    private let username: String
    private let password: String
    private let imei: String
    private let socket: WebSocket
    
    private let serverUrl = URL(string: "wss://signaling.da.digitalsubmarine.com:443")!
    
    private var currentType: SignalingType?
    
    private var readyToSendCandidates: Bool = false
    private var candidates = [String]()
    
    public enum SignalingType: String {
        case offer = "offer"
        case answer = "answer"
        case addCandidate = "sendIce"
    }
    
    public init(username: String, password: String, imei: String) {
        socket = WebSocket(url: self.serverUrl)
        self.username = username
        self.password = password
        self.imei = imei
        super.init()
    }
    
    public func close() {
        self.socket.disconnect()
    }
    
    private func parseResponse(_ response: String) -> (event: String?, data: JSON?) {
        if let data = response.data(using: .utf8) {
            if let json = try? JSON(data: data) {
                if let event = json["event"].string {
                    return (event: event, data: json)
                }
            }
        }
        return (event: nil, data: nil)
    }
    
    public func authenticate(type: SignalingType, completion: @escaping (Error?) -> Void) {
        let request: [String: String] = [
            "event": "authenticate",
            "username": self.username,
            "password": self.password,
            "gateway": self.imei,
            "role": "\(type.rawValue)"
        ]
        
        do {
            let data = try JSON(request).rawData()
            self.socket.onConnect = {
                self.socket.write(data: data)
            }
            
            self.socket.onText = { (response: String) in
                let response = self.parseResponse(response)
                if response.event == "authenticate" {
                    if let autheticated = response.data?["authenticated"].bool {
                        if autheticated {
                            print("Authetificated!!!!")
                            completion(nil)
                        }else{
                            self.socket.disconnect()
                            completion(SignalingClientError.unableToSignIn(reason: (response.data?["error"].string)!))
                        }
                    }
                }
            }
            
            self.socket.connect()
        }catch{
            completion(SignalingClientError.jsonDecodingFailed)
        }
    }
    
    public func post(offer: String, completion: @escaping (String?, Error?) -> Void) {
        self.authenticate(type: .offer) { error in
            if let error = error {
                completion(nil, error)
            }

            self.socket.onText = { (response: String) in
                let response = self.parseResponse(response)
                if let event = response.event,
                   let data = response.data {
                    switch event {
                    case "start":
                        let offerWithCandidates = self.addCandidates(to: offer)
                        self.write(type: .offer, payload: offerWithCandidates, completion: { error in
                            if let error = error {
                                completion(nil, error)
                            }
                        })
                        break
                    case "answer":
                        if let answerSdp = data["sdp"].string {
                            self.sendCandidatesQueue()
                            completion(answerSdp, nil)
                        }
                    default:
                        break
                    }
                }
            }
            
        }
    }
    
    public func post(answer: String, completion: @escaping (Error?) -> Void) {
        self.authenticate(type: .offer) { error in
            if let error = error {
                completion(error)
            }
            
            self.write(type: .answer, payload: answer, completion: { error in
                if let error = error {
                    completion(error)
                }
                self.sendCandidatesQueue()
                completion(nil)
            })
        }
    }
    
    public func post(candidate: String, completion: @escaping (Error?) -> Void) {
        let sdp = candidate.replacingOccurrences(of: "candidate:", with: "")
        if self.readyToSendCandidates {
            self.write(type: .addCandidate, payload: sdp) { error in
                completion(error)
            }
        }else{
            // Add candidate to queue
            self.candidates.append(sdp)
        }
    }
    
    private func sendCandidatesQueue() {
        self.readyToSendCandidates = true
        for candidate in self.candidates {
            self.write(type: .addCandidate, payload: candidate) { error in
                if let error = error {
                    print("Log \(error)")
                    return
                }
            }
        }
    }
    
    private func addCandidates(to sdp: String) -> String {
        var offer = sdp
        for candidate in self.candidates {
            offer += "\r\na=candidate:\(candidate)"
        }
        self.candidates.removeAll()
        return offer
    }
    
    public func receiveOffer(completion: @escaping (String?, Error?) -> Void) {
        self.authenticate(type: .answer) { error in
            if let error = error {
                completion(nil, error)
            }
            
            self.socket.onText = { (response: String) in
                let response = self.parseResponse(response)
                if let event = response.event,
                    let data = response.data {
                    if event == "offer",
                       let offerSdp = data["sdp"].string {
                            completion(offerSdp, nil)
                       }
                }
                completion(nil, SignalingClientError.jsonDecodingFailed)
            }
        }
    }
    
    private func write(type: SignalingType, payload: String, completion: @escaping (_ error: Error?) -> Void) {
        let request: [String: String] = [
            "event": "\(type.rawValue)",
            (type == .addCandidate ? "ice" : "sdp"): payload
        ]
        
        do {
            let data = try JSON(request).rawData()
            print("Signaling write \(type) \(request)")
            self.socket.write(data: data) {
                print("send")
                completion(nil)
            }
        }catch{
            completion(SignalingClientError.jsonDecodingFailed)
        }
    }
}
