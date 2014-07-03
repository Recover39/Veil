//
//  PNPostCellTableViewCell.m
//  Pine
//
//  Created by soojin on 6/23/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNPostCell.h"
#import "PNPhotoController.h"

@interface PNPostCell ()

@property (strong, nonatomic) IBOutlet UIView *bottomAccessoryView;
@property (strong, nonatomic) IBOutlet UILabel *contentLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *heartsCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *heartButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;

@end

@implementation PNPostCell

- (void)layoutSubviews
{
    self.imageView.frame = self.contentView.bounds;
    [self.contentView sendSubviewToBack:self.imageView];
}

- (void)configureCellForPost:(NSDictionary *)post
{
    _post = post;
    
    [self.heartButton setImage:[UIImage imageNamed:@"hearted.png"] forState:UIControlStateSelected];
    
    self.contentLabel.text = post[@"content"];
    self.timeLabel.text = post[@"pub_date"];
    
    NSString *imageName = post[@"image_url"];
    if ([imageName length] != 0) {
        [PNPhotoController imageForPost:post completion:^(UIImage *image) {
            
            self.imageView.image = image;
        }];
    } else if ([imageName length] == 0) {
        self.imageView.image = nil;
    } else {
        NSLog(@"image length weird");
    }
}

#pragma mark - IBActions

- (IBAction)heartButtonPressed:(UIButton *)sender
{
    int count = [self.heartsCountLabel.text intValue];
    
    if (self.heartButton.selected) {
        self.heartButton.selected = NO;
        if (count == 1) self.heartsCountLabel.text = nil;
        else self.heartsCountLabel.text = [NSString stringWithFormat:@"%d", --count];
        
    } else {
        self.heartButton.selected = YES;
        self.heartsCountLabel.text = [NSString stringWithFormat:@"%d", ++count];
    }
}


@end
