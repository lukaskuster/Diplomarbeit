//
//  SettingsGatewayChangeSIMPinViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 10.01.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class SettingsGatewayChangeSIMPinViewController: UIViewController {
    private let gateway: SPGateway
    private var loadingIndicator: UIView?
    private let pinField = KAPinField()
    private enum Step {
        case enterCurrentPIN
        case enterCurrentPIN2ndTry
        case enterCurrentPINLastTry
        case enterNewPIN
        case repeatNewPIN
        case repeatNewPINWrong
        case loading
        case SIMlocked
    }
    private var currentStep: Step = .enterCurrentPIN {
        didSet {
            self.layoutInformation()
        }
    }
    
    lazy var stepLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 34.0)
        return label
    }()
    
    lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    lazy var triesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Change SIM Pin"
        self.currentStep = .enterCurrentPIN
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissVC))
        
        view = UIView()
        view.backgroundColor = .tableViewBackground
        
        pinField.ka_delegate = self
        pinField.ka_token = "●"
        pinField.ka_numberOfCharacters = 4
        pinField.ka_tokenColor = UIColor.black.withAlphaComponent(0.3)
        pinField.ka_textColor = .black
        pinField.ka_font = .menlo(40)
        pinField.ka_kerning = 20
        
        _ = pinField.becomeFirstResponder()
        
        self.view.addSubview(pinField)
        self.view.addSubview(infoLabel)
        self.view.addSubview(stepLabel)
        self.view.addSubview(triesLabel)
        
        pinField.translatesAutoresizingMaskIntoConstraints = false
        pinField.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9).isActive = true
        pinField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        pinField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        pinField.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -40).isActive = true
        
        infoLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 15).isActive = true
        infoLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -15).isActive = true
        infoLabel.bottomAnchor.constraint(equalTo: pinField.topAnchor, constant: -65).isActive = true
        
        stepLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 15).isActive = true
        stepLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -15).isActive = true
        stepLabel.bottomAnchor.constraint(equalTo: infoLabel.topAnchor, constant: -12.5).isActive = true
        
        triesLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 15).isActive = true
        triesLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -15).isActive = true
        triesLabel.bottomAnchor.constraint(equalTo: pinField.bottomAnchor, constant: 40).isActive = true
    }
    
    func layoutInformation() {
        self.hideSpinner()
        switch self.currentStep {
        case .enterCurrentPIN:
            stepLabel.text = "Step 1"
            infoLabel.text = "Please enter your current PIN code"
            triesLabel.isHidden = true
        case .enterCurrentPIN2ndTry:
            triesLabel.isHidden = false
            triesLabel.text = "Two attempts left"
            triesLabel.textColor = .darkGray
        case .enterCurrentPINLastTry:
            triesLabel.text = "Only one attempt left"
            triesLabel.textColor = .red
        case .enterNewPIN:
            stepLabel.text = "Step 2"
            infoLabel.text = "Please enter your new PIN code"
        case .repeatNewPIN:
            stepLabel.text = "Step 3"
            infoLabel.text = "Please repeat your new PIN code"
            self.navigationItem.leftBarButtonItem?.isEnabled = false
        case .repeatNewPINWrong:
            stepLabel.text = "Step 3"
            infoLabel.text = "Please repeat your new PIN code"
            triesLabel.text = "The PINs you entered were not the same"
            triesLabel.textColor = .orange
            self.navigationItem.leftBarButtonItem?.isEnabled = true
        case .loading:
            self.showSpinner()
        case .SIMlocked:
            stepLabel.text = "SIM card locked"
            infoLabel.text = "Please contact your provider or try to use your SIM card in a regular phone to enter the PUK.\nSadly we do not support this function yet."
            pinField.isHidden = true
            pinField.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
    }
    
    init(gateway: SPGateway) {
        self.gateway = gateway
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func dismissVC() {
        self.navigationController?.popViewController(animated: false)
    }
}

extension SettingsGatewayChangeSIMPinViewController {
    func showSpinner() {
        self.loadingIndicator = UIView(frame: self.view.bounds)
        self.loadingIndicator?.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView(style: .whiteLarge)
        ai.startAnimating()
        ai.center = self.loadingIndicator!.center
        
        DispatchQueue.main.async {
            _ = self.pinField.resignFirstResponder()
            self.loadingIndicator?.addSubview(ai)
            self.navigationController?.tabBarController?.view.addSubview(self.loadingIndicator!)
        }
    }
    
    func hideSpinner() {
        DispatchQueue.main.async {
            self.loadingIndicator?.removeFromSuperview()
            if self.currentStep != .SIMlocked {
                _ = self.pinField.becomeFirstResponder()
            }
        }
    }
}

extension SettingsGatewayChangeSIMPinViewController: KAPinFieldDelegate {
    func ka_pinField(_ field: KAPinField, didFinishWith code: String) {
        // To-Do: Implement logic
        self.currentStep = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.currentStep = .SIMlocked
            field.ka_animateFailure() {
                field.ka_text = ""
            }
        }
    }
}
