//
//  PNRegisterViewController.m
//  Veil
//
//  Created by soojin on 9/4/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNRegisterViewController.h"

@interface PNRegisterViewController () <UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *authCodeField;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (strong, nonatomic) NSString *authNum;

@end

@implementation PNRegisterViewController

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
    self.authCodeField.delegate = self;
    self.registerButton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.authCodeField becomeFirstResponder];
    [self sendAuthRequest];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (range.location == 5 && range.length == 0) {
        //Entered 6 digits
        [self checkValidationCode];
    }
    if (range.location >= 6) {
        return NO;
    }
    //Deleting...
    if (range.location == 5) {
        if (range.length == 0) self.registerButton.enabled = YES;
        else self.registerButton.enabled = NO;
    }
    return YES;
}

#pragma mark - IBActions
- (IBAction)backButton:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)resendButton:(UIButton *)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"번호 확인\n\n%@", self.phoneNumber] message:@"사용하실 번호가 맞습니까?" delegate:self cancelButtonTitle:@"다시 입력" otherButtonTitles:@"확인", nil];
    [alertView show];
}

- (IBAction)registerUser:(UIButton *)sender
{
    NSString *urlString = [NSString stringWithFormat:@"http://10.73.38.175:8000/users/register"];
    NSURL *URL = [NSURL URLWithString:urlString];
    
    NSDictionary *dic = @{@"username" : self.phoneNumber,
                          @"password" : self.phoneNumber,
                          @"auth_num" : self.authNum,
                          @"device_type" : @"ios"};
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:NULL];
    
    
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    if (buttonIndex == 1) {
        self.authCodeField.text = @"";
        [self sendAuthRequest];
    }
}

#pragma mark - Helpers
- (void)sendAuthRequest
{
    NSLog(@"phone : %@", self.phoneNumber);
    /*
    NSString *urlString = [NSString stringWithFormat:@"http://10.73.38.175:8000/users/auth/request"];
    NSURL *URL = [NSURL URLWithString:urlString];

    NSDictionary *dic = @{@"username" : self.phoneNumber};
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:NULL];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:contentData];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if ([httpResponse statusCode] == 200) {
            NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            self.authNum = [responseDic objectForKey:@"auth_num"];
            NSLog(@"SUCCESS : %@", self.authNum);
        } else {
            NSLog(@"auth request error : %@", error);
            NSLog(@"error response : %@", [responseDic objectForKey:@"message"]);
        }
    }];
    [task resume];
    */
}

- (void)checkValidationCode
{
    if (self.authNum != nil) {
        if (self.authNum == self.authCodeField.text) {
            NSLog(@"PASS");
            return;
        }
    }
    
    //Show error view
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
