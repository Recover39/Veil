//
//  PNImagePickerController.m
//  Pine
//
//  Created by soojin on 6/26/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNImagePickerController.h"
#import "PNImageCollectionPicker.h"

@interface PNImagePickerController ()

@end

@implementation PNImagePickerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - PNImageCollectionPicker delegate

- (void)selectedAsset:(ALAsset *)asset
{
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    
    id obj = [asset valueForProperty:ALAssetPropertyType];
    
    NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
    
    [workingDictionary setObject:obj forKey:UIImagePickerControllerMediaType];
    
    //This method returns nil for assets from a shared photo stream that are not yet available locally. If the asset becomes available in the future, an ALAssetsLibraryChangedNotification notification is posted.
    ALAssetRepresentation *assetRep = [asset defaultRepresentation];
    
    if(assetRep != nil) {
        CGImageRef imgRef = nil;
        //defaultRepresentation returns image as it appears in photo picker, rotated and sized,
        //so use UIImageOrientationUp when creating our image below.
        UIImageOrientation orientation = UIImageOrientationUp;
        
        imgRef = [assetRep fullScreenImage];
        
        UIImage *img = [UIImage imageWithCGImage:imgRef
                                           scale:1.0f
                                     orientation:orientation];
        
        [workingDictionary setObject:img forKey:UIImagePickerControllerOriginalImage];
        [workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]] forKey:UIImagePickerControllerReferenceURL];
        
        [returnArray addObject:workingDictionary];
    }
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(pnImagePickerController:didFinishPickingMediaWithInfo:)]) {
		[self.delegate performSelector:@selector(pnImagePickerController:didFinishPickingMediaWithInfo:) withObject:self withObject:returnArray];
	} else {
        [self popToRootViewControllerAnimated:NO];
    }
}

- (void)cancelledSelection
{
    [self.delegate pnImagePickerControllerDidCancel:self];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
