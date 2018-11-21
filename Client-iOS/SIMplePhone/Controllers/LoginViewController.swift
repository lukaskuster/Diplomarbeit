//
//  LoginViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 10.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit
import SwiftMessages

@objc class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var usernameField: SetupTextField!
    @IBOutlet weak var passwordField: SetupTextField!
    @IBOutlet weak var loginBtn: SetupBoldButton!
    @IBOutlet weak var cloudEnvironmentSelectorBtn: UIButton!
    private var keyboardShowing: Bool = false
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
        // Do any additional setup after loading the view.
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleSwipe() {
        self.performSegue(withIdentifier: "forward", sender: self)
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    @IBAction func clickedLoginBtn(_ sender: SetupBoldButton) {
        self.view.endEditing(true)
        self.login()
    }
    
    func login() {
        if let username = usernameField.text,
            let password = passwordField.text {
            SwiftMessages.hideAll()
            if username == "" && password == "" {
                self.usernameField.becomeFirstResponder()
                return
            }
            
            if !isValidEmail(username) {
                self.errorNotification(title: "Invalid mail", body: "The mail you provided is not valid.", type: .error)
                self.usernameField.becomeFirstResponder()
                return
            }
            if password == "" {
                self.passwordField.becomeFirstResponder()
                return
            }
            
            let spinnerView = UIView.init(frame: self.view.bounds)
            spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
            let ai = UIActivityIndicatorView.init(style: .whiteLarge)
            ai.startAnimating()
            ai.center = spinnerView.center
            
            spinnerView.addSubview(ai)
            self.view.addSubview(spinnerView)
            
            
            SPManager.shared.loginUser(username: username, password: password, keychainEnvironment: self.selectedCloudEnvironment) { (success, error) in
                DispatchQueue.main.async {
                    spinnerView.removeFromSuperview()
                }
                if success {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let controller = storyboard.instantiateInitialViewController()
                        self.present(controller!, animated: false, completion: nil)
                    }
                }else{
                    self.showErrorUI(error!)
                }
            }
        }
    }
    
    func errorNotification(title: String, body: String, type: Theme) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(type)
        view.configureContent(title: title, body: body)
        view.button?.isHidden = true
        view.layoutMarginAdditions = UIEdgeInsets(top: 25, left: 20, bottom: 20, right: 20)
        SwiftMessages.show(view: view)
    }
    
    func showErrorUI(_ error: APIError) {
        DispatchQueue.main.async {
            switch error {
            case .wrongCredentials:
                self.errorNotification(title: "Wrong credentials", body: "The mail/password you provided is not correct. Check for typos.", type: .error)
            case .noNetworkConnection:
                self.errorNotification(title: "No network connection", body: "Seems like there is no connection to the internet.", type: .error)
            case .differentCloudUserId:
                let alert = UIAlertController(title: "iCloud Sharing unavailable", message: "Seems like your account is already associated with another iCloud user. To enable sharing with the account associated to this device first disable iCloud Sharing on a device associated with the other iCloud user (in Settings → Account). Or you can just sign in on this device without iCloud Sharing enabled.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Login without iCloud Sharing", style: .default, handler: { (action) in
                    self.environmentSelectorState = .disabled
                    self.login()
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            default:
                self.errorNotification(title: "Error", body: "\(error.localizedDescription)", type: .error)
                break
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case usernameField:
            checkUsernameInput()
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameField:
            passwordField.becomeFirstResponder()
        case passwordField:
            passwordField.resignFirstResponder()
        default:
            return false
        }
        return true
    }
    
    func checkUsernameInput() {
        let previousState = self.environmentSelectorState
        self.environmentSelectorState = .checking
        if let username = self.usernameField.text {
            SPManager.shared.checkUsernameWithCloud(username, completion: { (error) in
                if let error = error {
                    if error == .cloudAlreadyAssociatedWithDifferentAccount {
                        self.environmentSelectorState = .unavailableAccountAssociatedWithDifferentCloud
                    }
                }else{
                    if previousState == .unavailableAccountAssociatedWithDifferentCloud {
                        self.environmentSelectorState = .enabled
                    }else{
                        self.environmentSelectorState = previousState
                    }
                }
            })
        }else{
            self.environmentSelectorState = previousState
        }
    }
    
    func layoutEnvironmentSelector(_ state: EnvironmentSelectorState) {
        self.cloudEnvironmentSelectorBtn.isEnabled = true
        self.loginBtn.isEnabled = true
        self.loginBtn.backgroundColor = self.view.tintColor
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
            self.loginBtn.backgroundColor = UIColor.lightGray
            self.loginBtn.isEnabled = false
        }
    }
    
    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
}
