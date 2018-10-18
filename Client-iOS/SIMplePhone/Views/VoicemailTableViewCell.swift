//
//  VoicemailTableViewCell.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 18.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import Contacts

class VoicemailTableViewCell: UITableViewCell {

    var voicemail: Voicemail? {
        didSet {
            self.fillCellWithData()
        }
    }
    
    @IBOutlet weak var heardIndicatorLabel: UIView!
    @IBOutlet weak var originPhoneNumberLabel: UILabel!
    @IBOutlet weak var originGatewayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.heardIndicatorLabel.backgroundColor = self.tintColor
        self.heardIndicatorLabel.layer.cornerRadius = self.heardIndicatorLabel.frame.size.width/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        if selected {
            self.accessoryType = .none
        }else{
            self.accessoryType = .detailButton
        }
    }
    
    func fillCellWithData() {
        if let data = self.voicemail {
            self.heardIndicatorLabel.isHidden = data.heard
            self.originPhoneNumberLabel.text = data.originPhoneNumber
            self.originGatewayLabel.text = "Gateway: \(data.gateway.name)"
            self.dateLabel.text = DateFormatter.localizedString(from: data.date, dateStyle: .none, timeStyle: .short)
            if let duration = data.duration {
                let s: Int = Int(duration) % 60
                let m: Int = Int(duration) / 60
                self.durationLabel.text = String(format: "%0d:%02d", m, s)
            }
            
        }
    }

}
