//
//  PeerConnectionManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 27.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import WebRTC

class PeerConnectionManager: NSObject {
    public static let shared = PeerConnectionManager()
    private var rtcClient: WebRTCClient?
    private var signalingClient: SignalingClient?
    
    private var signalingUsername: String?
    private var signalingPassword: String?
    
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
    
    private func initDependancies(completion: @escaping (Error?) -> Void) {
        self.rtcClient = WebRTCClient()
        self.rtcClient?.delegate = self
        self.signalingClient = SignalingClient()
        if let username = signalingUsername,
           let password = signalingPassword {
            self.signalingClient?.setCredentials(username: username, password: password)
        }else{
            completion(PeerConnectionError.MissingSignalingCredentials)
            return
        }
        completion(nil)
    }
    
    public func makeCall(_ phoneNumber: SPNumber, with gateway: SPGateway, completion: @escaping (Error?) -> Void) {
        self.initDependancies { error in
            if let error = error {
                completion(error)
                return
            }
        }
        guard let rtcClient = self.rtcClient else {
            completion(PeerConnectionError.NoRTCInstanceFound)
            return
        }
        guard let signalingClient = self.signalingClient else {
            completion(PeerConnectionError.NoSignalingInstanceFound)
            return
        }
        rtcClient.generateOffer { (success, sdp, error) in
            if success {
                signalingClient.post(offer: sdp!, completion: { (success, answer, error) in
                    if success {
                        rtcClient.handle(answer: answer!, completion: { (success, error) in
                            if success {
                                completion(nil)
                            }else{
                                completion(PeerConnectionError.RTCError(error!))
                            }
                        })
                    }else{
                        completion(PeerConnectionError.CouldNotGetAnswerFromGateway)
                    }
                })
            }else{
                completion(PeerConnectionError.CouldNotGenerateOffer)
            }
        }
    }
    
    public func hangUpCall(on gateway: SPGateway, completion: @escaping (Error?) -> Void) {
        guard let rtcClient = self.rtcClient else {
            completion(PeerConnectionError.NoRTCInstanceFound)
            return
        }
        guard let signalingClient = self.signalingClient else {
            completion(PeerConnectionError.NoSignalingInstanceFound)
            return
        }
        rtcClient.closeConnection()
        self.rtcClient = nil
        signalingClient.close()
        self.signalingClient = nil
        completion(nil)
    }
    
    public func receivingIncomingCall(from phoneNumber: SPNumber, with gateway: SPGateway, completion: @escaping (Error?) -> Void) {
        self.initDependancies { error in
            if let error = error {
                completion(error)
                return
            }
        }
        guard let rtcClient = self.rtcClient else {
            completion(PeerConnectionError.NoRTCInstanceFound)
            return
        }
        guard let signalingClient = self.signalingClient else {
            completion(PeerConnectionError.NoSignalingInstanceFound)
            return
        }
        signalingClient.getOffer { (success, offer, error) in
            if success {
                rtcClient.handle(offer: offer!, completion: { (success, answer, error) in
                    if success {
                        signalingClient.post(answer: answer!, completion: { (success, error) in
                            if success {
                                completion(nil)
                            }else{
                                completion(PeerConnectionError.SignalingError(error!))
                            }
                        })
                    }else{
                        completion(PeerConnectionError.CouldNotGenerateAnswer)
                    }
                })
            }else{
                completion(PeerConnectionError.CouldNotGetOfferFromGateway)
            }
        }
    }
    
    public func setSignalingCredentials(username: String, password: String) {
        self.signalingUsername = username
        self.signalingPassword = password
    }
}

extension PeerConnectionManager: WebRTCClientDelegate {
    public func webRTCClient(client: WebRTCClient, didReceiveError error: Error) {
        print(error.localizedDescription)
    }
    
    public func webRTCClient(client: WebRTCClient, didReceiveRemoteTrack track: RTCAudioTrack) {
        print("\(track.source.volume)")
    }
    
    public func webRTCClient(didGenerateNewCandidate candidateSdp: String) {
        guard let signalingClient = self.signalingClient else {
            print("Error while postingNewCandidate \(PeerConnectionError.NoSignalingInstanceFound)")
            return
        }
        
        signalingClient.postCandidate(candidate: candidateSdp, completion: { (success, error) in
            print("post candidate \(candidateSdp)")
            if let error = error {
                print("Error: RTCIceCandidate/Signalling \(error)")
            }
        })
    }
}
