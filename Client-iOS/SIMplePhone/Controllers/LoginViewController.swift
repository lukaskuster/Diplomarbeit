//
//  LoginViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 10.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

@objc class LoginViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func clickedLoginBtn(_ sender: UIButton) {
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
    
    @IBAction func clickedRegisterAccount(_ sender: UIButton) {
        
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
