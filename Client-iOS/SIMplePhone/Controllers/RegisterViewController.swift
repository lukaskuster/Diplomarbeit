//
//  RegisterViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 13.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class RegisterViewController: UIViewController, UITextFieldDelegate, CloudEnvironmentButtonDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var givenNameField: SetupTextField!
    @IBOutlet weak var familyNameField: SetupTextField!
    @IBOutlet weak var usernameField: SetupTextField!
    @IBOutlet weak var passwordField: SetupTextField!
    @IBOutlet weak var repeatPasswordField: SetupTextField!
    @IBOutlet weak var createAccountBtn: SetupBoldButton!
    @IBOutlet weak var cloudEnvironmentButton: CloudEnvironmentButton!
    private var selectedCloudEnvironment: SPManager.SPKeychainEnvironment = .cloud
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        self.cloudEnvironmentButton.delegate = self
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
    
    func cloudEnvironmentDidChange(to newEnvironment: SPManager.SPKeychainEnvironment) {
        self.selectedCloudEnvironment = newEnvironment
    }
    
    func cloudEnvironmentRequestsAlert(_ alert: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }

    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}
