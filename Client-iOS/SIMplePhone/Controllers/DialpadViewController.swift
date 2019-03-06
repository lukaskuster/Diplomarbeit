//
//  DialpadViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 15.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit
import PhoneNumberKit
import SwiftMessages
import Contacts

class DialpadSegue: SwiftMessagesSegue {
    override public init(identifier: String?, source: UIViewController, destination: UIViewController) {
        super.init(identifier: identifier, source: source, destination: destination)
        self.configure(layout: .topCard)
        self.dimMode = .blur(style: .dark, alpha: 0.9, interactive: false)
        self.interactiveHide = false
        self.messageView.configureNoDropShadow()
        self.messageView.backgroundHeight = 250.0
        self.presentationStyle = .top
        self.containerView.cornerRadius = 20
    }
}

protocol DialpadViewControllerDelegate {
    func dialpadViewController(didRequestCall to: SPNumber)
    func dialpadViewController(didRequestNewContact with: SPNumber)
    func dialpadViewController(didRequestContactViewFor contact: CNContact)
}
class DialpadViewController: UIViewController {
    public var delegate: DialpadViewControllerDelegate?
    
    lazy var numberField: PhoneNumberTextField = {
        let numberField = PhoneNumberTextField()
        numberField.translatesAutoresizingMaskIntoConstraints = false
        numberField.keyboardType = .phonePad
        numberField.addTarget(self, action: #selector(self.textFieldDidChange(_:)),
                              for: UIControl.Event.editingChanged)
        numberField.adjustsFontSizeToFitWidth = true
        numberField.contentMode = .center
        numberField.textAlignment = .center
        numberField.contentHorizontalAlignment = .center
        numberField.tintColor = .lightGray
        numberField.font = UIFont.monospacedDigitSystemFont(ofSize: 33, weight: UIFont.Weight.regular)
        return numberField
    }()
    
    lazy var actionView: UIView = {
       let actionView = UIView()
        actionView.translatesAutoresizingMaskIntoConstraints = false
        actionView.backgroundColor = .lightGray
        return actionView
    }()
    
    lazy var actionBtn: UIButton = {
        let actionBtn = UIButton()
        actionBtn.isEnabled = false
        actionBtn.translatesAutoresizingMaskIntoConstraints = false
        actionBtn.setImage(#imageLiteral(resourceName: "call-phone-icon"), for: .normal)
        actionBtn.setAttributedTitle(NSAttributedString(string: "Call", attributes:
            [.font: UIFont.systemFont(ofSize: 23),
             .foregroundColor: UIColor.white]), for: .normal)
        actionBtn.setAttributedTitle(NSAttributedString(string: "Call", attributes:
            [.font: UIFont.systemFont(ofSize: 23),
             .foregroundColor: UIColor.lighterGray]), for: .disabled)
        actionBtn.imageView?.contentMode = .scaleAspectFit
        actionBtn.imageView?.tintColor = .white
        actionBtn.adjustsImageWhenHighlighted = false
        actionBtn.imageEdgeInsets = UIEdgeInsets(top: 20, left: -10, bottom: 20, right: 0)
        actionBtn.addTarget(self, action: #selector(didTapCallBtn), for: .touchUpInside)
        return actionBtn
    }()
    
    lazy var contactButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Add to contacts", for: .normal)
        button.setTitleColor(self.view.tintColor, for: .normal)
        button.addTarget(self, action: #selector(didTapContactBtn), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Dialpad"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissVc))
        
        self.view.backgroundColor = .white
        self.view.addSubview(numberField)
        self.view.addSubview(contactButton)
        self.view.addSubview(actionView)
        self.view.addSubview(actionBtn)
        
        let guide = self.view!
        numberField.leftAnchor.constraint(equalTo: guide.leftAnchor, constant: 15).isActive = true
        numberField.rightAnchor.constraint(equalTo: guide.rightAnchor, constant: -15).isActive = true
        numberField.topAnchor.constraint(equalTo: guide.topAnchor, constant: 50).isActive = true
        contactButton.leftAnchor.constraint(equalTo: guide.leftAnchor, constant: 15).isActive = true
        contactButton.rightAnchor.constraint(equalTo: guide.rightAnchor, constant: -15).isActive = true
        contactButton.topAnchor.constraint(equalTo: numberField.bottomAnchor, constant: 0).isActive = true
        contactButton.isHidden = true
        actionView.leftAnchor.constraint(equalTo: guide.leftAnchor).isActive = true
        actionView.rightAnchor.constraint(equalTo: guide.rightAnchor).isActive = true
        actionView.topAnchor.constraint(equalTo: contactButton.bottomAnchor, constant: 15).isActive = true
        actionView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        actionView.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
        
        actionBtn.leftAnchor.constraint(equalTo: actionView.leftAnchor, constant: 0).isActive = true
        actionBtn.rightAnchor.constraint(equalTo: actionView.rightAnchor, constant: 0).isActive = true
        actionBtn.topAnchor.constraint(equalTo: actionView.topAnchor, constant: 0).isActive = true
        actionBtn.bottomAnchor.constraint(equalTo: actionView.bottomAnchor, constant: 0).isActive = true
        
        numberField.becomeFirstResponder()
    }
    
    @objc func dismissVc() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapCallBtn() {
        if let text = self.numberField.text, text != "" {
            self.dismiss(animated: true) {
                let number = SPNumber(withNumber: text)
                self.delegate?.dialpadViewController(didRequestCall: number)
            }
        }
    }
    
    @objc func didTapContactBtn() {
        if let text = self.numberField.text, text != "" {
            let number = SPNumber(withNumber: text)
            self.dismiss(animated: true) {
                if let contact = number.contact {
                    self.delegate?.dialpadViewController(didRequestContactViewFor: contact)
                }else{
                    self.delegate?.dialpadViewController(didRequestNewContact: number)
                }
            }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text,
            text != "" {
            self.actionView.backgroundColor = .iosGreen
            self.actionBtn.isEnabled = true
            let number = SPNumber(withNumber: text)
            if let contact = number.contact {
                var contactString = contact.givenName+" "+contact.familyName
                contact.phoneNumbers.forEach { phoneNumber in
                    if number.isEqual(to: phoneNumber.value.stringValue),
                        let label = phoneNumber.label {
                        let localizedLabel = CNLabeledValue<NSString>.localizedString(forLabel: label)
                        contactString += " - "+localizedLabel
                    }
                }
                contactButton.isHidden = false
                contactButton.setTitle(contactString, for: .normal)
                contactButton.setTitleColor(.black, for: .normal)
            }else{
                contactButton.isHidden = false
                contactButton.setTitle("Add to contacts", for: .normal)
                contactButton.setTitleColor(self.view.tintColor, for: .normal)
            }
        }else{
            self.actionView.backgroundColor = .lightGray
            self.actionBtn.isEnabled = false
            self.contactButton.isHidden = true
        }
    }

}
