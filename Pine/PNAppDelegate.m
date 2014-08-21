//
//  PNAppDelegate.m
//  Pine
//
//  Created by soojin on 6/12/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNAppDelegate.h"
#import "SVProgressHUD.h"
#import "PNTabBarController.h"
#import <Crashlytics/Crashlytics.h>
#import "PNNotification.h"
#import "PNCoreDataStack.h"
#import "PNNotificationsViewController.h"

@implementation PNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //After All Third-party SDKs
    [Crashlytics startWithAPIKey:@"d5fd4fd405ab0d0363bdb2f3286eecef87d3b5a8"];
    
    //Reason for launching in options. (e.g. user reacted to push notification)
    NSLog(@"launchOptions : %@", launchOptions);
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    
    /*
    //Logging bit mask
    NSInteger theNumber = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    NSMutableString *str = [NSMutableString string];
    NSInteger numberCopy = theNumber; // so you won't change your original value
    for(NSInteger i = 0; i < 4 ; i++) {
        // Prepend "0" or "1", depending on the bit
        [str insertString:((numberCopy & 1) ? @"1" : @"0") atIndex:0];
        numberCopy >>= 1;
    }
    NSLog(@"enabled remote notification types: %@", str);
    */
    
    [self customizeUserInterface];

    PNTabBarController *rootTabBarVC = (PNTabBarController *)self.window.rootViewController;
    rootTabBarVC.delegate = self;
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Remote Notification : %@", userInfo);
    switch ([[UIApplication sharedApplication] applicationState]) {
        case UIApplicationStateActive:
        {
            NSLog(@"Application state Active");
            //User was in the app
            PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
            PNNotification *newNotification = [NSEntityDescription insertNewObjectForEntityForName:@"PNNotification" inManagedObjectContext:coreDataStack.managedObjectContext];
            newNotification.content = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
            newNotification.threadID = [NSNumber numberWithInt:[[userInfo objectForKey:@"thread_id"] intValue]];
            newNotification.date = [NSDate date];
            newNotification.isRead = [NSNumber numberWithBool:NO];
            [coreDataStack saveContext];
            
            PNTabBarController *rootTabBarVC = (PNTabBarController *)self.window.rootViewController;
            PNNotificationsViewController *notiVC = [rootTabBarVC.viewControllers objectAtIndex:3];
            NSInteger value = [notiVC.tabBarItem.badgeValue integerValue];
            notiVC.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", ++value];
            
            break;
        }
        case UIApplicationStateInactive:
            //Tapped on notification from outside
            NSLog(@"Application State Inactive");
            break;
        case UIApplicationStateBackground:
            NSLog(@"Application State Background");
            break;
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    //Send the token to server here
    NSLog(@"did register for remote notification");
    
    NSString *tokenString = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    tokenString = [tokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"token : %@", tokenString);
    
    [self registerUserForPush:tokenString];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"failed to register for remote notification error : %@", error);
}

- (void)registerUserForPush:(NSString *)deviceTokenString
{
    NSString *URLString = [NSString stringWithFormat:@"http://%@/users/register/push", kMainServerURL];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSMutableDictionary *content = [[NSMutableDictionary alloc] init];
    [content setObject:@"ios" forKey:@"device_type"];
    [content setObject:deviceTokenString forKey:@"push_id"];
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:content options:0 error:NULL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:contentData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //Completion Block
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            NSLog(@"register push to server success");
        }
    }];
    [task resume];

}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Helpers

- (void)customizeUserInterface {
    [SVProgressHUD setBackgroundColor:[UIColor blackColor]];
    /*
    //Customize Nav Bar
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.2 green:0.43 blue:0.9 alpha:1.0]];
    //[[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:.2 green:.4 blue:.9 alpha:1]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    //Customize the tab bar
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
     */
}

#pragma mark - UITabBarController delegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
//    NSLog(@"tab bar select VC : %@", viewController);
//    NSLog(@"selected VC : %@", tabBarController.selectedViewController);
    
    static UIViewController *previousController = nil;
    if (previousController == viewController) {
        // the same tab was tapped a second time
        NSLog(@"tapped twice");
        
        if ([viewController isEqual:[tabBarController.viewControllers objectAtIndex:3]]) {
            viewController.tabBarItem.badgeValue = nil;
        }
    }
    previousController = viewController;
}

@end
