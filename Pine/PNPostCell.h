//
//  PNPostCellTableViewCell.h
//  Pine
//
//  Created by soojin on 6/23/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMPThread.h"

@interface PNPostCell : UITableViewCell

- (void)configureCellForThread:(TMPThread *)thread;

- (void)setFriendlyDate:(NSString *)dateString;

@end
