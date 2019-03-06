//
//  SPDelegate.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 31.01.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import Foundation
import SIMplePhoneKit
import SwiftMessages

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
    
    public func display(error: Error) {
        var config = SwiftMessages.Config()
        config.presentationContext = .window(windowLevel: .statusBar)
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.error)
        view.configureContent(title: "An Error occured!", body: "\(error)")
        view.button?.isHidden = true
        view.layoutMarginAdditions = UIEdgeInsets(top: 25, left: 20, bottom: 20, right: 20)
        SwiftMessages.show(config: config, view: view)
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
