//
//  CallKitManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 30.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import CallKit

public protocol CallKitManagerDelegate {
    func callKitManager(didAcceptIncomingCallFromGateway gateway: SPGateway, completion: @escaping (_ success: Bool) -> Void)
    func callKitManager(didDeclineIncomingCallFromGateway gateway: SPGateway, completion: @escaping (_ success: Bool) -> Void)
    func callKitManager(didEndCallFromGateway gateway: SPGateway, completion: @escaping (_ success: Bool) -> Void)
    func callKitManager(didChangeHeldState isOnHold: Bool, onCallFrom gateway: SPGateway, completion: @escaping (_ success: Bool) -> Void)
    func callKitManager(didEnterDTMF digits: String, onCallFrom gateway: SPGateway, completion: @escaping (_ success: Bool) -> Void)
}

public class CallKitManager: NSObject {
    public static let shared = CallKitManager()
    public var delegate: CallKitManagerDelegate?
    private let provider: CXProvider
    private let callManager = CallManager()
    
    public override init() {
        let configuration = CXProviderConfiguration(localizedName: "SIMplePhone")
        configuration.ringtoneSound = "ringtone.caf"
        configuration.supportsVideo = false
        configuration.supportedHandleTypes = [.phoneNumber]
        configuration.includesCallsInRecents = true
        configuration.maximumCallsPerCallGroup = 1
        self.provider = CXProvider(configuration: configuration)
        super.init()
        self.provider.setDelegate(self, queue: nil)
    }
    
    public func reportIncomingCall(from number: SPNumber, on gateway: SPGateway) {
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = CXHandle(type: .phoneNumber, value: number.phoneNumber)
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        let call = Call(gateway: gateway)
        self.provider.reportNewIncomingCall(with: call.uuid, update: callUpdate) { (error) in
            if let error = error {
                print("Error while initializing call \(error.localizedDescription)")
                return
            }
            self.callManager.add(call: call)
        }
    }
    
    public enum CallEndReason {
        case otherDeviceDidAnswer
        case otherDeviceDidDecline
        case endedByRemote
        case unanswered
    }
    public func reportCallEnded(because reason: CallEndReason, on gateway: SPGateway) {
        guard let call = self.callManager.callOnGateway(gateway) else {
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
        }
        self.provider.reportCall(with: call.uuid, endedAt: Date(), reason: cxreason)
    }
}

extension CallKitManager: CXProviderDelegate {
    public func providerDidBegin(_ provider: CXProvider) {
        print("provider did begin")
    }
    
    public func providerDidReset(_ provider: CXProvider) {
        self.callManager.removeAllCalls()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = self.callManager.callWithUUID(action.callUUID) else {
            action.fail()
            return
        }
        delegate?.callKitManager(didAcceptIncomingCallFromGateway: call.gateway, completion: { success in
            if success {
                call.isConnected = true
                action.fulfill()
            }else{
                action.fail()
            }
        })
    }
    
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let call = self.callManager.callWithUUID(action.callUUID) else {
            action.fail()
            return
        }
        if call.isConnected {
            delegate?.callKitManager(didEndCallFromGateway: call.gateway, completion: { success in
                success ? action.fulfill() : action.fail()
            })
        }else{
            delegate?.callKitManager(didDeclineIncomingCallFromGateway: call.gateway, completion: { success in
                success ? action.fulfill() : action.fail()
            })
        }
        self.callManager.remove(call: call)
    }
    
    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = self.callManager.callWithUUID(action.callUUID) else {
            action.fail()
            return
        }
        delegate?.callKitManager(didChangeHeldState: action.isOnHold, onCallFrom: call.gateway, completion: { success in
            success ? action.fulfill() : action.fail()
        })
    }
    
    public func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        guard let call = self.callManager.callWithUUID(action.callUUID) else {
            action.fail()
            return
        }
        delegate?.callKitManager(didEnterDTMF: action.digits, onCallFrom: call.gateway, completion: { success in
            success ? action.fulfill() : action.fail()
        })
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
        guard let index = calls.index(where: { $0.gateway == gateway }) else {
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
    let gateway: SPGateway
    var isConnected = false
    
    init(gateway: SPGateway) {
        self.uuid = UUID()
        self.gateway = gateway
    }
}
