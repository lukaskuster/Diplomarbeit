//
//  GSSearchingForGatewayViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 01.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SwiftyBluetooth
import Pulsator
import SIMplePhoneKit

class GSSearchingForGatewayViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescLabel: UILabel!
    @IBOutlet weak var loadingIndicatorView: UIView!
    @IBOutlet weak var cancelBtn: SetupBoldButton!
    public var gateways: [SPGateway]?
    private let pulsator = Pulsator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pulsator.radius = 30
        pulsator.numPulse = 4
        pulsator.radius = self.loadingIndicatorView.frame.height/2
        pulsator.animationDuration = 3
        self.view.layer.insertSublayer(pulsator, above: self.loadingIndicatorView.layer)
        pulsator.start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.foundGateway(nil)
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.layer.layoutIfNeeded()
        pulsator.position = self.loadingIndicatorView.layer.position
    }
    
    private func foundGateway(_ gateway: Peripheral?) {
        let storyboard = UIStoryboard(name: "Setup", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: GSSelectNetworkViewController.self)) as! GSSelectNetworkViewController
        vc.bleGateway = gateway
        vc.gateways = self.gateways
        self.navigationController?.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FancyBounceVCAnimation()
    }
    
    @IBAction func didTapCancelBtn(_ sender: SetupBoldButton) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
