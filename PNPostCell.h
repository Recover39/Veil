//
//  PNPostCellTableViewCell.h
//  Pine
//
//  Created by soojin on 6/23/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PNPostCell : UITableViewCell

@property (strong, nonatomic) NSDictionary *post;

- (void)configureCellForPost:(NSDictionary *)post;

@end
