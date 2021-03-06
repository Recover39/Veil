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
#import "GAIDictionaryBuilder.h"

@interface PNComposeViewController () <UITextViewDelegate, PNImagePickerControllerDelegate, PNCamViewControllerDelegate, UIAlertViewDelegate>

//IBOutlets
@property (strong, nonatomic) IBOutlet UITextView *contentTextView;
@property (strong, nonatomic) IBOutlet UIView *keyboardAccessoryView;
@property (strong, nonatomic) IBOutlet UIImageView *pickedImageView;
@property (weak, nonatomic) IBOutlet UIButton *deletePhotoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButton;

//ALAssets
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) ALAssetsGroup *cameraRollGroup;

//Posts
@property (strong, nonatomic) UIImage *pickedImage;


@end

@implementation PNComposeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.deletePhotoButton.hidden = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.contentTextView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Google Analytics Screen tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Compose"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
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

#pragma mark - IBActions

- (IBAction)launchImagePickerController:(UIButton *)sender
{
    // enumerate only photos
    NSUInteger groupTypes = ALAssetsGroupSavedPhotos;
    
    // Perform enumeration
    [self.assetsLibrary enumerateGroupsWithTypes:groupTypes usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"Camera Roll"]) {
            ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
            [group setAssetsFilter:onlyPhotosFilter];
            self.cameraRollGroup = group;
        } else if (!group) {
            //End of enumeration
            //launch collectionView here
            [self displayPicker];
        }
    } failureBlock:^(NSError *error) {
//        switch ([error code]) {
//            case ALAssetsLibraryAccessUserDeniedError:
//            case ALAssetsLibraryAccessGloballyDeniedError:
//                errorMessage = @"The user has declined access to it.";
//                break;
//            default:
//                errorMessage = @"Reason unknown error";
//                break;
//        }
        UIViewController *albumInaccessibleVC = [self.storyboard instantiateViewControllerWithIdentifier:@"inaccessibleViewController"];
        albumInaccessibleVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"완료" style:UIBarButtonItemStylePlain target:self action:@selector(closeInaccessibleVC)];
        albumInaccessibleVC.title = @"사진첩";
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:albumInaccessibleVC];
        [self presentViewController:navVC animated:YES completion:nil];
    }];
}

- (void)closeInaccessibleVC
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)launchCamera:(UIButton *)sender
{
    PNCamViewController *camController = [self.storyboard instantiateViewControllerWithIdentifier:@"PNCamViewController"];
    camController.delegate = self;
    [self presentViewController:camController animated:YES completion:nil];
}

- (IBAction)cancelBarButtonItemPressed:(UIBarButtonItem *)sender
{
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Compose"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"cancel" value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    if (self.pickedImage != nil || [self.contentTextView.text length] != 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"정말 취소하시겠어요?" message:nil delegate:self cancelButtonTitle:@"취소" otherButtonTitles:@"삭제", nil];
        [alertView show];
    } else {
        [self.delegate didClose];
    }
}

- (IBAction)postBarButtonItemPressed:(UIBarButtonItem *)sender
{
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Compose"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"post" value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    NSString *content = self.contentTextView.text;
    
    //TODO : 포스팅 각종 예외처리
    NSString *trimmedContent = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmedContent length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"아무것도 쓰지 않았어요!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    } else {
        //Can Post
        self.postButton.enabled = NO;
        self.cancelBarButton.enabled = NO;
        [self.delegate doneComposeWithContent:content withImage:self.pickedImage isPublic:NO];
    }
}

- (IBAction)deletePhotoButtonPressed:(UIButton *)sender {
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Compose"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"delete picture" value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    self.pickedImageView.image = nil;
    self.pickedImage = nil;
    self.deletePhotoButton.hidden = YES;
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        self.pickedImage = nil;
        self.pickedImageView.image = nil;
        [self.delegate didClose];
    }
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
    self.deletePhotoButton.hidden = NO;
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
    self.deletePhotoButton.hidden = NO;
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
