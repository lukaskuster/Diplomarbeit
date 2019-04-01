//
//  CallKitManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 30.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import CallKit
import AVFoundation

/// Delegate Protocol of the CallKitManagerDelegate
public protocol CallKitManagerDelegate {
    /// Called when the user accepts the incoming call from the gateway
    ///
    /// - Parameters:
    ///   - gateway: SPGateway that is operating the call
    ///   - caller: The calling party (SPNumber)
    ///   - completion: A completion handler that is supposed to be called by the delegate receiver
    /// - Returns: ()
    func callKitManager(didAcceptIncomingCallFromGateway gateway: SPGateway, with caller: SPNumber, completion: @escaping (_ success: Bool) -> Void)
    /// Called when the outgoing call is connected
    ///
    /// - Parameters:
    ///   - gateway: SPGateway that is operating the call
    ///   - caller: The calling party (SPNumber)
    ///   - completion: A completion handler that is supposed to be called by the delegate receiver
    /// - Returns: ()
    func callKitManager(didConnectOutgoingCallFromGateway gateway: SPGateway, with caller: SPNumber, completion: @escaping (_ success: Bool) -> Void)
    /// Called when the incoming call is declined
    ///
    /// - Parameters:
    ///   - gateway: SPGateway that is operating the call
    ///   - recentItem: A SPRecentCall object representing inforamtion about the call
    ///   - completion: A completion handler that is supposed to be called by the delegate receiver
    /// - Returns: ()
    func callKitManager(didDeclineIncomingCallFromGateway gateway: SPGateway, withRecentCallItem recentItem: SPRecentCall, completion: @escaping (_ success: Bool) -> Void)
    /// Called when the call is ended
    ///
    /// - Parameters:
    ///   - gateway: SPGateway that is operating the call
    ///   - recentItem: A SPRecentCall object representing inforamtion about the call
    ///   - completion: A completion handler that is supposed to be called by the delegate receiver
    /// - Returns: ()
    func callKitManager(didEndCallFromGateway gateway: SPGateway, withRecentCallItem recentItem: SPRecentCall, completion: @escaping (_ success: Bool) -> Void)
    /// Called when the calls held state is changed
    ///
    /// - Parameters:
    ///   - isOnHold: Boolean indicating the held state (true = held)
    ///   - gateway: SPGateway that is operating the call
    ///   - completion: A completion handler that is supposed to be called by the delegate receiver
    /// - Returns: ()
    func callKitManager(didChangeHeldState isOnHold: Bool, onCallFrom gateway: SPGateway, completion: @escaping (_ success: Bool) -> Void)
    /// Called when the calls muting state is changed
    ///
    /// - Parameters:
    ///   - isMuted: Boolean indicating the mute state (true = muted)
    ///   - gateway: SPGateway that is operating the call
    ///   - completion: A completion handler that is supposed to be called by the delegate receiver
    /// - Returns: ()
    func callKitManager(didChangeMuteState isMuted: Bool, onCallFrom gateway: SPGateway, completion: @escaping (_ success: Bool) -> Void)
    /// Called when the caller sends out DTMF tones
    ///
    /// - Parameters:
    ///   - digits: DTMF digits to be send
    ///   - gateway: SPGateway that is operating the call
    ///   - completion: A completion handler that is supposed to be called by the delegate receiver
    func callKitManager(didEnterDTMF digits: String, onCallFrom gateway: SPGateway, completion: @escaping (_ success: Bool) -> Void)
}

/// Manager used to interact with CallKit
public class CallKitManager: NSObject {
    /// Shared instance of the CallKitManager
    public static let shared = CallKitManager()
    /// Reference to the class that implemented the delegate protocol
    public var delegate: CallKitManagerDelegate?
    private let provider: CXProvider
    private let callController: CXCallController
    private let callManager = CallManager()
    
    private override init() {
        let configuration = CXProviderConfiguration(localizedName: "SIMplePhone")
        configuration.ringtoneSound = "ringtone.caf"
        configuration.supportsVideo = false
        configuration.supportedHandleTypes = [.phoneNumber]
        configuration.includesCallsInRecents = true
        configuration.maximumCallsPerCallGroup = 1
        configuration.iconTemplateImageData = #imageLiteral(resourceName: "callkit-icon").pngData()
        self.provider = CXProvider(configuration: configuration)
        self.callController = CXCallController()
        super.init()
        self.provider.setDelegate(self, queue: nil)
    }
    
