//
//  SMSChat.h
//  SIMplePhone
//
//  Created by Lukas Kuster on 16.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Contacts/Contacts.h>

@interface SMSChat : NSObject
    @property (retain) CNContact* otherParty;
    
    - (id) initWithOtherParty:(CNContact *)otherParty;
@end
