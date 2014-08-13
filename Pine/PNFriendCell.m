//
//  PNFriendCell.m
//  Pine
//
//  Created by soojin on 8/13/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNFriendCell.h"

@interface PNFriendCell()

@end

@implementation PNFriendCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.addFriendButton.hidden = YES;
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)addFriendButtonPressed:(UIButton *)sender
{
    [self.delegate addFriendOfCell:self];
}

@end
