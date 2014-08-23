//
//  PNComposeViewController.h
//  Pine
//
//  Created by soojin on 6/12/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PNComposeViewControllerDelegate <NSObject>

- (void)didClose;
- (void)doneComposeWithContent:(NSString *)content withImage:(UIImage *)image isPublic:(BOOL)isPublic;

@end

@interface PNComposeViewController : UIViewController

@property (weak, nonatomic) id <PNComposeViewControllerDelegate> delegate;

@end
