//
//  PNPhotoCell.m
//  Pine
//
//  Created by soojin on 6/26/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNPhotoCell.h"

@implementation PNPhotoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.imageView = [[UIImageView alloc] init];
        
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPhoto)];
//        tap.numberOfTapsRequired = 1;
//        [self addGestureRecognizer:tap];
        
        [self.contentView addSubview:self.imageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.contentView.bounds;
}

#pragma mark - Helpers

//- (void)selectPhoto
//{
//    NSLog(@"selected a photo");
//}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
