//
//  PNRegisterViewController.m
//  Veil
//
//  Created by soojin on 9/4/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNRegisterViewController.h"
#import "SVProgressHUD.h"

@interface PNRegisterViewController () <UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *authCodeField;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (strong, nonatomic) NSString *authNum;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;
@property (weak, nonatomic) IBOutlet UIView *authFailView;
@property (weak, nonatomic) IBOutlet UIView *authSuccessView;
@property (weak, nonatomic) IBOutlet UIButton *resendButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

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
    self.indicatorView.hidden = YES;
    
    self.authFailView.frame = CGRectMake(0, 163, 320, 47);
    self.authFailView.hidden = YES;
    [self.view addSubview:self.authFailView];
    
    self.authSuccessView.frame = CGRectMake(0, 163, 320, 47);
    self.authSuccessView.hidden = YES;
    [self.view addSubview:self.authSuccessView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.authCodeField becomeFirstResponder];
    [self sendAuthRequest];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (range.location >= 6) {
        return NO;
    }
    //Deleting...
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
    [SVProgressHUD show];
    NSString *urlString = [NSString stringWithFormat:@"http://%@/users/register", kMainServerURL];
    NSURL *URL = [NSURL URLWithString:urlString];
    
    NSDictionary *dic = @{@"username" : self.phoneNumber,
                          @"password" : self.phoneNumber,
                          @"auth_num" : self.authNum,
                          @"device_type" : @"ios"};
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:NULL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:contentData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSError *JSONerror;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            //SUCCESS
            //After registration, sign in user
            NSLog(@"new user");
            [self signInUser];
        } else {
            //FAIL
            NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
            NSLog(@"Error : %@", error);
            //NOT PINE!!!
            if ([responseDic[@"message"] isEqualToString:@"ERROR: Duplicated username."]) {
                NSLog(@"already signed up user");
                [self signInUser];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"실패ㅠㅠ" message:[NSString stringWithFormat:@"%@", responseDic[@"message"]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];
                });
            }
        }
    }];
    [task resume];
    
    
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
- (IBAction)textFieldDidChange:(UITextField *)sender
{
    if (self.authCodeField.text.length == 6) {
        [self checkValidationCode];
    }
}

- (void)signInUser
{
    NSString *urlString = [NSString stringWithFormat:@"http://%@/users/login", kMainServerURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setURL:url];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSError *error;
    NSDictionary *contentDic = @{@"username": self.phoneNumber,
                                 @"password" : self.phoneNumber};
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDic options:0 error:&error];
    [urlRequest setHTTPBody:contentData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSError *JSONerror;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            //SUCCESS
            NSLog(@"login success");
            NSHTTPCookie *cookie = [[NSHTTPCookie cookiesWithResponseHeaderFields:[httpResponse allHeaderFields] forURL:url] objectAtIndex:0];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self performSegueWithIdentifier:@"SignInUserSegue" sender:nil];
            });
            
        } else {
            //FAIL
            NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
            NSLog(@"Error : %@", error);
            //NOT PINE!!!
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"실패ㅠㅠ" message:[NSString stringWithFormat:@"%@", responseDic[@"message"]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            });
        }
    }];
    [task resume];
}

- (void)sendAuthRequest
{
    NSLog(@"phone : %@", self.phoneNumber);
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/users/auth/request", kMainServerURL];
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
}

- (void)checkValidationCode
{
    if (self.authNum != nil) {
        if ([self.authNum isEqualToString:self.authCodeField.text]) {
            //Show success view
            [[NSUserDefaults standardUserDefaults] setObject:self.phoneNumber forKey:@"user_phonenumber"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            self.backButton.hidden = YES;
            self.authSuccessView.hidden = NO;
            self.registerButton.enabled = YES;
            self.resendButton.enabled = NO;
            [self.authCodeField resignFirstResponder];
            self.authCodeField.enabled = NO;
            return;
        }
    }
    //Show error view
    if (self.authFailView.hidden == YES) self.authFailView.hidden = NO;
    [self performSelector:@selector(hideFailView) withObject:nil afterDelay:2.0f];
}

- (void)hideFailView
{
    if (self.authFailView.hidden == NO) self.authFailView.hidden = YES;
}

@end
