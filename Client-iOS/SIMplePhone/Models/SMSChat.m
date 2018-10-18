//
//  SMSChat.m
//  SIMplePhone
//
//  Created by Lukas Kuster on 16.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

#import "SMSChat.h"

@implementation SMSChat

    - (id) initWithOtherParty:(CNContact*)otherParty
    {
        self = [super init];
        if (self) {
            self.otherParty = otherParty;
        }
        return self;
    }
    
@end
