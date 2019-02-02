//
//  GatewaySetupViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 01.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class GatewaySetupViewController: UIViewController {
    var setupManager: BLESetupManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupManager = BLESetupManager()
        view.backgroundColor = .white
        
        setupManager?.getAvailableNetworks(completion: { networks, error in
            if let networks = networks {
                for network in networks {
                    print(network.ssid)
                }
            }
            print(error)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationController?.navigationItem.largeTitleDisplayMode = .never
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
