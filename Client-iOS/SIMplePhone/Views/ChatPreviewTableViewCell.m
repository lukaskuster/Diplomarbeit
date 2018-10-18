//
//  ChatPreviewTableViewCell.m
//  SIMplePhone
//
//  Created by Lukas Kuster on 11.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

#import "ChatPreviewTableViewCell.h"
#import "../Models/SMSChat.h"
#import <Contacts/Contacts.h>

@implementation ChatPreviewTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self populateCell];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
    
- (void)populateCell {
    if(self.chat.otherParty.imageDataAvailable) {
        self.userAvatar.image = [UIImage imageWithData:self.chat.otherParty.imageData];
    }else{
        // TODO: Add initials alternative
        self.userAvatar.backgroundColor = UIColor.purpleColor;
    }
    self.userNameLabel.attributedText = [CNContactFormatter attributedStringFromContact:self.chat.otherParty style:CNContactFormatterStyleFullName defaultAttributes:nil];
}

@end
