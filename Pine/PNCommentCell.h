//
//  PNCommentCell.h
//  Pine
//
//  Created by soojin on 7/19/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TMPComment;

@interface PNCommentCell : UITableViewCell

- (void)configureCellWithComment:(TMPComment *)comment;

@end
