//
//  PeerConnectionManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 27.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import WebRTC

/// Manager responsible for all the active PeerConnections
class PeerConnectionManager: NSObject {
    /// Shared instance of the PeerConnectionManager
    public static let shared = PeerConnectionManager()
    private var peerConnections = [String: PeerConnection]()
    
    private var signalingUsername: String?
    private var signalingPassword: String?
    
    /// Enum indicating an error returned by the PeerConnectionManager
    ///
    /// - NoRTCInstanceFound:
    /// - NoSignalingInstanceFound: <#NoSignalingInstanceFound description#>
    /// - CouldNotGenerateAnswer: <#CouldNotGenerateAnswer description#>
    /// - CouldNotGenerateOffer: <#CouldNotGenerateOffer description#>
    /// - CouldNotGetAnswerFromGateway: <#CouldNotGetAnswerFromGateway description#>
    /// - CouldNotGetOfferFromGateway: <#CouldNotGetOfferFromGateway description#>
    /// - MissingSignalingCredentials: <#MissingSignalingCredentials description#>
    /// - SignalingError: Another Signaling error occurred
    /// - RTCError: Another WebRTC error occurred
    public enum PeerConnectionError: Error {
        case NoRTCInstanceFound
        case NoSignalingInstanceFound
        case CouldNotGenerateAnswer
        case CouldNotGenerateOffer
        case CouldNotGetAnswerFromGateway
        case CouldNotGetOfferFromGateway
        case MissingSignalingCredentials
        case SignalingError(_ error: Error)
        case RTCError(_ error: Error)
    }
    
    private func getPeerConnection(with gateway: SPGateway, completion: @escaping (PeerConnection) -> Void) {
        if let peerconnection = self.peerConnections[gateway.imei] {
            completion(peerconnection)
        }else{
            if let username = signalingUsername,
               let password = signalingPassword {
                    let peerconnection = PeerConnection(username: username, password: password, gateway: gateway)
                    self.peerConnections[gateway.imei] = peerconnection
                    completion(peerconnection)
            }
        }
    }
    
    private func destroyPeerConnection(with gateway: SPGateway) {
        self.peerConnections.removeValue(forKey: gateway.imei)
    }
    
    public func makeCall(_ phoneNumber: SPNumber, with gateway: SPGateway, completion: @escaping (Error?) -> Void) {
        self.getPeerConnection(with: gateway) { peerconnection in
            peerconnection.call(phoneNumber, completion: completion)
        }
    }
    
    public func hangUpCall(on gateway: SPGateway, completion: @escaping (Error?) -> Void) {
        self.getPeerConnection(with: gateway) { peerconnection in
            peerconnection.hangUp(completion: { error in
                if let error = error {
                    completion(error)
                }
                self.destroyPeerConnection(with: gateway)
                completion(nil)
            })
        }
    }
    
    public func receivingIncomingCall(from phoneNumber: SPNumber, with gateway: SPGateway, completion: @escaping (Error?) -> Void) {
        self.getPeerConnection(with: gateway) { peerconnection in
            peerconnection.incomingCall(from: phoneNumber, completion: completion)
        }
    }
    
    public func notify(didActivate audioSession: AVAudioSession) {
        RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
        RTCAudioSession.sharedInstance().isAudioEnabled = true
    }
    
    public func notify(didDeactivate audioSession: AVAudioSession) {
        RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
    }
    
    public func notify(callOnGateway gateway: SPGateway, isOnHold: Bool) {
        self.getPeerConnection(with: gateway) { peerconnection in
            if isOnHold {
                peerconnection.muteAudio()
            }else{
                peerconnection.unmuteAudio()
            }
        }
    }
    
    public func notify(callOnGateway gateway: SPGateway, isMuted: Bool) {
        self.getPeerConnection(with: gateway) { peerconnection in
            if isMuted {
                peerconnection.muteAudio()
            }else{
                peerconnection.unmuteAudio()
            }
        }
    }
    
    public func setSignalingCredentials(username: String, password: String) {
        self.signalingUsername = username
        self.signalingPassword = password
    }
}

fileprivate class PeerConnection: NSObject {
    private var rtcClient: WebRTCClient
    private var signalingClient: SignalingClient
    
    public init(username: String, password: String, gateway: SPGateway) {
        self.rtcClient = WebRTCClient()
        self.signalingClient = SignalingClient(username: username, password: password, imei: gateway.imei)
        super.init()
        self.rtcClient.delegate = self
    }
    
    public func call(_ phoneNumber: SPNumber, completion: @escaping (Error?) -> Void) {
        self.rtcClient.offer(completion: { (offerSdp, error) in
            if let error = error {
                completion(error)
            }
            guard let offerSdp = offerSdp else {
                completion(PeerConnectionManager.PeerConnectionError.CouldNotGenerateOffer)
                return
            }
            
            self.signalingClient.post(offer: offerSdp, completion: { (answerSdp, error) in
                if let error = error {
                    completion(error)
                }
                guard let answerSdp = answerSdp else {
                    completion(PeerConnectionManager.PeerConnectionError.CouldNotGetAnswerFromGateway)
                    return
                }
                
                self.rtcClient.handle(answer: answerSdp, completion: { error in
                    if let error = error {
                        completion(error)
                    }
                    
                    completion(nil)
                })
                
            })
            
        })
    }
    
    public func incomingCall(from phoneNumber: SPNumber, completion: @escaping (Error?) -> Void) {
        self.signalingClient.receiveOffer(completion: { (offerSdp, error) in
            if let error = error {
                completion(error)
            }
            guard let offerSdp = offerSdp else {
                completion(PeerConnectionManager.PeerConnectionError.CouldNotGetOfferFromGateway)
                return
            }
            
            self.rtcClient.handle(offer: offerSdp, completion: { error in
                if let error = error {
                    completion(error)
                }
                
                self.rtcClient.answer(completion: { (answerSdp, error) in
                    if let error = error {
                        completion(error)
                    }
                    guard let answerSdp = answerSdp else {
                        completion(PeerConnectionManager.PeerConnectionError.CouldNotGenerateAnswer)
                        return
                    }
                    
                    self.signalingClient.post(answer: answerSdp, completion: { error in
                        if let error = error {
                            completion(error)
                        }
                        
                        completion(nil)
                    })
                })
                
            })
            
        })
    }
    
    public func hangUp(completion: @escaping (Error?) -> Void) {
        self.rtcClient.closeConnection()
        self.signalingClient.close()
        completion(nil)
    }
    
    public func muteAudio() {
        self.rtcClient.muteAudio()
    }
    
    public func unmuteAudio() {
        self.rtcClient.unmuteAudio()
    }
}

extension PeerConnection: WebRTCClientDelegate {
    func webRTCClient(didReceiveError error: Error) {
        print("[WEBRTC-CLIENT]: \(error)")
    }
    
    func webRTCClient(didGenerateNewCandidate candidateSdp: String) {
        self.signalingClient.post(candidate: candidateSdp) { error in
            if let error = error {
                print("[SIGNALING-CLIENT]: Error while sending out candidate \(error)")
            }
        }
    }
    
    func webRTCClient(didReceiveRemoteTrack track: RTCAudioTrack) {
        print("did receive remote track \(track)")
    }
}
