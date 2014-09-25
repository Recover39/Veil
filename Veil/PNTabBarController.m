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
    feedTab.selectedImage = [[UIImage imageNamed:@"menu_01_f"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UITabBarItem *friendTab = [self.tabBar.items objectAtIndex:1];
    friendTab.selectedImage = [[UIImage imageNamed:@"menu_02_f"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UITabBarItem *composeTab = [self.tabBar.items objectAtIndex:2];
    composeTab.selectedImage = [[UIImage imageNamed:@"menu_03_f"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UITabBarItem *notiTab = [self.tabBar.items objectAtIndex:3];
    notiTab.selectedImage = [[UIImage imageNamed:@"menu_04_f"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UITabBarItem *moreTab = [self.tabBar.items objectAtIndex:4];
    moreTab.selectedImage = [[UIImage imageNamed:@"menu_05_f"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
