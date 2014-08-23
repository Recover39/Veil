//
//  PNFriendCell.h
//  Pine
//
//  Created by soojin on 8/13/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PNFriendCell;

@protocol PNFriendCellDelegate <NSObject>

- (void)addFriendOfCell:(PNFriendCell *)cell;

@end

@interface PNFriendCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UIButton *addFriendButton;

@property (weak, nonatomic) id<PNFriendCellDelegate> delegate;
@end
