//
//  SelectedVoicemailTableViewCell.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 18.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit

class SelectedVoicemailTableViewCell: UITableViewCell {

    var voicemail: Voicemail? {
        didSet {
            self.fillCellWithData()
        }
    }
    
    @IBOutlet weak var heardIndicatorView: UIView!
    @IBOutlet weak var originPhoneNumberLabel: UILabel!
    @IBOutlet weak var originGatewayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var playbackBackgroundView: UIView!
    @IBOutlet weak var playbackControlBtn: UIButton!
    @IBOutlet weak var playbackProgressLabel: UILabel!
    @IBOutlet weak var playbackRemainingLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.heardIndicatorView.backgroundColor = self.tintColor
        self.heardIndicatorView.layer.cornerRadius = self.heardIndicatorView.frame.size.width/2
        
        self.playbackBackgroundView.backgroundColor = UIColor.lightGray
        self.playbackBackgroundView.layer.cornerRadius = 12.0
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
            
        }
    }
    
}
