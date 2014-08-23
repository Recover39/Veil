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
    [SVProgressHUD dismiss];
    [self.tabBarController setSelectedIndex:0];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)doneComposeWithContent:(NSString *)content withImage:(UIImage *)image isPublic:(BOOL)isPublic
{
    [SVProgressHUD show];
    
    NSError *error;
    NSString *urlString = [NSString stringWithFormat:@"http://%@/threads", kMainServerURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSDictionary *contentDictionary = @{@"content" : content,
                                        @"is_public" : [NSNumber numberWithBool:isPublic]};
    NSLog(@"JSON : %@", contentDictionary);
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDictionary options:0 error:&error];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setURL:url];
    
    if (image == nil) {
        //사진 없는 글 POST
        
        [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [urlRequest setHTTPBody:contentData];
    } else {
        //사진 있는 글 POST
        
        //Setup HTTP Header
        
        NSString *boundary = @"4A6qaFx71K";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [urlRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        //Create HTTP body
        NSMutableData *body = [[NSMutableData alloc] init];
        NSData *boundaryLineData =[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
        
        [body appendData:boundaryLineData];
        [body appendData:[@"Content-Disposition: form-data; name=\"json\"\r\n" dataUsingEncoding	:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/json\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:contentData]];
        
        [body appendData:boundaryLineData];
        [body appendData:[@"Content-Disposition: form-data; name=\"bg_image_file\"; filename=\"image.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:UIImageJPEGRepresentation(image, 0.9f)];
        
        [body appendData:boundaryLineData];
        [urlRequest setHTTPBody:body];
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSError *JSONerror;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            //SUCCESS
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                //NSLog(@"Data : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                //NSLog(@"Response : %@", response);
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: @"OK", nil];
                [alertView show];
            });
        } else {
            //FAIL
            NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
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
