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
    @IBOutlet weak var originGatewayLabel: UIBorderedLabel!
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
            self.dateLabel.text = formatDate(data.time)
            
            let s: Int = Int(data.duration) % 60
            let m: Int = Int(data.duration) / 60
            self.durationLabel.text = String(format: "%0d:%02d", m, s)
        }
    }

    func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        }else{
            let day = Calendar.current.startOfDay(for: date)
            if day.timeIntervalSinceNow >= -(60*60*24*6) { // last six days in seconds
                // Display Weekday
                let f = DateFormatter()
                f.locale = Locale.autoupdatingCurrent
                let weekday = f.weekdaySymbols[Calendar.current.component(.weekday, from: day)]
                return weekday
            }else{
                // Display Date
                return DateFormatter.localizedString(from: day, dateStyle: .short, timeStyle: .none)
            }
        }
    }
}
