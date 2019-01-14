//
//  SPPeerConnectionManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 27.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import WebRTC

public class SPPeerConnectionManager: NSObject {
    public static let shared = SPPeerConnectionManager()
    private var rtcClient: WebRTCClient
    private var signalingClient: SignalingClient
    private var spManager: SPManager
    
    public override init() {
        self.rtcClient = WebRTCClient.shared
        self.signalingClient = SignalingClient.shared
        self.spManager = SPManager.shared
        super.init()
        self.rtcClient.delegate = self
    }
    
    public func makeCall(_ phoneNumber: SPNumber, with gateway: SPGateway, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        // Step 1: Push Notification to Gateway (via Server/SSE)
        self.spManager.dial(number: phoneNumber, with: gateway) { (success, response, error) in
            if success {
                // Step 2: Generate local WebRTC offer sdp
                print("self.rtcClient.generateOffer")
                self.rtcClient.startConnection()
                self.rtcClient.generateOffer(completion: { (success, sdp, error) in
                    if success {
                        // Step 3: Send local sdp to signaling server
                        print("self.signalingClient.post(offer: \(sdp!))")
                        self.signalingClient.post(offer: sdp!, completion: { (success, answer, error) in
                            if success {
                                // Step 4: Set remote sdp
                                print("self.rtcClient.handle(answer: \(answer!))")
                                self.rtcClient.handle(answer: answer!, completion: { (success, error) in
                                    
                                    print("connection should be established some time now")
                                })
                            }else{
                                completion(false, error!)
                            }
                        })
                    }else{
                        completion(false, error!)
                    }
                })
            }else{
                completion(false, error!)
            }
        }
    }
    
    public func hangUpCall(on gateway: SPGateway, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        self.spManager.hangUpCurrentCall(on: gateway) { (success, error) in
            if success {
                self.signalingClient.close()
                self.rtcClient.closeConnection()
                completion(true, nil)
            }else{
                completion(false, error)
            }
        }
    }
    
    public func receivingIncomingCall(from phoneNumber: SPNumber, with gateway: SPGateway, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        // Step 1: Get offer from signaling server
        self.signalingClient.getOffer { (success, offer, error) in
            if success {
                // Step 2: Set remote offer for WebRTC
                self.rtcClient.handle(offer: offer!, completion: { (success, answer, error) in
                    if success {
                        // Step 3: Send back answer to signaling server, which is hopefully still open
                        self.signalingClient.post(answer: answer!, completion: { (success, error) in
                            if success {
                                // Step 4: Start WebRTC connection
                                print("connection should be established some time now")
                            }else{
                                completion(false, error!)
                            }
                        })
                    }else{
                        completion(false, error!)
                    }
                })
            }
        }
    }
    
    
}

extension SPPeerConnectionManager: WebRTCClientDelegate {
    public func webRTCClient(client: WebRTCClient, didReceiveError error: Error) {
        print(error.localizedDescription)
    }
    
    public func webRTCClient(client: WebRTCClient, didReceiveRemoteTrack track: RTCAudioTrack) {
        print("\(track.source.volume)")
    }
}
