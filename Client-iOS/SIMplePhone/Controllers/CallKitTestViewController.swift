//
//  CallKitTestViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 30.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class CallKitTestViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let gateway = SPGateway(withIMEI: NSUUID().uuidString, name: "Main-Gateway", phoneNumber: "00436648338455", colorString: "#000000", signalStrength: 0.0, firmwareVersion: "0.0.1", carrier: "spusu")
        let number = SPNumber(withNumber: "00436641817909")
        let call = SPRecentCall(with: number, at: Date(), for: TimeInterval(exactly: 12.0)!, type: .outgoing, missed: false, gateway: gateway)
        
        SPManager.shared.addRecentCall(call)
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
