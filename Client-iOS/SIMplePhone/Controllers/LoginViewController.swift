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

@objc class LoginViewController: UIViewController, UITextFieldDelegate, CloudEnvironmentButtonDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var usernameField: SetupTextField!
    @IBOutlet weak var passwordField: SetupTextField!
    @IBOutlet weak var loginBtn: SetupBoldButton!
    @IBOutlet weak var cloudEnvironmentButton: CloudEnvironmentButton!
    private var keyboardShowing: Bool = false
    private var selectedCloudEnvironment: SPManager.SPKeychainEnvironment = .cloud
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        self.cloudEnvironmentButton.delegate = self
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
                    self.selectedCloudEnvironment = .local
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
    
    func cloudEnvironmentDidChange(to newEnvironment: SPManager.SPKeychainEnvironment) {
        self.selectedCloudEnvironment = newEnvironment
    }
    
    func cloudEnvironmentRequestsAlert(_ alert: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case usernameField:
            self.cloudEnvironmentButton.updateForUsername(usernameField.text)
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
    
    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
}
