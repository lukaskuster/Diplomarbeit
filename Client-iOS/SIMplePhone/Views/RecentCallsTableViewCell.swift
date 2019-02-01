//
//  RecentCallsTableViewCell.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 01.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit
import PhoneNumberKit

class RecentCallsTableViewCell: UITableViewCell {

    var call: SPRecentCall? {
        didSet {
            self.fillCellWithData()
        }
    }
    @IBOutlet weak var callerNameLabel: UILabel!
    @IBOutlet weak var callerSubtitleLabel: UILabel!
    @IBOutlet weak var timeStampLabel: UILabel!
    @IBOutlet weak var callerGlyph: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func fillCellWithData() {
        if let call = call {
            if let contact = call.secondParty.contact {
                self.callerNameLabel.text = contact.givenName+" "+contact.familyName
            }else{
                self.callerNameLabel.text = call.secondParty.prettyPhoneNumber()
            }
            
            self.callerNameLabel.textColor = call.missed ? UIColor.red : UIColor.black
            
            self.callerSubtitleLabel.text = (call.gateway?.name ?? "No Gateway")+" Duration: \(call.duration.description)"
            
            self.callerGlyph.isHidden = (call.direction == .outgoing)
            
            self.timeStampLabel.text = DateFormatter.localizedString(from: call.time, dateStyle: .none, timeStyle: .short)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
