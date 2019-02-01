//
//  WebRTCClient.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 25.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import WebRTC

public protocol WebRTCClientDelegate {
    func webRTCClient(didReceiveError error: Error)
    func webRTCClient(didGenerateNewCandidate candidateSdp: String)
    func webRTCClient(didReceiveRemoteTrack track: RTCAudioTrack)
}

public class WebRTCClient: NSObject {
    public var delegate: WebRTCClientDelegate?
    private var connectionFactory: RTCPeerConnectionFactory
    private var peerConnection: RTCPeerConnection
    
    private let iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
                              RTCIceServer(urlStrings: ["stun:stun1.l.google.com:19302"]),
                              RTCIceServer(urlStrings: ["stun:stun2.l.google.com:19302"]),
                              RTCIceServer(urlStrings: ["stun:stun3.l.google.com:19302"]),
                              RTCIceServer(urlStrings: ["stun:stun4.l.google.com:19302"])]
    private let mediaConstraints = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue]
    
    override init() {
        RTCPeerConnectionFactory.initialize()
        self.connectionFactory = RTCPeerConnectionFactory()

        let configuration = RTCConfiguration()
        configuration.iceServers = self.iceServers
        configuration.sdpSemantics = .unifiedPlan
        configuration.continualGatheringPolicy = .gatherContinually
        
        let constraint = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue])
        self.peerConnection = self.connectionFactory.peerConnection(with: configuration, constraints: constraint, delegate: nil)
        
        super.init()
        self.optimizeForCallKit()
        self.addMediaStreams()
        self.peerConnection.delegate = self
    }
    
    private func addMediaStreams() {
        let audioTrack = self.createAudioTrack()
        self.peerConnection.add(audioTrack, streamIds: ["stream0"])
    }
    
    private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.connectionFactory.audioSource(with: audioConstrains)
        let audioTrack = self.connectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }
    
    private func optimizeForCallKit() {
        RTCAudioSession.sharedInstance().useManualAudio = true
        RTCAudioSession.sharedInstance().isAudioEnabled = false
    }
    
    public func muteAudio() {
        self.setAudioEnabled(false)
    }
    
    public func unmuteAudio() {
        self.setAudioEnabled(true)
    }
    
    private func setAudioEnabled(_ isEnabled: Bool) {
        let audioTracks = self.peerConnection.senders.compactMap { return $0.track as? RTCAudioTrack }
        audioTracks.forEach { $0.isEnabled = isEnabled }
    }
    
}

extension WebRTCClient {
    public func offer(completion: @escaping (String?, Error?) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: self.mediaConstraints, optionalConstraints: nil)
        self.peerConnection.offer(for: constraints) { (sdp, error) in
            guard let sdp = sdp else {
                completion(nil, error)
                return
            }
            let offerSdp = sdp.PCMAonly
            self.peerConnection.setLocalDescription(offerSdp, completionHandler: { error in
                completion(offerSdp.sdp, error)
            })
        }
    }
    
    public func answer(completion: @escaping (String?, Error?) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: self.mediaConstraints, optionalConstraints: nil)
        self.peerConnection.answer(for: constraints) { (sdp, error) in
            guard let sdp = sdp else {
                completion(nil, error)
                return
            }
            let answerSdp = sdp.PCMAonly
            self.peerConnection.setLocalDescription(answerSdp, completionHandler: { error in
                completion(answerSdp.sdp, error)
            })
        }
    }
    
    private func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> Void) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    public func handle(offer offerString: String, completion: @escaping (Error?) -> Void) {
        let offerSdp = RTCSessionDescription(type: .offer, sdp: offerString)
        self.set(remoteSdp: offerSdp, completion: completion)
    }
    
    public func handle(answer answerString: String, completion: @escaping (Error?) -> Void) {
        let answerSdp = RTCSessionDescription(type: .answer, sdp: answerString)
        self.set(remoteSdp: answerSdp, completion: completion)
    }
    
    func closeConnection() {
        if let stream = self.peerConnection.localStreams.first {
            self.peerConnection.remove(stream)
        }
        self.peerConnection.close()
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("peerConnection: didChange RTCSignalingState")
        debugPrint(stateChanged)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("peerConnection: didAdd RTCMediaStream")
        debugPrint(stream)
        
        for track in stream.audioTracks {
            self.delegate?.webRTCClient(didReceiveRemoteTrack: track)
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("peerConnection: didRemove RTCMediaStream")
        debugPrint(stream)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("peerConnection: didChange RTCIceConnectionState")
        debugPrint(newState)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("peerConnection: didChange RTCIceGatheringState")
        print("\(newState.rawValue)")
        if case .complete = newState {
            print("completed getting candidates")
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.webRTCClient(didGenerateNewCandidate: candidate.sdp)
        print("peerConnection: didGenerate RTCIceCandidate")
        debugPrint(candidate)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("peerConnection: didRemove RTCIceCandidate")
        debugPrint(candidates)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("peerConnection: didOpen RTCDataChannel")
        debugPrint(dataChannel)
    }
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnection: ShouldNegotiate RTCPeerConnection")
        debugPrint(peerConnection)
    }
}
