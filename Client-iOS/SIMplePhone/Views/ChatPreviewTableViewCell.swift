//
//  ChatPreviewTableViewCell.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 07.03.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class ChatPreviewTableViewCell: UITableViewCell {
    public var chat: SPChat? {
        didSet {
            self.fillCellWithData()
        }
    }
    @IBOutlet weak var avatarImageView: RoundedImageView!
    @IBOutlet weak var secondPartyNameLabel: UILabel!
    @IBOutlet weak var lastMessagePreviewLabel: UITextView!
    @IBOutlet weak var timeOfLastMessageLabel: UILabel!
    @IBOutlet weak var gatewayNameLabel: UIBorderedLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.avatarImageView.backgroundColor = .lightGray
        self.lastMessagePreviewLabel.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    private func fillCellWithData() {
        guard let chat = self.chat else { return }
        if let contact = chat.secondParty.contact {
            self.secondPartyNameLabel.attributedText = contact.attributedFullName(fullyBold: true)
            if contact.imageDataAvailable,
                let thumbnailData = contact.thumbnailImageData {
                self.avatarImageView.image = UIImage(data: thumbnailData)
            }
        }else{
            self.secondPartyNameLabel.text = chat.secondParty.prettyPhoneNumber()
        }
        
        if let gateway = chat.gateway {
            self.gatewayNameLabel.text = gateway.name ?? "Gateway"
            self.gatewayNameLabel.backgroundColor = gateway.color ?? .lightGray
        }else{
            self.gatewayNameLabel.text = "N/A"
            self.gatewayNameLabel.backgroundColor = .lightGray
        }
        
        self.setLastMessage()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let gatewayLabelPath = UIBezierPath(rect: self.lastMessagePreviewLabel.convert(self.gatewayNameLabel.bounds, from: self.gatewayNameLabel))
        self.lastMessagePreviewLabel.textContainer.exclusionPaths = [gatewayLabelPath]
        self.lastMessagePreviewLabel.textContainer.maximumNumberOfLines = 0
        self.lastMessagePreviewLabel.textContainer.lineBreakMode = .byTruncatingTail
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.avatarImageView.image = nil
        self.timeOfLastMessageLabel.isHidden = false
    }
    
    private func setLastMessage() {
        if let lastMessage = self.chat?.latestMessage() {
            self.lastMessagePreviewLabel.text = lastMessage.text
            self.timeOfLastMessageLabel.text = lastMessage.time.formatted
        }else{
            self.lastMessagePreviewLabel.text = "No messages"
            self.timeOfLastMessageLabel.isHidden = true
        }
    }
}
