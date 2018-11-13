//
//  LoginViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 10.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

@objc class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var usernameField: SetupTextField!
    @IBOutlet weak var passwordField: SetupTextField!
    @IBOutlet weak var icloudLoginBtn: SetupBoldButton! {
        didSet {
            icloudLoginBtn.setImage(#imageLiteral(resourceName: "cloud-keychain"), for: .normal)
            icloudLoginBtn.adjustsImageWhenHighlighted = false
            icloudLoginBtn.imageView?.contentMode = .scaleAspectFit
            icloudLoginBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        if SPManager.shared.loginWithiCloudAvailable() {
            icloudLoginBtn.isHidden = false
        }
    }
    
    @objc func handleSwipe() {
        self.performSegue(withIdentifier: "forward", sender: self)
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    @IBAction func clickedLoginBtn(_ sender: SetupBoldButton) {
        self.view.endEditing(true)
        if let username = usernameField.text,
            let password = passwordField.text {
            SPManager.shared.loginUser(username: username, password: password) { (success, error) in
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
    
    @IBAction func clickedIcloudLoginBtn(_ sender: SetupBoldButton) {
        SPManager.shared.loginWithiCloud { (success, error) in
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
}
