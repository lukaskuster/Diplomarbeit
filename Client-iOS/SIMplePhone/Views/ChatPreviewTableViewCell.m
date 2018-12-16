//
//  ChatPreviewTableViewCell.m
//  SIMplePhone
//
//  Created by Lukas Kuster on 11.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

#import "ChatPreviewTableViewCell.h"
#import <Contacts/Contacts.h>

@implementation ChatPreviewTableViewCell

@synthesize chat = _chat;

- (void)setChat:(SPChat *)chat {
    _chat = chat;
    [self populateCell];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.userAvatar.layer.cornerRadius = self.userAvatar.frame.size.width/2;
}
    
- (void)populateCell {
    if(self.chat.secondParty.contact) {
        if([[self.chat.secondParty.contact familyName] length] > 0) {
            self.userNameLabel.text = [NSString stringWithFormat:@"%@ %@", [self.chat.secondParty.contact givenName], [self.chat.secondParty.contact familyName]];
        }else{
            self.userNameLabel.text = [self.chat.secondParty.contact organizationName];
        }
        
        if([self.chat.secondParty.contact imageDataAvailable]) {
            self.userAvatar.image = [UIImage imageWithData:[self.chat.secondParty.contact thumbnailImageData]];
        }else{
            self.userAvatar.backgroundColor = UIColor.brownColor;
        }
        self.userAvatar.layer.masksToBounds = YES;
    }else{
        self.userNameLabel.text = [self.chat.secondParty prettyPhoneNumber];
    }
    self.latestChatLabel.text = [NSString stringWithFormat:@"ID: %@", self.chat.id];
    
    SPMessage *message = [self.chat latestMessage];
    if(message) {
        self.latestChatLabel.text = message.text;
        self.timeInfoLabel.text = [NSDateFormatter localizedStringFromDate:message.time dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    }
}

@end
