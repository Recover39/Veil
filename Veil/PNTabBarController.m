//
//  PNTabBarController.m
//  Pine
//
//  Created by soojin on 7/15/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNTabBarController.h"

@interface PNTabBarController ()

@end

@implementation PNTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBar.translucent = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITabBar *tabBar = self.tabBar;
    
    for (UITabBarItem *tabBarItem in tabBar.items) {
        [tabBarItem setImageInsets:UIEdgeInsetsMake(5, 0, -5, 0)];
    }
    
    UITabBarItem *feedTab = [self.tabBar.items objectAtIndex:0];
    feedTab.selectedImage = [[UIImage imageNamed:@"ic_timeline_select"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UITabBarItem *friendTab = [self.tabBar.items objectAtIndex:1];
    friendTab.selectedImage = [[UIImage imageNamed:@"ic_friend_select"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UITabBarItem *composeTab = [self.tabBar.items objectAtIndex:2];
    composeTab.selectedImage = [[UIImage imageNamed:@"ic_write_select"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UITabBarItem *notiTab = [self.tabBar.items objectAtIndex:3];
    notiTab.selectedImage = [[UIImage imageNamed:@"ic_notification_select"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
