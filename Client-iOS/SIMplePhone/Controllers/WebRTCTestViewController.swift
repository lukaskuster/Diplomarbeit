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
    @IBOutlet weak var logField: UITextView!
    
    public var gateway: SPGateway?
    
    var sdpOfferString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func clickAnswer(_ sender: Any) {
        guard let gateway = self.gateway else { return }
        let number = SPNumber(withNumber: "00436641817908")
        SPManager.shared.makeCall(to: number, on: gateway) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.lprint("\(error)")
                }
                return
            }
            DispatchQueue.main.async {
                self.lprint("Call to \(number.prettyPhoneNumber()) initiated...")
            }
        }
    }
    
    @IBAction func clickOffer(_ sender: Any) {
        guard let gateway = self.gateway else { return }
        SPManager.shared.hangUpCall(via: gateway) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.lprint("\(error)")
                }
                return
            }
            DispatchQueue.main.async {
                self.lprint("Ready for new Call!")
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
