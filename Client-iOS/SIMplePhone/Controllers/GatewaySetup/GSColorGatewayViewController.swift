//
//  GSColorGatewayViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 01.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import ChromaColorPicker
import SIMplePhoneKit

class GSColorGatewayViewController: UIViewController {
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescLabel: UILabel!
    @IBOutlet weak var colorSelectorView: UIView!
    @IBOutlet weak var continueBtn: SetupBoldButton!
    public var gateways: [SPGateway]?
    private var colorPicker: ChromaColorPicker?
    private var color: UIColor = .gray
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.layoutColorPicker()
    }

    func layoutColorPicker() {
        self.colorPicker?.removeFromSuperview()
        self.colorPicker = ChromaColorPicker(frame: CGRect(x: (self.colorSelectorView.frame.width-300)/2, y: 12.5, width: 300, height: 300))
        if let colorPicker = self.colorPicker {
            colorPicker.adjustToColor(self.color)
            colorPicker.padding = 5
            colorPicker.stroke = 10
            colorPicker.addButton.setTitle("", for: .normal)
            colorPicker.hexLabel.text = "Choose Color"
            colorPicker.hexLabel.textColor = .darkGray
            colorPicker.delegate = self
            colorPicker.layout()
            self.colorSelectorView.addSubview(colorPicker)
        }
    }
    
    private func setGatewayColor(color: UIColor) {
        guard let gateway = self.gateways?.last else { return }
        SPManager.shared.updateGatewayColor(color, of: gateway) { (success, error) in
            if let error = error {
                self.handle(error: error)
            }
            
            self.gateways?.last?.color = color
            DispatchQueue.main.async {
                // Check whether gateway needs to unlocked
                let pinVC = GatewaySIMPinViewController(gateway: gateway, config: .unlockGateway)
                let navController = UINavigationController(rootViewController: pinVC)
                self.present(navController, animated: true, completion: nil)
                
                let storyboard = UIStoryboard(name: "Setup", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: String(describing: GSSetupFinishedViewController.self)) as! GSSetupFinishedViewController
                vc.gateways = self.gateways
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    private func handle(error: Error) {
        print("error \(error)")
    }
    
    @IBAction func didTapContinueBtn(_ sender: SetupBoldButton) {
        if let colorPicker = self.colorPicker {
            self.color = colorPicker.currentColor
        }
        self.setGatewayColor(color: self.color)
    }
}

extension GSColorGatewayViewController: ChromaColorPickerDelegate {
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        self.color = color
    }
}
