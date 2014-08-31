//
//  PNImagePostCell.m
//  Veil
//
//  Created by soojin on 8/31/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNImagePostCell.h"

@interface PNImagePostCell()

@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIImageView *backgroundImageView;
@property (strong, nonatomic) UILabel *contentLabel;
@property (strong, nonatomic) UILabel *dateLabel;
@property (strong, nonatomic) UILabel *heartsCountLabel;
@property (strong, nonatomic) UILabel *commentsCountLabel;
@property (strong, nonatomic) UIButton *heartButton;
@property (strong, nonatomic) UIButton *commentButton;
@property (strong, nonatomic) UIButton *activityButton;

@end

@implementation PNImagePostCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.contentView.backgroundColor = [UIColor lightGrayColor];
        
        self.containerView = [[UIView alloc] init];
        self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
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

@end
