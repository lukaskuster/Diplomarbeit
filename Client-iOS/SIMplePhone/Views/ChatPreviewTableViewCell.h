//
//  ChatPreviewTableViewCell.h
//  SIMplePhone
//
//  Created by Lukas Kuster on 11.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMSChat.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatPreviewTableViewCell : UITableViewCell
    @property (strong) SMSChat *chat;
    @property (weak, nonatomic) IBOutlet UIImageView *userAvatar;
    @property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
    @property (weak, nonatomic) IBOutlet UILabel *latestChatLabel;
    @property (weak, nonatomic) IBOutlet UILabel *timeInfoLabel;
    
@end

NS_ASSUME_NONNULL_END
