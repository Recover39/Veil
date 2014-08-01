//
//  PNLoginViewController.m
//  Pine
//
//  Created by soojin on 7/31/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNLoginViewController.h"

@interface PNLoginViewController ()
@property (strong, nonatomic) IBOutlet UITextField *phoneNumberTextField;

@end

@implementation PNLoginViewController

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

- (IBAction)signInButtonPressed:(UIButton *)sender
{
    NSString *phoneNumber = [_phoneNumberTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([phoneNumber length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"번호를 입력하세요" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    } else {
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicatorView.center = CGPointMake(self.view.center.x, self.view.center.y);
        [self.view addSubview:indicatorView];
        [indicatorView startAnimating];
        
        //Register
        NSString *urlString = [NSString stringWithFormat:@"http://%@/users/login", kMainServerURL];
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setURL:url];
        [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        NSError *error;
        NSDictionary *contentDic = @{@"username": phoneNumber,
                                     @"password" : @"01098590530"};
        NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDic options:0 error:&error];
        [urlRequest setHTTPBody:contentData];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error) {
                //NSLog(@"Data : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                //NSLog(@"Response : %@", response);
                NSError *error;
                NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
                    //Successful
                    NSHTTPCookie *cookie = [[NSHTTPCookie cookiesWithResponseHeaderFields:[httpResponse allHeaderFields] forURL:url] objectAtIndex:0];
                    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
                    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [indicatorView stopAnimating];
                        [self.navigationController popToRootViewControllerAnimated:YES];
                    });
                } else if ([responseDic[@"result"] isEqualToString:@"not pine"]) {
                    //NOT PINE!!!
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [indicatorView stopAnimating];
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"실패ㅠㅠ" message:[NSString stringWithFormat:@"%@", responseDic[@"message"]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alertView show];
                    });
                }
            }
        }];
        [task resume];
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