    /// Reports an outgoing call to the system via CallKit
    ///
    /// - Parameters:
    ///   - number: SPNumber of the recipient of the call
    ///   - gateway: SPGateway that is used for the call
    public func reportOutgoingCall(to number: SPNumber, on gateway: SPGateway) {
        let call = Call(with: number, on: gateway, .outgoing)
        let handle = CXHandle(type: .phoneNumber, value: number.phoneNumber)
        let callAction = CXStartCallAction(call: call.uuid, handle: handle)
        self.callController.requestTransaction(with: callAction) { error in
            if let error = error {
                print("Error while initializing call \(error.localizedDescription)")
                return
            }
            self.callManager.add(call: call)
        }
    }
    
    /// Reports an incoming call to the system via CallKit
    ///
    /// - Parameters:
    ///   - number: SPNumber of the calling party
    ///   - gateway: SPGateway that is receiving the call
    public func reportIncomingCall(from number: SPNumber, on gateway: SPGateway) {
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = CXHandle(type: .phoneNumber, value: number.phoneNumber)
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        let call = Call(with: number, on: gateway, .incoming)
        self.provider.reportNewIncomingCall(with: call.uuid, update: callUpdate) { (error) in
            if let error = error {
                print("Error while initializing call \(error.localizedDescription)")
                return
            }
            self.callManager.add(call: call)
        }
    }
    
    /// Enum representing a reason why the call ended
    public enum CallEndReason {
        /// Call was answered by another device
        case otherDeviceDidAnswer
        /// Call was declined by another device
        case otherDeviceDidDecline
        /// Call was ended by the other party
        case endedByRemote
        /// Call was left unanswered (e.g. timed-out; straight to voicemail)
        case unanswered
        /// The end of the call was initiated by the user
        case userInitiated
    }
    
    /// Reports to the system (CallKit) that the call was ended
    ///
    /// - Parameters:
    ///   - reason: A CallEndReason why the call was ended
    ///   - gateway: The SPGateway used for the call
    public func reportCallEnded(because reason: CallEndReason, on gateway: SPGateway) {
        guard let call = self.callManager.callOnGateway(gateway) else {
            return
        }
        if reason == .userInitiated {
            let callAction = CXEndCallAction(call: call.uuid)
            self.callController.requestTransaction(with: callAction) { error in
                if let error = error {
                    print("EndCallAction transaction request failed: \(error.localizedDescription).")
                    self.reportCallEnded(because: .endedByRemote, on: gateway)
                }
                self.callManager.remove(call: call)
            }
            return
        }
        let cxreason: CXCallEndedReason
        switch reason {
        case .otherDeviceDidAnswer:
            cxreason = .answeredElsewhere
        case .otherDeviceDidDecline:
            cxreason = .declinedElsewhere
        case .endedByRemote:
            cxreason = .remoteEnded
        case .unanswered:
            cxreason = .unanswered
        case .userInitiated:
            return
        }
        self.provider.reportCall(with: call.uuid, endedAt: Date(), reason: cxreason)
        self.callManager.remove(call: call)
    }
}

extension CallKitManager: CXProviderDelegate {
    /// Called when the CallKit provider begins
    ///
    /// - Parameter provider: The telephony provider (CXProvider)
    public func providerDidBegin(_ provider: CXProvider) {
        print("provider did begin")
    }
    
    /// Called when the CallKit provider is reset
    ///
    /// - Parameter provider: The telephony provider (CXProvider)
    public func providerDidReset(_ provider: CXProvider) {
        self.callManager.removeAllCalls()
    }
    
