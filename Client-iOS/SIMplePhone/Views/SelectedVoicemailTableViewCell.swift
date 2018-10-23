//
//  SelectedVoicemailTableViewCell.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 18.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import AVFoundation

class SelectedVoicemailTableViewCell: UITableViewCell, AVAudioPlayerDelegate {

    var parentVC: UITableViewController?
    var voicemail: Voicemail? {
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
        
        self.player?.delegate = self
        self.markVoicemailAsHeard()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func fillCellWithData() {
        if let data = self.voicemail {
            self.heardIndicatorView.isHidden = data.heard
            self.originPhoneNumberLabel.text = data.originPhoneNumber
            self.originGatewayLabel.text = "Gateway: \(data.gateway.name)"
            self.dateLabel.text = DateFormatter.localizedString(from: data.date, dateStyle: .long, timeStyle: .short)
            do {
                self.player = try AVAudioPlayer(contentsOf: data.audioFile)
                
                
                
                if let player = self.player {
                    let s: Int = Int(player.currentTime) % 60
                    let m: Int = Int(player.currentTime) / 60
                    self.playbackProgressLabel.text = String(format: "%0d:%02d", m, s)
                    self.playbackProgressSlider.value = Float(player.currentTime)
                    player.currentTime = TimeInterval(self.playbackProgressSlider.value)
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
            let voicemailFile = NSData(contentsOf: self.voicemail!.audioFile)
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
        self.voicemail?.markAsHeard()
        self.heardIndicatorView.isHidden = true
    }
    
}
