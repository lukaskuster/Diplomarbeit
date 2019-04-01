//
//  CloudEnvironmentButton.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 21.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

protocol CloudEnvironmentButtonDelegate {
    func cloudEnvironmentDidChange(to: SPManager.SPKeychainEnvironment)
    func cloudEnvironmentRequestsAlert(_ alert: UIAlertController)
}

extension CloudEnvironmentButtonDelegate {
    func cloudEnvironmentChecking(_ finished: Bool = false) {   }
}

class CloudEnvironmentButton: UIButton {
    public var delegate: CloudEnvironmentButtonDelegate?
    
    private enum BtnState {
        case enabled
        case disabled
        case checking
        case unavailableCloudAlreadyAssociatedWithDifferentAccount
        case unavailableAccountAssociatedWithDifferentCloud
    }
    private var selectorState: BtnState = .enabled {
        didSet {
            self.layout(selectorState)
        }
    }
    private var environment: SPManager.SPKeychainEnvironment = .cloud {
        willSet(newValue) {
            if newValue != environment {
                self.delegate?.cloudEnvironmentDidChange(to: newValue)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }
    
    private func layout(_ state: BtnState) {
        self.isEnabled = true
        self.delegate?.cloudEnvironmentChecking()
        
        switch state {
        case .unavailableCloudAlreadyAssociatedWithDifferentAccount, .unavailableAccountAssociatedWithDifferentCloud:
            self.environment = .local
            self.setTitle("iCloud Sharing unavailable", for: .normal)
            self.setTitleColor(UIColor.lightGray, for: .normal)
        case .disabled:
            self.environment = .local
            self.setTitle("iCloud Sharing disabled", for: .normal)
            self.setTitleColor(UIColor.darkGray, for: .normal)
        case .enabled:
            self.environment = .cloud
            self.setTitle("Share with all my devices through iCloud", for: .normal)
            self.setTitleColor(#colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1), for: .normal)
        case .checking:
            self.environment = .local
            self.setTitle("Checking...", for: .normal)
            self.setTitleColor(UIColor.lightGray, for: .normal)
            self.isEnabled = false
            self.delegate?.cloudEnvironmentChecking(true)
        }
    }
    
    public func updateForUsername(_ username: String?) {
        print("checking un: \(username)")
        let stateCache = self.selectorState
        self.selectorState = .checking
        if let username = username {
            SPManager.shared.checkUsernameWithCloud(username) { (error) in
                print("response \(error)")
                if let error = error {
                    if error == .cloudAlreadyAssociatedWithDifferentAccount {
                        self.selectorState = .unavailableAccountAssociatedWithDifferentCloud
                    }
                }else{
                    if stateCache == .unavailableAccountAssociatedWithDifferentCloud {
                        self.selectorState = .enabled
                    }else{
                        self.selectorState = stateCache
                    }
                }
            }
        }else{
            self.selectorState = stateCache
        }
    }
    
    @objc private func didTap(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        switch self.selectorState {
        case .unavailableAccountAssociatedWithDifferentCloud:
            alert.title = "iCloud Sharing unavailable"
            alert.message = "Seems like your iCloud devices are already associated with another account. Log in there and disable iCloud Sharing (in Settings → Account) to procede."
        case .unavailableCloudAlreadyAssociatedWithDifferentAccount:
            alert.title = "iCloud Sharing unavailable"
            alert.message = "Seems like your account is already associated with another iCloud user. To enable sharing with the account associated to this device first disable iCloud Sharing on a device associated with the other iCloud user (in Settings → Account). Or you can just sign in on this device without iCloud Sharing enabled."
            alert.addAction(UIAlertAction(title: "Login without iCloud Sharing", style: .default, handler: { (action) in
                self.selectorState = .disabled
            }))
        case .disabled:
            alert.title = "Share Login Data through iCloud"
            alert.message = "iCloud Sharing automatically authentificates this account on all your other devices. It also syncs messages, the recent calls log and voicemails across the devices. By disabling it you are not able to use these features."
            alert.addAction(UIAlertAction(title: "Enable iCloud Sharing", style: .default, handler: { (action) in
                self.selectorState = .enabled
            }))
        case .enabled:
            alert.title = "Share Login Data through iCloud"
            alert.message = "iCloud Sharing automatically authentificates this account on all your other devices. It also syncs messages, the recent calls log and voicemails across the devices. By disabling it you are not able to use these features."
            alert.addAction(UIAlertAction(title: "Disable iCloud Sharing", style: .destructive, handler: { (action) in
                self.selectorState = .disabled
            }))
        case .checking:
            break
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds
        alert.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        alert.popoverPresentationController?.canOverlapSourceViewRect = false
        self.delegate?.cloudEnvironmentRequestsAlert(alert)
    }
}
