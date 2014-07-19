//
//  PNEntireFeedViewController.h
//  Pine
//
//  Created by soojin on 6/20/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TMPThread;

@protocol PNFeedContentViewControllerDelegate <NSObject>

- (void)selectedThread:(TMPThread *)thread;

@end

@interface PNFeedContentViewController : UITableViewController


@property (nonatomic, weak) id<PNFeedContentViewControllerDelegate> delegate;
@property NSUInteger pageIndex;

@end
