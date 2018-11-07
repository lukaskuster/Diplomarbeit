//
//  CallKitManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 30.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import PushKit
import CallKit
import Contacts

public class CallKitManager: NSObject, PKPushRegistryDelegate, CXProviderDelegate {
    
    public func receiveCall() {
        let provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "SIMplePhone"))
        provider.setDelegate(self, queue: nil)
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "Pete Za")
        provider.reportNewIncomingCall(with: UUID(), update: update, completion: { error in })
    }
    
    public func initiateCall(with contact: CNContact) {
        let provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "SIMplePhone"))
        provider.setDelegate(self, queue: nil)
        let controller = CXCallController()
        
        let transaction = CXTransaction(action: CXStartCallAction(call: UUID(), handle: CXHandle(type: .generic, value: contact.givenName+" "+contact.familyName)))
        controller.request(transaction, completion: { error in })
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        print(pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined())
    }
    
    private func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        
    }
    
    public func providerDidReset(_ provider: CXProvider) {
    }
    
    private func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
    }
    
    private func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
    }
    
    
}
