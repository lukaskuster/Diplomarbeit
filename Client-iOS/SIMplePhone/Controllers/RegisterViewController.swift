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
            if password == repeatedPassword {
                let account = SPAccount(givenName: givenName, familyName: familyName, username: username, password: password)
                SPManager.shared.registerNewAccount(account) { (success, error) in
                    if success {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let controller = storyboard.instantiateInitialViewController()
                            self.present(controller!, animated: false, completion: nil)
                        }
                    }else{
                        print(error!)
                    }
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

}
