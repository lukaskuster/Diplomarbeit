//
//  SPDelegate.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 31.01.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import Foundation
import SIMplePhoneKit

@objc class SPDelegate: NSObject {
    public static let shared = SPDelegate()
    
    override init() {
        super.init()
        SPManager.shared.delegate = self
    }
    
    @objc public func initiateCall(with phoneNumber: String) {
        let number = SPNumber(withNumber: phoneNumber)
        self.initiateCall(with: number)
    }
    
    public func initiateCall(with phoneNumber: SPNumber) {        
        if let controller = UIApplication.shared.topMostViewController() {
            let vc = SelectGatewayViewController(number: phoneNumber)
            vc.parentVC = controller
            let selectVC = UINavigationController(rootViewController: vc)
            let seque = SelectGatewaySegue(identifier: nil, source: controller, destination: selectVC)
            seque.perform()
        }
    }
    
    @objc public class func sharedInstance() -> SPDelegate {
        return self.shared
    }
}

extension SPDelegate: SPManagerDelegate {
    func spManager(didAnswerIncomingCall from: SPNumber, on gateway: SPGateway) {
        print("incoming call answered")
    }
}
