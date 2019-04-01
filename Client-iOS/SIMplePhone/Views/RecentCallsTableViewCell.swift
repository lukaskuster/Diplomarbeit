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
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var gatewayNameLabel: UIBorderedLabel!
    @IBOutlet weak var timeStampLabel: UILabel!
    @IBOutlet weak var callerGlyph: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func fillCellWithData() {
        if let call = call {
            if let contact = call.secondParty.contact {
                self.callerNameLabel.attributedText = contact.attributedFullName(fullyBold: true)
            }else{
                self.callerNameLabel.text = call.secondParty.prettyPhoneNumber()
            }
            
            self.callerNameLabel.textColor = call.missed ? UIColor.red : UIColor.black
            
            if let gateway = call.gateway {
                self.gatewayNameLabel.text = gateway.name ?? "Gateway"
                self.gatewayNameLabel.backgroundColor = gateway.color ?? .lightGray
            }else{
                self.gatewayNameLabel.text = "N/A"
                self.gatewayNameLabel.backgroundColor = .lightGray
            }
            
            self.durationLabel.isHidden = call.duration.isEqual(to: 0)
            self.durationLabel.text = "- Duration: \(formatDuration(call.duration))"
            
            self.callerGlyph.isHidden = (call.direction == .incoming)
            
            self.timeStampLabel.text = call.time.formatted
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 3
        return formatter.string(from: duration)!
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let gatewayColor = self.gatewayNameLabel.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        self.gatewayNameLabel.backgroundColor = gatewayColor
    }
}
