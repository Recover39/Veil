//
//  PNEnterPhoneNumberViewController.m
//  Veil
//
//  Created by soojin on 9/4/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNEnterPhoneNumberViewController.h"
#import "PNRegisterViewController.h"

@interface PNEnterPhoneNumberViewController () <UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberField;
@property (weak, nonatomic) IBOutlet UIView *accessoryView;

@end

@implementation PNEnterPhoneNumberViewController

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
    // Do any additional setup after loading the view.
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.phoneNumberField.delegate = self;
    self.phoneNumberField.inputAccessoryView = self.accessoryView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.phoneNumberField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (range.length == 0) {
        //User is typing
        if (range.location == 3) {
            textField.text = [NSString stringWithFormat:@"%@-", textField.text];
        } else if (range.location == 8) {
            textField.text = [NSString stringWithFormat:@"%@-", textField.text];
        } else if (range.location >= 13) {
            return NO;
        }
        
    } else if (range.length == 1) {
        //User is deleting
        if (range.location == 4) {
            textField.text = [textField.text substringToIndex:[textField.text length] - 1];
        } else if (range.location == 9) {
            textField.text = [textField.text substringToIndex:[textField.text length] - 1];
        }
    }
    
    return YES;
}

#pragma mark - IBActions

- (IBAction)nextButton:(UIButton *)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"번호 확인\n\n%@", self.phoneNumberField.text] message:@"사용하실 번호가 맞습니까?" delegate:self cancelButtonTitle:@"다시 입력" otherButtonTitles:@"확인", nil];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self performSegueWithIdentifier:@"enterAuthCode" sender:nil];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"enterAuthCode"]) {
        PNRegisterViewController *nextVC = segue.destinationViewController;
        NSString *phoneNumber = [self.phoneNumberField.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
        nextVC.phoneNumber = phoneNumber;
    }
}

@end
