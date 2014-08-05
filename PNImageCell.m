//
//  PNImageCell.m
//  Pine
//
//  Created by soojin on 8/5/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNImageCell.h"

@implementation PNImageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.threadImageView = [[UIImageView alloc] init];
        self.threadImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.threadImageView.clipsToBounds = YES;
        self.threadImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.threadImageView];
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)updateConstraints
{
    NSLayoutConstraint *leadingCN = [NSLayoutConstraint constraintWithItem:self.threadImageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0f];
    NSLayoutConstraint *topCN = [NSLayoutConstraint constraintWithItem:self.threadImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0f];
    NSLayoutConstraint *trailingCN = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.threadImageView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0f];
    NSLayoutConstraint *bottomCN = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.threadImageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0f];
    NSLayoutConstraint *heightCN = [NSLayoutConstraint constraintWithItem:self.threadImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:320.0f];
    
    [self.contentView addConstraints:@[leadingCN, topCN, trailingCN, bottomCN, heightCN]];
    
    [super updateConstraints];
}

@end
