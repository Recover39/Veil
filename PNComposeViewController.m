//
//  PNComposeViewController.m
//  Pine
//
//  Created by soojin on 6/12/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNComposeViewController.h"
#import "PNImageCollectionPicker.h"
#import "PNImagePickerController.h"
#import "PNCamViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface PNComposeViewController () <UITextViewDelegate, PNImagePickerControllerDelegate, PNCamViewControllerDelegate>

//IBOutlets
@property (strong, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UIButton *friendsOnlyButton;
@property (strong, nonatomic) IBOutlet UIView *friendOnlyIndicator;
@property (weak, nonatomic) IBOutlet UIButton *toEveryoneButton;
@property (strong, nonatomic) IBOutlet UIView *toEveryoneIndicator;
@property (strong, nonatomic) IBOutlet UIView *accessoryView;
@property (strong, nonatomic) IBOutlet UIView *keyboardAccessoryView;
@property (strong, nonatomic) IBOutlet UIImageView *pickedImageView;

//ALAssets
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) ALAssetsGroup *cameraRollGroup;

//Posts
@property (nonatomic, assign) BOOL isPublic;
@property (strong, nonatomic) UIImage *pickedImage;


@end

@implementation PNComposeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isPublic = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.contentTextView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Lazy Instantiation

- (ALAssetsLibrary *)assetsLibrary
{
    if (!_assetsLibrary) {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    
    return _assetsLibrary;
}

- (ALAssetsGroup *)cameraRollGroup
{
    if (!_cameraRollGroup) {
        _cameraRollGroup = [[ALAssetsGroup alloc] init];
    }
    
    return _cameraRollGroup;
}

#pragma mark - Keyboard Notification selectors

- (void)keyboardWillShow:(NSNotification *)notification
{                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    //Get the keyboard size
    NSDictionary *userInfo = [notification userInfo];
    CGFloat kbHeight = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    
    //Set the animation
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        CGRect newFrame = self.keyboardAccessoryView.frame;
        newFrame.origin.y -= kbHeight;
        self.keyboardAccessoryView.frame = newFrame;
    }];
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    //Get the keyboard size
    NSDictionary *userInfo = [notification userInfo];
    CGFloat kbHeight = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    
    //Set the animation
    [UIView beginAnimations:nil context:nil];
    //[UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView animateWithDuration:5 animations:^{
        CGRect newFrame = self.keyboardAccessoryView.frame;
        newFrame.origin.y += kbHeight;
        self.keyboardAccessoryView.frame = newFrame;
    }];
    [UIView commitAnimations];
}

#pragma mark - Override set methods

- (void)setIsPublic:(BOOL)isPublic
{
    _isPublic = isPublic;
    
    self.friendsOnlyButton.alpha = 0.5f;
    self.toEveryoneButton.alpha = 0.5f;
    self.friendOnlyIndicator.hidden = YES;
    self.toEveryoneIndicator.hidden = YES;
    
    if (isPublic == YES){
        self.toEveryoneButton.alpha = 1.0f;
        self.toEveryoneIndicator.hidden = NO;
    } else {
        self.friendsOnlyButton.alpha = 1.0f;
        self.friendOnlyIndicator.hidden = NO;
    }
}

#pragma mark - IBActions

- (IBAction)launchImagePickerController:(UIButton *)sender
{
    // enumerate only photos
    NSUInteger groupTypes = ALAssetsGroupSavedPhotos;
    
    // Perform enumeration
    [self.assetsLibrary enumerateGroupsWithTypes:groupTypes usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
        [group setAssetsFilter:onlyPhotosFilter];
        
        if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"Camera Roll"]) {
            self.cameraRollGroup = group;
        } else if (!group) {
            //End of enumeration
            //launch collectionView here
            [self displayPicker];
        }
    } failureBlock:^(NSError *error) {
        NSString *errorMessage = nil;
        switch ([error code]) {
            case ALAssetsLibraryAccessUserDeniedError:
            case ALAssetsLibraryAccessGloballyDeniedError:
                errorMessage = @"The user has declined access to it.";
                break;
            default:
                errorMessage = @"Reason unknown error";
                break;
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
    }];
}

- (IBAction)launchCamera:(UIButton *)sender
{
    PNCamViewController *camController = [self.storyboard instantiateViewControllerWithIdentifier:@"PNCamViewController"];
    camController.delegate = self;
    [self presentViewController:camController animated:YES completion:nil];
}

- (IBAction)cancelBarButtonItemPressed:(UIBarButtonItem *)sender
{
    [self.delegate didClose];
}

- (IBAction)postBarButtonItemPressed:(UIBarButtonItem *)sender
{
    NSString *content = self.contentTextView.text;
    
    //TODO : 포스팅 각종 예외처리
    NSString *trimmedContent = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmedContent length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"WTF!" message:@"Write some shit before posting!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    } else {
        [self.delegate doneComposeWithContent:content isPublic:self.isPublic];
    }
}
- (IBAction)friendsOnlyButtonPressed:(UIButton *)sender
{
    self.isPublic = NO;
}
- (IBAction)toEveryoneButtonPressed:(UIButton *)sender
{
    
    self.isPublic = YES;
}

#pragma mark - Helper Methods

- (void)displayPicker
{
    PNImageCollectionPicker *collectionPicker = [[PNImageCollectionPicker alloc] init];
    collectionPicker.assetsGroup = self.cameraRollGroup;
    PNImagePickerController *imagePicker = [[PNImagePickerController alloc] initWithRootViewController:collectionPicker];
    imagePicker.delegate = self;
    collectionPicker.delegate = imagePicker;
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - PNCamViewController delegate

- (void)capturedSquarePhoto:(UIImage *)image
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.pickedImage = image;
    self.pickedImageView.image = image;
}

- (void)cancelled
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PNImagePickerController delegate

- (void)pnImagePickerController:(PNImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSDictionary *dict = info[0];
    self.pickedImage = dict[UIImagePickerControllerOriginalImage];
    self.pickedImageView.image = self.pickedImage;
}

- (void)pnImagePickerControllerDidCancel:(PNImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}
*/

@end
