//
//  PNImageCollectionViewController.h
//  Pine
//
//  Created by soojin on 6/24/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol PNImageCollectionPickerDelegate <NSObject>

- (void)selectedSquareImage:(UIImage *)squareImage;
- (void)cancelledSelection;

@end

@interface PNImageCollectionPicker : UICollectionViewController

@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) ALAssetsGroup *assetsGroup;

@property (weak, nonatomic) id<PNImageCollectionPickerDelegate> delegate;

@end
