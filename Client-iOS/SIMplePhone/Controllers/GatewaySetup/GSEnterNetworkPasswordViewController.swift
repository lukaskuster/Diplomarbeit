//
//  GSEnterNetworkPasswordViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 01.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

protocol GSEnterNetworkPasswordDelegate {
    func enterPasswordViewController(didEnterPassword password: String, for network: SPNetwork)
}

class GSEnterNetworkPasswordViewController: UIViewController, UITextFieldDelegate {
    public var delegate: GSEnterNetworkPasswordDelegate?
    public var network: SPNetwork? {
        didSet {
            self.fillVCWithData()
        }
    }
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescLabel: UILabel!
    @IBOutlet weak var networkPasswordTextField: SetupTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.networkPasswordTextField.becomeFirstResponder()
        self.networkPasswordTextField.delegate = self
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    }
    
    func fillVCWithData() {
        if let network = self.network {
            self.title = "Connect to \(network.ssid)"
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let password = textField.text,
            let network = self.network,
            password != "" {
            textField.resignFirstResponder()
            self.dismiss(animated: true) {
                self.delegate?.enterPasswordViewController(didEnterPassword: password, for: network)
            }
            return true
        }
        return false
    }
    
    @objc func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
}
