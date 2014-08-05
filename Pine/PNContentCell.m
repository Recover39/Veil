//
//  PNContentCell.m
//  Pine
//
//  Created by soojin on 8/5/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNContentCell.h"

@interface PNContentCell()

@end

@implementation PNContentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.contentLabel = [[UILabel alloc] init];
        self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.contentLabel.numberOfLines = 0;
        self.contentLabel.textAlignment = NSTextAlignmentLeft;
        self.contentLabel.font = [UIFont systemFontOfSize:18.0f];
        self.contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.contentLabel];
        
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)updateConstraints
{
    NSLayoutConstraint *leadingCN = [NSLayoutConstraint constraintWithItem:self.contentLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:13.0f];
    NSLayoutConstraint *trailingCN = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentLabel attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:13.0f];
    NSLayoutConstraint *topCN = [NSLayoutConstraint constraintWithItem:self.contentLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:13.0f];
    NSLayoutConstraint *bottomCN = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.contentLabel attribute:NSLayoutAttributeBottom multiplier:1.0f constant:13.0f];
    bottomCN.priority = 750;
    
    
    [self.contentView addConstraints:@[leadingCN, trailingCN, topCN, bottomCN]];
    
    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    //띄어씌기 없이 쭉 쓰는 글이 잘리는걸 방지 (WHY?)
    self.contentLabel.preferredMaxLayoutWidth = self.contentLabel.frame.size.width;
    [super layoutSubviews];
}

@end
