//
//  GSNameGatewayViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 01.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class GSNameGatewayViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescLabel: UILabel!
    @IBOutlet weak var gatewayNameTextField: SetupTextField!
    public var gateways: [SPGateway]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.gatewayNameTextField.becomeFirstResponder()
        self.gatewayNameTextField.delegate = self
    }
    
    private func setGatewayName(name: String) {
        guard let gateway = self.gateways?.last else { return }
        SPManager.shared.updateGatewayName(name, of: gateway) { (error) in
            if let error = error {
                self.handle(error: error)
            }
            
            self.gateways?.last?.name = name
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Setup", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: String(describing: GSColorGatewayViewController.self)) as! GSColorGatewayViewController
                vc.gateways = self.gateways
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    private func handle(error: Error) {
        print("error \(error)")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let name = textField.text,
            name != "" {
            textField.resignFirstResponder()
            self.setGatewayName(name: name)
            return true
        }
        return false
    }
}
