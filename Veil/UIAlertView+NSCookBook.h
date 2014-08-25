//
//  UIAlertView+NSCookBook.h
//  Pine
//
//  Created by soojin on 7/25/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (NSCookBook)

- (void)showWithCompletion:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion;

@end
