//
//  PNNotificationCell.m
//  Pine
//
//  Created by soojin on 8/21/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNNotificationCell.h"

@implementation PNNotificationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.thumbnailImage.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.thumbnailImage.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [self.thumbnailImage.layer setBorderWidth:1.0f];
}

@end
