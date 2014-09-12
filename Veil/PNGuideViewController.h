//
//  PNGuideViewController.h
//  Veil
//
//  Created by soojin on 9/11/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PNGuideViewDelegate <NSObject>

- (void)didAuthorizeAddressbook;

@end

@interface PNGuideViewController : UIViewController

@property (weak, nonatomic) id<PNGuideViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *explanationOne;
@property (weak, nonatomic) IBOutlet UILabel *explanationTwo;
@property (weak, nonatomic) IBOutlet UIButton *useContactsButton;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

- (void)increaseProgressByRate:(float)rate;

@end
