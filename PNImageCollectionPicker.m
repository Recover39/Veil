//
//  PNImageCollectionViewController.m
//  Pine
//
//  Created by soojin on 6/24/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNImageCollectionPicker.h"
#import "PNPhotoCell.h"

@interface PNImageCollectionPicker () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

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
    // Do any additional setup after loading the view.
    
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
            UIImage *cameraButtonImage = [UIImage imageNamed:@"cameraButton.png"];
            [self.assets insertObject:cameraButtonImage atIndex:0];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.collectionView reloadData];
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
    
    if (indexPath.row == 0) {
        cell.imageView.image = self.assets[indexPath.row];
    } else {
        ALAsset *asset = self.assets[indexPath.row];
        CGImageRef thumbnailImageRef = [asset thumbnail];
        UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
        
        // apply the image to the cell
        cell.imageView.image = thumbnail;
    }
    
    return cell;
}

#pragma mark - UICollectionView delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"selected item at index path : %@", indexPath);
    if (indexPath.row == 0) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
            controller.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
            controller.delegate = self;
            [self presentViewController:controller animated:YES completion:nil];
        }
    } else {
        //TODO : Crop Image to Square.
        
        [self.delegate selectedAsset:self.assets[indexPath.row]];
    }
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
