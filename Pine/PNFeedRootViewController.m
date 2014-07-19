//
//  PNFeedRootViewController.m
//  Pine
//
//  Created by soojin on 7/14/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNFeedRootViewController.h"
#import "PNFeedContentViewController.h"
#import "PNThreadDetailViewController.h"

@interface PNFeedRootViewController () <UIScrollViewDelegate, PNFeedContentViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (strong, nonatomic) NSArray *contentList;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;

@end

@implementation PNFeedRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor grayColor];
    
    self.contentList = @[@"친구", @"전체", @"내 관심글"];
    NSUInteger pagesCount = [self.contentList count];
    
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < pagesCount; i++)
    {
		[controllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;

    //Prevent scroll view inset caused by navigation bar
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    self.scrollView.pagingEnabled = YES;
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame)*pagesCount, self.scrollView.frame.size.height);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.directionalLockEnabled = NO;
    self.scrollView.bounds = CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    self.scrollView.delegate = self;
    
    self.pageControl.numberOfPages = pagesCount;
    self.pageControl.currentPage = 0;
    
    //load scrollview pages here
    [self loadFeedWithPage:0];
    [self loadFeedWithPage:1];
}

#pragma mark - Helpers

- (void)loadFeedWithPage:(NSUInteger)page
{
    if (page >= self.contentList.count) return;
    
    PNFeedContentViewController *controller = [self.viewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null]) {
        controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PNFeedContentViewController"];
        controller.pageIndex = page;
        controller.delegate = self;
        [self.viewControllers replaceObjectAtIndex:page withObject:controller];
    }
    
    //Add the controller's view to the scroll view
    if (controller.tableView.superview == nil) {
        CGRect frame = self.scrollView.frame;
        frame.origin.x = CGRectGetWidth(frame) * page;
        frame.origin.y = 0;
        controller.tableView.frame = frame;
        
        [self addChildViewController:controller];
        [self.scrollView addSubview:controller.tableView];
        [controller didMoveToParentViewController:self];
    }
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = CGRectGetWidth(self.scrollView.frame);
    NSUInteger page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
    
    [self loadFeedWithPage:page - 1];
    [self loadFeedWithPage:page];
    [self loadFeedWithPage:page + 1];
}

#pragma mark - PNFeedContentVC delegate

- (void)selectedThread:(TMPThread *)thread
{
    [self performSegueWithIdentifier:@"threadDetailViewSegue" sender:thread];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"threadDetailViewSegue"]) {
        TMPThread *thread = (TMPThread *)sender;
        PNThreadDetailViewController *nextVC = segue.destinationViewController;
        nextVC.thread = thread;
    }
}


@end
