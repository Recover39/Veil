//
//  PNThreadActionDelegate.h
//  Veil
//
//  Created by soojin on 9/19/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PNThreadActionDelegate <NSObject>

- (void)reportPostButtonPressed:(PNThread *)thread;
- (void)commentButtonPressed:(UITableViewCell *)thread;

@end
