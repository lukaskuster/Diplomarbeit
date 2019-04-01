//
//  AppDelegate.m
//  SIMplePhone
//
//  Created by Lukas Kuster on 09.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <PKPushRegistryDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    SPManager *manager = [SPManager sharedInstance];
    [manager isAuthetificatedWithCompletion:^(BOOL loggedIn) {
        if(loggedIn){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self registerForPushNotifications];
                [self voipRegistration];
                [self updateBadges];
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                UIStoryboard *setupStoryboard = [UIStoryboard storyboardWithName:@"Setup" bundle:nil];
                LoginViewController *controller = (LoginViewController*)[setupStoryboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
                self.window.rootViewController = controller;
            });
        }
    }];
    
    application.applicationIconBadgeNumber = 0;
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    NSLog(@"openURL: %@", url);
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    if ([userActivity.interaction.intent isKindOfClass:[INStartAudioCallIntent class]]) {
        INPerson *person = [[(INStartAudioCallIntent*)userActivity.interaction.intent contacts] firstObject];
        NSString *phoneNumber = person.personHandle.value;
        [[SPDelegate sharedInstance] initiateCallWith:phoneNumber];
    }
    return YES;
}

- (void)voipRegistration {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    PKPushRegistry* voipRegistry = [[PKPushRegistry alloc] initWithQueue:mainQueue];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)pushRegistry:(nonnull PKPushRegistry *)registry didUpdatePushCredentials:(nonnull PKPushCredentials *)pushCredentials forType:(nonnull PKPushType)type {
    if(type == PKPushTypeVoIP) {
        [[SPManager sharedInstance] handleVoIPToken:pushCredentials.token];
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion {
    if(type == PKPushTypeVoIP) {
        [[SPManager sharedInstance] handleVoIPNotification:payload.dictionaryPayload];
    }
}

- (void)registerForPushNotifications {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (! error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
            NSLog( @"Push registration success." );
        }else{
            NSLog( @"Push registration FAILED" );
            NSLog( @"ERROR: %@ - %@", error.localizedFailureReason, error.localizedDescription );
            NSLog( @"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion );
        }
    }];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    SPManager *manager = [SPManager sharedInstance];
    [manager receivedPushDeviceToken:deviceToken completion:^(BOOL gotRevoked) {
        if(gotRevoked) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIStoryboard *setupStoryboard = [UIStoryboard storyboardWithName:@"Setup" bundle:nil];
                LoginViewController *controller = (LoginViewController*)[setupStoryboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
                self.window.rootViewController = controller;
            });
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    NSLog(@"%@", userInfo);
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound);
}

- (void)updateBadges {
    SPManager *manager = [SPManager sharedInstance];
    UITabBarController *tabController = (UITabBarController *)self.window.rootViewController;
    // Recent calls
    NSInteger recentCallsCount = [manager getCountOfUnseenRecentCalls];
    [[tabController.viewControllers objectAtIndex:0] tabBarItem].badgeValue = (recentCallsCount == 0) ? nil : [@(recentCallsCount) stringValue];
    
    // Voicemails
    NSInteger voicemailCount = [manager getCountOfUnheardVoicemails];
    [[tabController.viewControllers objectAtIndex:3] tabBarItem].badgeValue = (voicemailCount == 0) ? nil : [@(voicemailCount) stringValue];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
