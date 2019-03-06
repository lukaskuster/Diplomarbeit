//
//  SelectedVoicemailTableViewCell.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 18.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import AVFoundation
import SIMplePhoneKit

class SelectedVoicemailTableViewCell: UITableViewCell, AVAudioPlayerDelegate {

    var parentVC: UITableViewController?
    var cellIndex: IndexPath?
    var voicemail: SPVoicemail? {
        didSet {
            self.fillCellWithData()
        }
    }
    var player: AVAudioPlayer?
    var displayLink: CADisplayLink?
    var playBtnLongPressDetected: Bool = false
    
    @IBOutlet weak var heardIndicatorView: UIView!
    @IBOutlet weak var originPhoneNumberLabel: UILabel!
    @IBOutlet weak var originGatewayLabel: UIBorderedLabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var playbackBackgroundView: UIView!
    @IBOutlet weak var playbackControlBtn: UIButton!
    @IBOutlet weak var playbackProgressLabel: UILabel!
    @IBOutlet weak var playbackRemainingLabel: UILabel!
    @IBOutlet weak var playbackProgressSlider: VoicemailProgressSlider!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.heardIndicatorView.backgroundColor = self.tintColor
        self.heardIndicatorView.layer.cornerRadius = self.heardIndicatorView.frame.size.width/2
        
        self.playbackBackgroundView.backgroundColor = UIColor.darkGray
        self.playbackBackgroundView.layer.cornerRadius = 12.0
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.unhearVoicemail))
        self.playbackControlBtn.addGestureRecognizer(longGesture)
    }
    
    public func resetAudioPlayer() {
        self.pausePlayer()
        player?.currentTime = TimeInterval(0.0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func fillCellWithData() {
        if let data = self.voicemail {
            self.heardIndicatorView.isHidden = data.heard
            if let contact = data.secondParty.contact {
                self.originPhoneNumberLabel.attributedText = contact.attributedFullName(fullyBold: true)
            }else{
                self.originPhoneNumberLabel.text = data.secondParty.prettyPhoneNumber()
            }
            if let gateway = data.gateway {
                self.originGatewayLabel.text = gateway.name ?? "Gateway"
                self.originGatewayLabel.backgroundColor = gateway.color ?? .lightGray
            }else{
                self.originGatewayLabel.text = "N/A"
                self.originGatewayLabel.backgroundColor = .lightGray
            }
            
            self.dateLabel.text = DateFormatter.localizedString(from: data.time, dateStyle: .long, timeStyle: .short)
            
            do {
                if let path = data.audioFilePath {
                    self.player = try AVAudioPlayer(contentsOf: path)
                }
                
                if let player = self.player {
                    player.delegate = self
                    displayLink = CADisplayLink(target: self, selector: #selector(self.updateSliderProgress))
                    displayLink?.add(to: .current, forMode: .common)
                }
            } catch let error {
                print("\(error)")
            }
        }
    }
    
    @IBAction func audioTrackControl(_ sender: UIButton) {
        if let player = player {
            if player.isPlaying {
                pausePlayer()
            }else{
                sender.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
                displayLink = CADisplayLink(target: self, selector: #selector(self.updateSliderProgress))
                displayLink?.add(to: .current, forMode: .common)
                player.play()
            }
        }
    }
    
    @objc func updateSliderProgress() {
        if let player = self.player {
            let progress = player.currentTime / player.duration
            self.timeUpdate()
            self.playbackProgressSlider.setValue(Float(progress), animated: false)
        }
    }
    
    func pausePlayer() {
        self.playbackControlBtn.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        displayLink?.invalidate()
        player?.pause()
    }
    
    func timeUpdate() {
        let s: Int = Int(player?.currentTime ?? 0) % 60
        let m: Int = Int(player?.currentTime ?? 0) / 60
        self.playbackProgressLabel.text = String(format: "%0d:%02d", m, s)
        
        let remainingMinutes = Int((player?.duration ?? 0)-(player?.currentTime ?? 0)) / 60
        let remainingSeconds = Int((player?.duration ?? 0)-(player?.currentTime ?? 0)) % 60
        self.playbackRemainingLabel.text = String(format: "-%0d:%02d", remainingMinutes, remainingSeconds)
    }
    
    @IBAction func scrub(_ sender: VoicemailProgressSlider) {
        self.pausePlayer()
        player?.currentTime = TimeInterval(Float(player?.duration ?? 0.0)*sender.value)
    }
    
    @IBAction func shareVoicemailBtn(_ sender: UIButton) {
        if let voicemailPath = self.voicemail?.audioFilePath {
            DispatchQueue.global(qos: .userInteractive).async {
                if let voicemailFile = NSData(contentsOf: voicemailPath) {
                    let activityViewController = UIActivityViewController(activityItems: [voicemailFile], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = sender
                    DispatchQueue.main.async {
                        self.parentVC?.present(activityViewController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func callBackBtn(_ sender: UIButton) {
        if let voicemail = self.voicemail {
            SPDelegate.shared.initiateCall(with: voicemail.secondParty)
        }
    }
    
    @IBAction func deleteVoicemailBtn(_ sender: UIButton) {
        if let parent = self.parentVC as? VoicemailTableViewController,
            let index = self.cellIndex {
            parent.deleteVoicemail(at: index)
        }
    }
    
    @objc func unhearVoicemail() {
        if !self.playBtnLongPressDetected {
            self.playBtnLongPressDetected = true
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            if let voicemail = self.voicemail {
                if voicemail.heard {
                    alert.addAction(UIAlertAction(title: "Mark Voicemail as unheard", style: .default, handler: { (action) in
                        if let voicemail = self.voicemail {
                            SPManager.shared.markVoicemailAsUnheard(voicemail)
                            self.heardIndicatorView.isHidden = false
                        }
                        self.playBtnLongPressDetected = false
                    }))
                }else{
                    alert.addAction(UIAlertAction(title: "Mark Voicemail as heard", style: .default, handler: { (action) in
                        if let voicemail = self.voicemail {
                            SPManager.shared.markVoicemailAsHeard(voicemail)
                            self.heardIndicatorView.isHidden = true
                        }
                        self.playBtnLongPressDetected = false
                    }))
                }
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                self.playBtnLongPressDetected = false
            }))
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.playbackControlBtn
                popoverController.sourceRect = self.playbackControlBtn.bounds
                popoverController.canOverlapSourceViewRect = false
                popoverController.permittedArrowDirections = [.left]
            }
            if let controller = UIApplication.shared.topMostViewController() {
                controller.present(alert, animated: true)
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.playbackControlBtn.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        self.markVoicemailAsHeard()
        self.displayLink?.invalidate()
    }
    
    func markVoicemailAsHeard() {
        if let voicemail = self.voicemail {
            if !voicemail.heard {
                SPManager.shared.markVoicemailAsHeard(voicemail)
                self.heardIndicatorView.isHidden = true
            }
        }
    }
    
}
