//
//  PNFeedsViewController.m
//  Pine
//
//  Created by soojin on 6/21/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNFeedsViewController.h"
#import "PNFeedContentViewController.h"
#import "BWTitlePagerView.h"

@interface PNFeedsViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) NSArray *pageTitles;
@property (strong, nonatomic) UIPageViewController *pageViewController;
//@property (strong, nonatomic) UIScrollView *scrollView;

@end

@implementation PNFeedsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.pageTitles = @[@"Friends", @"Everyone"];
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.view.backgroundColor = [UIColor lightGrayColor];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    PNFeedContentViewController *friendFeedVC = [self viewControllerAtIndex:0];
    [self.pageViewController setViewControllers:@[friendFeedVC] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    //Change the size of page view controller to fit between nav bar and tab bar
    CGRect pageViewRect = CGRectMake(0, 64, 320, 568-49-64);
    self.pageViewController.view.frame = pageViewRect;
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
    
//    BWTitlePagerView *pagingTitleView = [[BWTitlePagerView alloc] init];
//    pagingTitleView.frame = CGRectMake(0, 0, 150, 40);
//    pagingTitleView.font = [UIFont systemFontOfSize:18];
//    pagingTitleView.backgroundColor = [UIColor clearColor];
//    [pagingTitleView observeScrollView:self.pageViewController.view.subviews[0]];
//    [pagingTitleView addObjects:@[@"Friends", @"Everyone"]];
//    self.navigationItem.titleView = pagingTitleView;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

#pragma mark - Helper Methods

- (PNFeedContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    PNFeedContentViewController *feedVC;
    
    if (([self.pageTitles count] == 0) || (index >= [self.pageTitles count])) {
        return nil;
    }
    
    if (index == 0) {
        feedVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PNFeedContentViewController"];
        feedVC.pageIndex = index;
    }
    
    if (index == 1) {
        feedVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PNFeedContentViewController"];
        feedVC.pageIndex = index;
    }
    
//    if (index == 2) {
//        feedVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PNFeedContentViewController"];
//        feedVC.pageIndex = index;
//    }
    
    return feedVC;
}

#pragma mark - UIPageViewController Data source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PNFeedContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageTitles count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PNFeedContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
