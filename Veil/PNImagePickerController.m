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

- (void)selectedSquareImage:(UIImage *)squareImage
{
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    
    NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];

    [workingDictionary setObject:squareImage forKey:UIImagePickerControllerOriginalImage];
    
    [returnArray addObject:workingDictionary];
    
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
