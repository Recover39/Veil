//
//  PNCellProtocol.h
//  Veil
//
//  Created by soojin on 9/10/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PNThread;

@protocol PNCellProtocol <NSObject>

- (void)configureCellForThread:(PNThread *)thread;
- (void)setFriendlyDate:(NSString *)dateString;
- (void)setReportDelegate:(id)delegate;

@end
