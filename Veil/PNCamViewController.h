//
//  PNCamViewController.h
//  Pine
//
//  Created by soojin on 6/27/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PNCamViewControllerDelegate <NSObject>

- (void)capturedSquarePhoto:(UIImage *)image;
- (void)cancelled;

@end

@interface PNCamViewController : UIViewController

@property (weak, nonatomic) id <PNCamViewControllerDelegate> delegate;

@end
