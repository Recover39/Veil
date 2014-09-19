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

- (UIActivityIndicatorView *)indicatorView
{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.center = self.addFriendButton.center;
        [self.contentView addSubview:_indicatorView];
    }
    
    return _indicatorView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)addFriendButtonPressed:(UIButton *)sender
{
    self.addFriendButton.hidden = YES;
    [self.indicatorView startAnimating];
    [self.delegate addFriendOfCell:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSNumber *newValue = [change objectForKey:@"new"];
    if (![newValue isKindOfClass:[NSNull class]]) {
        self.addFriendButton.hidden = [newValue boolValue];
    }
}

@end
