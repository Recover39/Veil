//
//  PNImagePickerController.h
//  Pine
//
//  Created by soojin on 6/26/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PNImageCollectionPicker.h"

@class PNImagePickerController;

@protocol PNImagePickerControllerDelegate <UINavigationControllerDelegate>

- (void)pnImagePickerController:(PNImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info;
- (void)pnImagePickerControllerDidCancel:(PNImagePickerController *)picker;

@end

@interface PNImagePickerController : UINavigationController <PNImageCollectionPickerDelegate>

@property (weak, nonatomic) id<PNImagePickerControllerDelegate> delegate;

@end
