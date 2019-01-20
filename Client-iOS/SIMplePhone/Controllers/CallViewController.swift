//
//  CallViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 19.01.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit
import SwiftMessages

class CallViewController: UIViewController {
    private static var vcinstance: CallViewController?
    public var receiver: SPNumber?
    public var gateway: SPGateway?
    private var mSelf: CallViewController?
    
    @IBOutlet weak var receiverNameLabel: UILabel!
    @IBOutlet weak var receiverImageView: SPCallReceiverImageView!
    @IBOutlet weak var gatewayColorIndicatorView: UIView!
    @IBOutlet weak var gatewayNameAndTimeLabel: UILabel!
    
    @IBOutlet weak var muteBtn: UIButton!
    @IBOutlet weak var muteBtnDescLabel: UILabel!
    @IBOutlet weak var DTMFKeypadBtn: UIButton!
    @IBOutlet weak var DTMFKeypadBtnDescLabel: UILabel!
    @IBOutlet weak var speakerPhoneBtn: UIButton!
    @IBOutlet weak var speakerPhoneBtnDescLabel: UILabel!
    
    @IBOutlet weak var hangUpCallBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mSelf = self

        // Do any additional setup after loading the view.
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.backgroundColor = .clear
        self.view.insertSubview(blurEffectView, at: 0)
        self.fillData()
        
        UIDevice.current.isProximityMonitoringEnabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        UIDevice.current.isProximityMonitoringEnabled = false
        super.viewDidDisappear(animated)
    }
    
    func fillData() {
        guard let receiver = receiver,
              let gateway = gateway else { return }
        if let contact = receiver.contact {
            receiverNameLabel.text = contact.givenName+" "+contact.familyName
            if contact.imageDataAvailable,
               let imageData = contact.thumbnailImageData {
                receiverImageView.image = UIImage(data: imageData)
            }else{
                receiverImageView.isHidden = true
            }
        }else{
            receiverNameLabel.text = receiver.prettyPhoneNumber()
            receiverImageView.isHidden = true
        }
        gatewayColorIndicatorView.backgroundColor = gateway.color ?? .lightGray
        gatewayNameAndTimeLabel.text = (gateway.name ?? "Gateway")+" - 00:00"
    }
    
    override func viewDidLayoutSubviews() {
        self.gatewayColorIndicatorView.layer.cornerRadius = 5.0
        self.receiverImageView.layer.cornerRadius = self.receiverImageView.frame.width / 2
        
        self.muteBtn.backgroundColor = .gray
        self.muteBtn.layer.cornerRadius = self.DTMFKeypadBtn.frame.width / 2
        self.muteBtnDescLabel.text = "Mute"
        
        self.speakerPhoneBtn.backgroundColor = .gray
        self.speakerPhoneBtn.layer.cornerRadius = self.DTMFKeypadBtn.frame.width / 2
        self.speakerPhoneBtnDescLabel.text = "Speaker"
        
        self.DTMFKeypadBtn.backgroundColor = .gray
        self.DTMFKeypadBtn.layer.cornerRadius = self.DTMFKeypadBtn.frame.width / 2
        self.DTMFKeypadBtnDescLabel.text = "Keypad"
        
        self.hangUpCallBtn.backgroundColor = .red
        self.hangUpCallBtn.layer.cornerRadius = self.hangUpCallBtn.frame.width / 2
    }
    
    @IBAction func didTapMuteBtn(_ sender: UIButton) {
        
    }
    
    @IBAction func didTapDTMFKeypadBtn(_ sender: UIButton) {
        
    }
    
    @IBAction func didTapSpeakerPhoneBtn(_ sender: UIButton) {

    }
    
    @IBAction func didTapHangUpCallBtn(_ sender: UIButton) {
        guard let gateway = gateway else { return }
        SPManager.shared.hangUpCall(via: gateway) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.close(error)
                }
                return
            }
            DispatchQueue.main.async {
                self.close()
            }
        }
    }
    
}

extension CallViewController {
    public func show() {
        let appDelegate = UIApplication.shared.delegate!
        appDelegate.window?!.addSubview((self.view)!)
        self.view.frame = (appDelegate.window?!.bounds)!
        self.view.alpha = 0
//        controller.view.backgroundColor = .clear
        self.view.isHidden = true
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .transitionCrossDissolve, animations: {
            self.view.isHidden = false
            self.view.alpha = 1
        }, completion: nil)
    }
    
    public func connected() {
        print("connected")
    }
    
    public func close(_ error: Error) {
        self.close()
        var config = SwiftMessages.Config()
        config.presentationContext = .window(windowLevel: .statusBar)
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.error)
        view.configureContent(title: "Error while trying to make call", body: "\(error)")
        view.button?.isHidden = true
        view.layoutMarginAdditions = UIEdgeInsets(top: 25, left: 20, bottom: 20, right: 20)
        SwiftMessages.show(config: config, view: view)
    }
    
    public func close() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .transitionCrossDissolve, animations: {
            self.view.alpha = 0
        }) { _ in
            self.view.removeFromSuperview()
        }
    }
}

class SPCallReceiverImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentMode = .scaleAspectFill
        let radius: CGFloat = self.bounds.size.width / 2.0
        self.layer.cornerRadius = radius
    }
}