    /// Called when the CallKit provider performs the specified answer call action
    ///
    /// - Parameters:
    ///   - provider: The telephony provider (CXProvider)
    ///   - action: The answer call action
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = self.callManager.callWithUUID(action.callUUID) else {
            action.fail()
            return
        }
        delegate?.callKitManager(didAcceptIncomingCallFromGateway: call.gateway, with: call.number, completion: { success in
            if success {
                call.start()
                action.fulfill()
            }else{
                action.fail()
            }
        })
    }
    
    /// Called when the CallKit provider performs the specified end call action
    ///
    /// - Parameters:
    ///   - provider: The telephony provider (CXProvider)
    ///   - action: The end call action
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let call = self.callManager.callWithUUID(action.callUUID) else {
            action.fail()
            return
        }
        if call.isConnected {
            let recentCallItem = SPRecentCall(with: call.number, at: call.startTime, for: call.duration, direction: call.direction, missed: false, gateway: call.gateway)
            delegate?.callKitManager(didEndCallFromGateway: call.gateway, withRecentCallItem: recentCallItem, completion: { success in
                success ? action.fulfill() : action.fail()
            })
        }else{
            let recentCallItem = SPRecentCall(with: call.number, at: call.startTime, for: nil, direction: call.direction, missed: true, gateway: call.gateway)
            delegate?.callKitManager(didDeclineIncomingCallFromGateway: call.gateway, withRecentCallItem: recentCallItem, completion: { success in
                success ? action.fulfill() : action.fail()
            })
        }
        self.callManager.remove(call: call)
    }
    
    /// Called when the CallKit provider performs the specified start call action
    ///
    /// - Parameters:
    ///   - provider: The telephony provider (CXProvider)
    ///   - action: The start call action
    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        guard let call = self.callManager.callWithUUID(action.callUUID) else {
            action.fail()
            return
        }
        self.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
        delegate?.callKitManager(didConnectOutgoingCallFromGateway: call.gateway, with: call.number, completion: { success in
            if success {
                self.provider.reportOutgoingCall(with: call.uuid, connectedAt: nil)
                call.start()
                action.fulfill()
            }else{
                action.fail()
            }
        })
    }

    /// Called when the CallKit provider performs the specified set held call action
    ///
    /// - Parameters:
    ///   - provider: The telephony provider (CXProvider)
    ///   - action: The set held call action
    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = self.callManager.callWithUUID(action.callUUID) else {
            action.fail()
            return
        }
        delegate?.callKitManager(didChangeHeldState: action.isOnHold, onCallFrom: call.gateway, completion: { success in
            success ? action.fulfill() : action.fail()
        })
    }
    
    /// Called when the provider performs the specified play DTMF (dual tone multifrequency) call action
    ///
    /// - Parameters:
    ///   - provider: The telephony provider (CXProvider)
    ///   - action: The play DTMF call action
    public func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        guard let call = self.callManager.callWithUUID(action.callUUID) else {
            action.fail()
            return
        }
        delegate?.callKitManager(didEnterDTMF: action.digits, onCallFrom: call.gateway, completion: { success in
            success ? action.fulfill() : action.fail()
        })
    }
    
    /// Called when the provider performs the specified set muted call action
    ///
    /// - Parameters:
    ///   - provider: The telephony provider (CXProvider)
    ///   - action: The set muted call action
    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let call = self.callManager.callWithUUID(action.callUUID) else {
            action.fail()
            return
        }
        delegate?.callKitManager(didChangeMuteState: action.isMuted, onCallFrom: call.gateway, completion: { success in
            success ? action.fulfill() : action.fail()
        })
    }
    
    /// Called when the provider’s audio session is activated
    ///
    /// - Parameters:
    ///   - provider: The telephony provider (CXProvider)
    ///   - audioSession: The audio session that was activated
    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        PeerConnectionManager.shared.notify(didActivate: audioSession)
    }
    
    /// Called when the provider’s audio session is deactivated
    ///
    /// - Parameters:
    ///   - provider: The telephony provider (CXProvider)
    ///   - audioSession: The audio session that was deactivated
    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        PeerConnectionManager.shared.notify(didDeactivate: audioSession)
    }
}

fileprivate class CallManager {
    private var calls = [Call]()
    
    func callWithUUID(_ uuid: UUID) -> Call? {
        guard let index = calls.index(where: { $0.uuid == uuid }) else {
            return nil
        }
        return calls[index]
    }
    
    func callOnGateway(_ gateway: SPGateway) -> Call? {
        guard let index = calls.index(where: { $0.gateway.imei == gateway.imei }) else {
            return nil
        }
        return calls[index]
    }
    
    func add(call: Call) {
        calls.append(call)
    }
    
    func remove(call: Call) {
        guard let index = calls.index(where: { $0 === call }) else { return }
        calls.remove(at: index)
    }
    
    func removeAllCalls() {
        calls.removeAll()
    }
}

fileprivate class Call {
    let uuid: UUID
    let number: SPNumber
    let gateway: SPGateway
    var startTime: Date?
    var isConnected = false
    var direction: SPRecentCall.Direction
    var duration: TimeInterval {
        get { return self.end() }
    }
    
    init(with number: SPNumber, on gateway: SPGateway, _ direction: SPRecentCall.Direction) {
        self.uuid = UUID()
        self.number = number
        self.gateway = gateway
        self.direction = direction
    }
    
    func start() {
        self.isConnected = true
        self.startTime = Date()
    }
    
    private func end() -> TimeInterval {
        return Date().timeIntervalSince(self.startTime ?? Date())
    }
}
