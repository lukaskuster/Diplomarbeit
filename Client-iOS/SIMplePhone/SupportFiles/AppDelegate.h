//
//  AppDelegate.h
//  SIMplePhone
//
//  Created by Lukas Kuster on 09.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <PushKit/PushKit.h>
#import <SIMplePhoneKit/SIMplePhoneKit.h>
#import "SIMplePhone-Swift.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,UNUserNotificationCenterDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

