//
//  PNImageCollectionViewController.m
//  Pine
//
//  Created by soojin on 6/24/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNImageCollectionPicker.h"
#import "PNPhotoCell.h"
#import "VPImageCropperViewController.h"
#import "PNCamViewController.h"
#import "GAIDictionaryBuilder.h"

@interface PNImageCollectionPicker () <VPImageCropperDelegate>

@end

@implementation PNImageCollectionPicker

- (instancetype)init {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(106.0, 106.0);
    layout.minimumInteritemSpacing = 1.0;
    layout.minimumLineSpacing = 1.0;
    
    return (self = [super initWithCollectionViewLayout:layout]);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Setup photo cell
    [self.collectionView registerClass:[PNPhotoCell class] forCellWithReuseIdentifier:@"photoCell"];
    
    //Instantiation
    if (!self.assets) {
        _assets = [[NSMutableArray alloc] init];
    } else {
        [self.assets removeAllObjects];
    }
    
    //Setup Navigation Item
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonItemPressed)];
    [self.navigationItem setRightBarButtonItem:cancelBarButtonItem];
    
    //Photo Enumeration
    ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
    [self.assetsGroup setAssetsFilter:onlyPhotosFilter];
    [self.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
            [self.assets insertObject:result atIndex:0];
        } else {
            //end
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.collectionView reloadData];
    
    //Google Analytics Screen tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Image Picker"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

#pragma mark - Helper Methods

- (void)cancelBarButtonItemPressed
{
    [self.delegate cancelledSelection];
}

#pragma mark - UICollectionView data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.assets count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"photoCell";
    PNPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    ALAsset *asset = self.assets[indexPath.row];
    CGImageRef thumbnailImageRef = [asset thumbnail];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
    
    // apply the image to the cell
    cell.imageView.image = thumbnail;
    
    return cell;
}

#pragma mark - UICollectionView delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Image Picker"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"thumbnail" value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    //Extract UIImage from selected asset
    ALAsset *asset = self.assets[indexPath.row];
    ALAssetRepresentation *assetRep = [asset defaultRepresentation];
    
    if(assetRep != nil) {
        CGImageRef imgRef = nil;
        //defaultRepresentation returns image as it appears in photo picker, rotated and sized,
        //so use UIImageOrientationUp when creating our image below.
        UIImageOrientation orientation = UIImageOrientationUp;

        //NSLog(@"image UTI : %@", [assetRep UTI]);
        //NSLog(@"image url : %@", [assetRep url]);
        imgRef = [assetRep fullScreenImage];
        UIImage *img = [UIImage imageWithCGImage:imgRef scale:1.0f orientation:orientation];
        
        //VC to crop square image
        VPImageCropperViewController *cropperVC = [[VPImageCropperViewController alloc] initWithImage:img cropFrame:CGRectMake(0, 100.0f, self.view.frame.size.width, self.view.frame.size.width) limitScaleRatio:3.0];
        cropperVC.delegate = self;
        [self.navigationController pushViewController:cropperVC animated:YES];
    }
}

#pragma mark - VPImageCropperVC delegate

- (void)imageCropper:(VPImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage
{
    [self.delegate selectedSquareImage:editedImage];
}

- (void)imageCropperDidCancel:(VPImageCropperViewController *)cropperViewController
{
    [self.navigationController popViewControllerAnimated:YES];
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
