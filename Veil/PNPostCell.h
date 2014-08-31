//
//  PNPostCellTableViewCell.h
//  Pine
//
//  Created by soojin on 6/23/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PNThread.h"

@protocol PNPostCellReportDelegate <NSObject>

- (void)reportPostButtonPressed:(PNThread *)thread;

@end

@interface PNPostCell : UITableViewCell

@property (weak, nonatomic) id<PNPostCellReportDelegate> delegate;

- (void)configureCellForThread:(PNThread *)thread;
- (void)setFriendlyDate:(NSString *)dateString;

@end
