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
#import "PNFeedContentViewController.h"
#import "PNLoginViewController.h"

static NSString *const kGaPropertyId = @"UA-54362622-1";
static NSString *const kTrackingPreferenceKey = @"allowTracking";
static BOOL const kGaDryRun = YES; //YES when debugging or testing
static int const kGaDispatchPeriod = 30;

@implementation PNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initializeGoogleAnalytics];
    
    //Start Crashlytics after all third-party SDKs
    [Crashlytics startWithAPIKey:@"d5fd4fd405ab0d0363bdb2f3286eecef87d3b5a8"];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] != nil) {
        //user tapped on push notification when the application was not running
        NSDictionary *payload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        [self saveNotificaionFromPayload:payload andIncrementBadgeValue:YES];
    }
    
    [self customizeUserInterface];
    
    /* new login flow
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    //self.window.rootViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"AuthNavigationController"];
    self.window.rootViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PNTabBarController"];
    [self.window makeKeyAndVisible];
    */
    
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    NSString *phoneNumber = [[NSUserDefaults standardUserDefaults] stringForKey:@"user_phonenumber"];
    if (phoneNumber == nil) {
        NSLog(@"instantiate PNLoginViewCon");
        self.window.rootViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PNLoginViewController"];
        // <--view is loaded at this time-->
        [self.window makeKeyAndVisible];
        return YES;
    }
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", kMainServerURL]]];
    if (cookies.count > 0) {
        NSHTTPCookie *cookie = [cookies firstObject];
        if ([self cookieExpired:cookie]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
            dispatch_sync(dispatch_queue_create("cookie expired, sign in", NULL), ^{
                //Register
                NSString *urlString = [NSString stringWithFormat:@"http://%@/users/login", kMainServerURL];
                NSURL *url = [NSURL URLWithString:urlString];
                NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
                [urlRequest setHTTPMethod:@"POST"];
                [urlRequest setURL:url];
                [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
                
                NSError *error;
                NSDictionary *contentDic = @{@"username": phoneNumber,
                                             @"password" : phoneNumber};
                NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDic options:0 error:&error];
                [urlRequest setHTTPBody:contentData];
                
                NSURLSession *session = [NSURLSession sharedSession];
                NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    NSError *JSONerror;
                    NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
                    if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
                        //SUCCESS
                        NSHTTPCookie *cookie = [[NSHTTPCookie cookiesWithResponseHeaderFields:[httpResponse allHeaderFields] forURL:url] objectAtIndex:0];
                        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
                        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                    } else {
                        //FAIL
                        NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
                        NSLog(@"Error : %@", error);
                        //NOT PINE!!!
                    }
                }];
                [task resume];
            });
        }
        
        self.window.rootViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PNTabBarController"];
        // <--view is loaded at this time-->
        [self.window makeKeyAndVisible];
        return YES;
    } else {
        self.window.rootViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PNLoginViewController"];
        // <--view is loaded at this time-->
        [self.window makeKeyAndVisible];
        return YES;
    }
    
    /*
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"userinfo" message:[NSString stringWithFormat:@"%@", launchOptions] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];
    */
    //UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"launchOptions" message:[NSString stringWithFormat:@"%@", launchOptions] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    //[alertView show];
    
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
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Remote Notification : %@", userInfo);
    switch ([[UIApplication sharedApplication] applicationState]) {
        case UIApplicationStateActive:
        {
            //User was in the app
            [self saveNotificaionFromPayload:userInfo andIncrementBadgeValue:YES];
            break;
        }
        case UIApplicationStateInactive:
        {
            //Tapped on notification from outside and came in
            //Direct user to related thread view
            NSLog(@"Application State Inactive");
            [self saveNotificaionFromPayload:userInfo andIncrementBadgeValue:YES];
            break;
        }
        case UIApplicationStateBackground:
            NSLog(@"Application State Background");
            break;
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    //Send the token to server here
    NSString *tokenString = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    tokenString = [tokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"token : %@", tokenString);
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShouldRegisterPushKey] == YES){
        [self registerUserForPush:tokenString];
    }
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
            NSLog(@"registered push to provider");
        }
    }];
    [task resume];
}

- (void)saveNotificaionFromPayload:(NSDictionary *)payload andIncrementBadgeValue:(BOOL)shouldIncrement
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
    PNNotification *newNotification = [NSEntityDescription insertNewObjectForEntityForName:@"PNNotification" inManagedObjectContext:coreDataStack.managedObjectContext];
    newNotification.content = [[payload objectForKey:@"aps"] objectForKey:@"alert"];
    newNotification.threadID = [NSNumber numberWithInt:[[payload objectForKey:@"thread_id"] intValue]];
    newNotification.date = [dateFormatter dateFromString:[payload objectForKey:@"event_date"]];
    //NSLog(@"formatted date : %@", [dateFormatter dateFromString:[payload objectForKey:@"event_date"]]);
    newNotification.isRead = [NSNumber numberWithBool:NO];
    newNotification.imageURL = [payload objectForKey:@"image_url"];
    [coreDataStack saveContext];
    
    if (shouldIncrement) {
        PNTabBarController *rootTabBarVC = (PNTabBarController *)self.window.rootViewController;
        PNNotificationsViewController *notiVC = [rootTabBarVC.viewControllers objectAtIndex:3];
        NSInteger value = [notiVC.tabBarItem.badgeValue integerValue];
        notiVC.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)++value];
    }
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
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:62/255.0f green:24/255.0f blue:97/255.0f alpha:1.0f]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
}

- (void)initializeGoogleAnalytics
{
    [[GAI sharedInstance] setDispatchInterval:kGaDispatchPeriod];
    [[GAI sharedInstance] setDryRun:kGaDryRun];
    [[GAI sharedInstance] setTrackUncaughtExceptions:YES];
    [[GAI sharedInstance].logger setLogLevel:kGAILogLevelVerbose];
    
    self.tracker = [[GAI sharedInstance] trackerWithTrackingId:kGaPropertyId];
}

- (BOOL)cookieExpired:(NSHTTPCookie *)cookie
{
    //YES, if it will expire within a day
    NSTimeInterval timeInterval = [cookie.expiresDate timeIntervalSinceNow];
    NSTimeInterval dayInSeconds = 60*60*24;
    if (timeInterval <= dayInSeconds) return YES;
    else return NO;
}

#pragma mark - UITabBarController delegate


- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
//    NSLog(@"tab bar select VC : %@", viewController);
//    NSLog(@"selected VC : %@", tabBarController.selectedViewController);
    
    NSUInteger index = [tabBarController.viewControllers indexOfObject:viewController];
    if (index != 2) {
        [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"previousViewControllerIndex"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    static UIViewController *previousController = nil;
    if (previousController == viewController) {
        // the same tab was tapped a second time
        NSLog(@"tapped twice");
        if ([viewController isEqual:[tabBarController.viewControllers objectAtIndex:3]]) {
            viewController.tabBarItem.badgeValue = nil;
        }
        /*
        else if ([viewController isEqual:[tabBarController.viewControllers objectAtIndex:0]]) {
            UINavigationController *navigationVC = (UINavigationController *)viewController;
            NSLog(@"visible : %@", navigationVC.visibleViewController);
            PNFeedContentViewController *feedVC = (PNFeedContentViewController *)navigationVC.topViewController;
            [feedVC.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
         */
    }
    previousController = viewController;
}

@end
