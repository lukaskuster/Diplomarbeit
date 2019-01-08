//
//  WebRTCTestViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 22.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class WebRTCTestViewController: UIViewController {
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var logField: UITextView!
    
    var gateway: SPGateway?
    
    var sdpOfferString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gateway = SPGateway(withIMEI: NSUUID().uuidString, name: "Main-Gateway", phoneNumber: "00436648338455", colorString: "#000000", signalStrength: 0.0, firmwareVersion: "0.0.1", carrier: "spusu")
    }
    
    @IBAction func clickAnswer(_ sender: Any) {
        let number = SPNumber(withNumber: "00436641817908")
        
        SPPeerConnectionManager.shared.makeCall(number, with: self.gateway!) { (success, error) in
            if success {
                DispatchQueue.main.async {
                    self.lprint("action")
                }
            }else{
                DispatchQueue.main.async {
                    self.lprint("\(error!)")
                }
            }
        }
    }
    
    @IBAction func clickOffer(_ sender: Any) {
        SPPeerConnectionManager.shared.hangUpCall(on: self.gateway!) { (success, error) in
            if success {
                DispatchQueue.main.async {
                    self.logField.text = ""
                    self.lprint("ready for new call!")
                }
            }else{
                DispatchQueue.main.async {
                    self.lprint("\(error!)")
                }
            }
        }
    }
    
    func lprint(_ object: String) {
        if self.logField.text == "Log" {
            self.logField.text = ""
        }
        self.logField.text = "\(object)\n"+self.logField.text
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
