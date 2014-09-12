//
//  PNGuideViewController.m
//  Veil
//
//  Created by soojin on 9/11/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNGuideViewController.h"

@import AddressBook;

@interface PNGuideViewController ()

@end

@implementation PNGuideViewController

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
    
    [self resetOutlets];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)resetOutlets
{
    self.explanationOne.frame = CGRectMake(26, 180, CGRectGetWidth(self.explanationOne.frame), CGRectGetHeight(self.explanationOne.frame));
    self.explanationOne.hidden = NO;
    [self.view addSubview:self.explanationOne];
    self.explanationTwo.frame = CGRectMake(24, 233, CGRectGetWidth(self.explanationTwo.frame), CGRectGetHeight(self.explanationTwo.frame));
    self.explanationTwo.hidden = NO;
    [self.view addSubview:self.explanationTwo];
    self.useContactsButton.frame = CGRectMake(106, 355, CGRectGetWidth(self.useContactsButton.frame), CGRectGetHeight(self.useContactsButton.frame));
    self.useContactsButton.hidden = NO;
    [self.view addSubview:self.useContactsButton];
    
    self.loadingLabel.frame = CGRectMake(500, 221, CGRectGetWidth(self.loadingLabel.frame), CGRectGetHeight(self.loadingLabel.frame));
    [self.view addSubview:self.loadingLabel];
    self.indicatorView.frame = CGRectMake(800, 221, CGRectGetWidth(self.indicatorView.frame), CGRectGetHeight(self.indicatorView.frame));
    [self.view addSubview:self.indicatorView];
    self.progressBar.frame = CGRectMake(1200, 265, CGRectGetWidth(self.progressBar.frame), CGRectGetHeight(self.progressBar.frame));
    [self.view addSubview:self.progressBar];
    
    self.progressBar.progress = 0.0;
}

- (void)increaseProgressByRate:(float)rate
{
    self.progressBar.progress += rate;
}

#pragma mark - IBActions

- (IBAction)useContactsButtonPressed:(UIButton *)sender
{
    switch (ABAddressBookGetAuthorizationStatus()) {
        case kABAuthorizationStatusNotDetermined:
        {
            ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
                if (!granted) return;
                //GRANTED
                [self.delegate didAuthorizeAddressbook];
            });
            break;
        }
        case kABAuthorizationStatusAuthorized:
        {
            //Authorized
            [self.delegate didAuthorizeAddressbook];
            break;
        }
        case kABAuthorizationStatusDenied:
        case kABAuthorizationStatusRestricted:
        {
            //Do something to encourage user to allow access to his/her contacts
            UIAlertView *cantAccessContactAlert = [[UIAlertView alloc] initWithTitle:@"접근 권한이 없어요!" message: @"아이폰 설정->개인정보보호->연락처 에서 접근 권한을 허용해주세요" delegate:nil cancelButtonTitle: @"네" otherButtonTitles: nil];
            [cantAccessContactAlert show];
            
            break;
        }
            
        default:
            break;
    }

}

@end
