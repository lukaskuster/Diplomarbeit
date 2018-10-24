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
    case socketNotInitialized
}

public enum SignalingClientAuthentificationType {
    case offer
    case answer
}

public protocol SignalingClientDelegate: class {
    func signalingClient(client: SignalingClient, didAuthenticateOnServer authenticated: Bool, error: SignalingClientError?)
    func signalingClient(client: SignalingClient, didReceiveOfferWithSdp sdp: String)
}

public class SignalingClient: NSObject {
    var shared: SignalingClient?
    
    var socket: WebSocket?
    
    var username: String?
    var password: String?
    var type: SignalingClientAuthentificationType?
    
    public var delegate: SignalingClientDelegate?
    
    let serverUrl = URL(string: "wss://signaling.da.digitalsubmarine.com:443")!
    
    public init(username: String, password: String, type: SignalingClientAuthentificationType) {
        self.socket = WebSocket(url: serverUrl)
        self.username = username
        self.password = password
        self.type = type
    }
    
    public func connect() {
        self.socket?.delegate = self
        self.socket?.connect()
    }
    
    public func respondToOffer(withLocalSdp sdp: String) {
        let request: [String: String] = [
            "event": "answer",
            "sdp": sdp
        ]
        
        do {
            let data = try JSON(request).rawData()
            if let socket = self.socket {
                socket.write(data: data)
            }else{
                self.handleError(.socketNotInitialized)
            }
        }catch{
            self.handleError(.jsonDecodingFailed)
        }
    }
    
    func didConnect(withSocket socket: WebSocketClient) {
        self.authenticate(socket: socket, type: self.type!)
    }
    
    func didDisconnect(fromSocket socket: WebSocketClient, error: Error?) {
        
    }
    
    func didReceiveMessage(fromSocket socket: WebSocketClient, message msg: String) {
        if let data = msg.data(using: .utf8) {
            if let json = try? JSON(data: data) {
                self.handleSocketResponse(json)
            }
        }
    }
    
    func handleSocketResponse(_ json: JSON) {
        if let event = json["event"].string {
            
            print(json.rawString())
            
            if event == "authenticate" {
                if let authenticated = json["authenticated"].bool {
                    if authenticated {
                        self.delegate?.signalingClient(client: self, didAuthenticateOnServer: true, error: nil)
                    }else{
                        if let error = json["error"].string {
                            self.delegate?.signalingClient(client: self, didAuthenticateOnServer: false, error: .unableToSignIn(reason: error))
                        }
                    }
                }
            }
            
            if event == "offer" {
                if let sdp = json["sdp"].string {
                    self.handleOffer(sdp: sdp)
                }
            }
        }
    }
    
    func handleOffer(sdp: String) {
        self.delegate?.signalingClient(client: self, didReceiveOfferWithSdp: sdp)
    }
    
    
    func handleError(_ error: SignalingClientError) {
        print(error)
    }
    
    public func sendOffer(withSdp sdp: String) {
        let request: [String: String] = [
            "event": "offer",
            "message": sdp
        ]
        
        do {
            let data = try JSON(request).rawData()
            if let socket = self.socket {
                socket.write(data: data)
            }else{
                self.handleError(.socketNotInitialized)
            }
        }catch{
            self.handleError(.jsonDecodingFailed)
        }
    }
    
    func authenticate(socket: WebSocketClient, type: SignalingClientAuthentificationType) {
        let request: [String: String] = [
            "event": "authenticate",
            "username": self.username!,
            "password": self.password!,
            "rule": "\(type)"
        ]
        
        do {
            let data = try JSON(request).rawData()
            socket.write(data: data)
        }catch{
            self.handleError(.jsonDecodingFailed)
        }
    }
    
    
}

extension SignalingClient: WebSocketDelegate {
    public func websocketDidConnect(socket: WebSocketClient) {
        self.didConnect(withSocket: socket)
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        self.didDisconnect(fromSocket: socket, error: error)
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        self.didReceiveMessage(fromSocket: socket, message: text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
}
