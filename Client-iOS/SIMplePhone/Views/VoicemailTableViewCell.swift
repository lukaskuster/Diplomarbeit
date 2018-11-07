//
//  VoicemailTableViewCell.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 18.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import Contacts
import SIMplePhoneKit

class VoicemailTableViewCell: UITableViewCell {
    var voicemail: SPVoicemail? {
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
    }
    
    func fillCellWithData() {
        if let data = self.voicemail {
            self.heardIndicatorLabel.isHidden = data.heard
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
            self.dateLabel.text = DateFormatter.localizedString(from: data.time, dateStyle: .none, timeStyle: .short)
            let s: Int = Int(data.duration) % 60
            let m: Int = Int(data.duration) / 60
            self.durationLabel.text = String(format: "%0d:%02d", m, s)
        }
    }

}
