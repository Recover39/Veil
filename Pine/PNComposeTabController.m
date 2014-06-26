//
//  PNComposeTabController.m
//  Pine
//
//  Created by soojin on 6/12/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNComposeTabController.h"
#import "PNComposeViewController.h"
#import "SVProgressHUD.h"

@interface PNComposeTabController () <PNComposeViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSString *authorID;
@property (nonatomic, strong) NSMutableDictionary *post;

@end

@implementation PNComposeTabController

-(NSMutableDictionary *)post
{
    if (!_post){
        _post = [[NSMutableDictionary alloc] init];
    }
    
    return _post;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.authorID = @"2";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self performSegueWithIdentifier:@"toComposeViewControllerSegue" sender:self];
}

#pragma mark - PNComposeViewController Delegate methods

-(void)didClose
{
    [self.tabBarController setSelectedIndex:0];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)doneComposeWithContent:(NSString *)content isPublic:(BOOL)isPublic
{
    [SVProgressHUD show];
    NSError *error;
    NSURL *url = [NSURL URLWithString:@"http://10.73.45.42:5000/threads"];
    NSDictionary *contentDictionary = @{@"author": self.authorID,
                                        @"content" : content,
                                        @"is_public" : [NSNumber numberWithBool:isPublic]};
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDictionary options:0 error:&error];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setURL:url];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setHTTPBody:contentData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        if (!error) {
            //NSLog(@"Data : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            //NSLog(@"Response : %@", response);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: @"OK", nil];
                [alertView show];
            });

        } else {
            NSLog(@"Error : %@", error);
        }
    }];
    [task resume];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self.tabBarController setSelectedIndex:0];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Helper Methods

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toComposeViewControllerSegue"]){
        UINavigationController *navVC = segue.destinationViewController;
        PNComposeViewController *nextVC = (PNComposeViewController *)navVC.visibleViewController;
        nextVC.delegate = self;
    }
}

@end
