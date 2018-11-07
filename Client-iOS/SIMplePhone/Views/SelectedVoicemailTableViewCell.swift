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
    var voicemail: SPVoicemail? {
        didSet {
            self.fillCellWithData()
        }
    }
    var player: AVAudioPlayer?
    
    @IBOutlet weak var heardIndicatorView: UIView!
    @IBOutlet weak var originPhoneNumberLabel: UILabel!
    @IBOutlet weak var originGatewayLabel: UILabel!
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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func fillCellWithData() {
        if let data = self.voicemail {
            self.heardIndicatorView.isHidden = data.heard
            if let contact = data.secondParty.contact {
                if contact.givenName != "" && contact.familyName != "" {
                    self.originPhoneNumberLabel.text = contact.givenName+" "+contact.familyName
                }else{
                    self.originPhoneNumberLabel.text = contact.organizationName
                }
            }else{
                self.originPhoneNumberLabel.text = data.secondParty.prettyPhoneNumber()
            }
            self.originGatewayLabel.text = "Gateway: \(String(describing: data.gateway?.name))"
            self.dateLabel.text = DateFormatter.localizedString(from: data.time, dateStyle: .long, timeStyle: .short)
            
            do {
                let path = data.getAudioFilePath()
                print(path)
                
                self.player = try AVAudioPlayer(contentsOf: path)
                
                if let player = self.player {
                    player.delegate = self
                    
                    let s: Int = Int(player.currentTime) % 60
                    let m: Int = Int(player.currentTime) / 60
                    self.playbackProgressLabel.text = String(format: "%0d:%02d", m, s)
                    
                    
                    let remainingMinutes = Int(player.duration-player.currentTime) / 60
                    let remainingSeconds = Int(player.duration-player.currentTime) % 60
                    self.playbackRemainingLabel.text = String(format: "-%0d:%02d", remainingMinutes, remainingSeconds)
                }else{
                    print("error")
                }
            } catch let error {
                print(error.localizedDescription)
            }
            if let player = self.player {
                self.playbackProgressSlider.minimumValue = 0
                self.playbackProgressSlider.maximumValue = Float(player.duration)
                self.playbackProgressSlider.isContinuous = true
                self.playbackProgressSlider.value = Float(player.currentTime)
                
            }
        }
    }
    
    @IBAction func audioTrackControl(_ sender: UIButton) {
        if let player = player {
            if player.isPlaying {
                sender.setImage(#imageLiteral(resourceName: "play"), for: .normal)
                player.pause()
            }else{
                sender.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
                player.play()
            }
        }
    }
    
    @IBAction func shareVoicemailBtn(_ sender: UIButton) {
        DispatchQueue.global(qos: .userInteractive).async {
            let voicemailFile = NSData(contentsOf: (self.voicemail?.getAudioFilePath())!)
            let activityViewController = UIActivityViewController(activityItems: [voicemailFile!], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = sender
            
            DispatchQueue.main.async {
                self.parentVC?.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.playbackControlBtn.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        self.markVoicemailAsHeard()
    }
    
    func markVoicemailAsHeard() {
        SPManager.shared.markVoicemailAsHeard(self.voicemail!)
        self.heardIndicatorView.isHidden = true
    }
    
}
