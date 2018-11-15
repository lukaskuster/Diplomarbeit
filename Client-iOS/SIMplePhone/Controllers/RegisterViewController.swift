//
//  RegisterViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 13.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class RegisterViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var givenNameField: SetupTextField!
    @IBOutlet weak var familyNameField: SetupTextField!
    @IBOutlet weak var usernameField: SetupTextField!
    @IBOutlet weak var passwordField: SetupTextField!
    @IBOutlet weak var repeatPasswordField: SetupTextField!
    @IBOutlet weak var createAccountBtn: SetupBoldButton!
    @IBOutlet weak var cloudEnvironmentSelectorBtn: UIButton!
    private var selectedCloudEnvironment: SPManager.SPKeychainEnvironment = .cloud
    private var environmentSelectorState: EnvironmentSelectorState = .enabled {
        didSet {
            self.layoutEnvironmentSelector(environmentSelectorState)
        }
    }
    
    enum EnvironmentSelectorState{
        case enabled
        case disabled
        case checking
        case unavailableCloudAlreadyAssociatedWithDifferentAccount
        case unavailableAccountAssociatedWithDifferentCloud
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleSwipe() {
        self.performSegue(withIdentifier: "backward", sender: self)
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    @IBAction func clickedRegisterBtn(_ sender: SetupBoldButton) {
        self.view.endEditing(true)
        if let givenName = self.givenNameField.text,
            let familyName = self.familyNameField.text,
            let username = self.usernameField.text,
            let password = self.passwordField.text,
            let repeatedPassword = self.repeatPasswordField.text {
            if !isValidEmail(username) {
                print("invalid mail!")
                return
            }
            if password == "" {
                print("no password")
                return
            }
            
            if password != repeatedPassword {
                print("passwords are not the same")
                return
            }
                let account = SPAccount(givenName: givenName, familyName: familyName, username: username, password: password)
            SPManager.shared.registerNewAccount(account, keychainEnvironment: self.selectedCloudEnvironment) { (success, error) in
                    if success {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let controller = storyboard.instantiateInitialViewController()
                            self.present(controller!, animated: false, completion: nil)
                        }
                    }else{
                        // TODO: Error handling
                        print(error!)
                    }
                }
        }
    }
    
    @IBAction func didTapCloudEnvironmentSelector(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        switch self.environmentSelectorState {
        case .unavailableAccountAssociatedWithDifferentCloud:
            alert.title = "iCloud Sharing unavailable"
            alert.message = "Seems like your iCloud devices are already associated with another account. Log in there and disable iCloud Sharing (in Settings → Account) to procede."
        case .unavailableCloudAlreadyAssociatedWithDifferentAccount:
            alert.title = "iCloud Sharing unavailable"
            alert.message = "Seems like your account is already associated with another iCloud user. To enable sharing with the account associated to this device first disable iCloud Sharing on a device associated with the other iCloud user (in Settings → Account). Or you can just sign in on this device without iCloud Sharing enabled."
            alert.addAction(UIAlertAction(title: "Login without iCloud Sharing", style: .default, handler: { (action) in
                self.environmentSelectorState = .disabled
            }))
        case .disabled:
            alert.title = "Share Login Data through iCloud"
            alert.message = "iCloud Sharing automatically authentificates this account on all your other devices. It also syncs messages, the recent calls log and voicemails across the devices. By disabling it you are not able to use these features."
            alert.addAction(UIAlertAction(title: "Enable iCloud Sharing", style: .default, handler: { (action) in
                self.environmentSelectorState = .enabled
            }))
        case .enabled:
            alert.title = "Share Login Data through iCloud"
            alert.message = "iCloud Sharing automatically authentificates this account on all your other devices. It also syncs messages, the recent calls log and voicemails across the devices. By disabling it you are not able to use these features."
            alert.addAction(UIAlertAction(title: "Disable iCloud Sharing", style: .destructive, handler: { (action) in
                self.environmentSelectorState = .disabled
            }))
        case .checking:
            break
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds
        alert.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        alert.popoverPresentationController?.canOverlapSourceViewRect = false
        self.present(alert, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case givenNameField:
            familyNameField.becomeFirstResponder()
        case familyNameField:
            usernameField.becomeFirstResponder()
        case usernameField:
            passwordField.becomeFirstResponder()
        case passwordField:
            repeatPasswordField.becomeFirstResponder()
        case repeatPasswordField:
            repeatPasswordField.resignFirstResponder()
        default:
            return false
        }
        return true
    }
    
    func layoutEnvironmentSelector(_ state: EnvironmentSelectorState) {
        self.cloudEnvironmentSelectorBtn.isEnabled = true
        self.createAccountBtn.isEnabled = true
        self.createAccountBtn.backgroundColor = self.view.tintColor
        switch state {
        case .unavailableCloudAlreadyAssociatedWithDifferentAccount, .unavailableAccountAssociatedWithDifferentCloud:
            self.selectedCloudEnvironment = .local
            self.cloudEnvironmentSelectorBtn.setTitle("iCloud Sharing unavailable", for: .normal)
            self.cloudEnvironmentSelectorBtn.setTitleColor(UIColor.lightGray, for: .normal)
        case .disabled:
            self.selectedCloudEnvironment = .local
            self.cloudEnvironmentSelectorBtn.setTitle("iCloud Sharing disabled", for: .normal)
            self.cloudEnvironmentSelectorBtn.setTitleColor(UIColor.darkGray, for: .normal)
        case .enabled:
            self.selectedCloudEnvironment = .cloud
            self.cloudEnvironmentSelectorBtn.setTitle("Share with all my devices through iCloud", for: .normal)
            self.cloudEnvironmentSelectorBtn.setTitleColor(self.view.tintColor, for: .normal)
        case .checking:
            self.selectedCloudEnvironment = .local
            self.cloudEnvironmentSelectorBtn.setTitle("Checking...", for: .normal)
            self.cloudEnvironmentSelectorBtn.setTitleColor(UIColor.lightGray, for: .normal)
            self.cloudEnvironmentSelectorBtn.isEnabled = false
            self.createAccountBtn.backgroundColor = UIColor.lightGray
            self.createAccountBtn.isEnabled = false
        }
    }

    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}
