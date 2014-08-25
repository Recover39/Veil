//
//  UIAlertView+NSCookBook.m
//  Pine
//
//  Created by soojin on 7/25/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <objc/runtime.h>
#import "UIAlertView+NSCookBook.h"

@interface NSCBAlertWrapper : NSObject

@property (copy) void(^completionBlock)(UIAlertView *alertView, NSInteger buttonIndex);

@end

@implementation NSCBAlertWrapper

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.completionBlock) self.completionBlock(alertView, buttonIndex);
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
    if (self.completionBlock) self.completionBlock(alertView, alertView.cancelButtonIndex);
}

@end

static const char kNSCBAlertViewWrapper;
@implementation UIAlertView (NSCookBook)

- (void)showWithCompletion:(void (^)(UIAlertView *, NSInteger))completion
{
    NSCBAlertWrapper *alertWrapper = [[NSCBAlertWrapper alloc] init];
    alertWrapper.completionBlock = completion;
    self.delegate = alertWrapper;
    
    objc_setAssociatedObject(self, &kNSCBAlertViewWrapper, alertWrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self show];
}

@end
