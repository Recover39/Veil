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

@implementation PNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //After All Third-party SDKs
    [Crashlytics startWithAPIKey:@"d5fd4fd405ab0d0363bdb2f3286eecef87d3b5a8"];
    
    [self customizeUserInterface];

    PNTabBarController *rootTabBarVC = (PNTabBarController *)self.window.rootViewController;
    rootTabBarVC.delegate = self;
    
    return YES;
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
    }
    previousController = viewController;
}

@end
