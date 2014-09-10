//
//  PNTextCell.m
//  Veil
//
//  Created by soojin on 9/10/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNTextCell.h"
#import "PNPhotoController.h"
#import "PNCoreDataStack.h"
#import "GAIDictionaryBuilder.h"

@interface PNTextCell()

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *bottomAccessoryView;

@property (weak, nonatomic) IBOutlet UILabel *commentsCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *heartsCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UIButton *heartButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;

@property (strong, nonatomic) PNThread *thread;

@end

@implementation PNTextCell

- (void)layoutSubviews
{
    self.contentLabel.preferredMaxLayoutWidth = self.contentLabel.frame.size.width;
    [self.contentLabel setNumberOfLines:4];
    [self.contentLabel sizeToFit];
    [self.contentLabel setLineBreakMode:NSLineBreakByWordWrapping];
    self.contentLabel.backgroundColor = [UIColor yellowColor];
    
    self.containerView.layer.cornerRadius = 2.0f;
    self.containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.containerView.layer.shadowOpacity = 0.7;
    self.containerView.layer.shadowOffset = CGSizeMake(0, 0);
    self.containerView.layer.shadowRadius = 0.4f;

    self.bottomAccessoryView.layer.cornerRadius = 2.0f;
    
    [super layoutSubviews];
}

- (void)setReportDelegate:(id)delegate
{
    self.delegate = delegate;
}

- (void)configureCellForThread:(PNThread *)thread
{
    _thread = thread;
    
    [self.heartButton setImage:[UIImage imageNamed:@"ic_like"] forState:UIControlStateSelected];
    
    self.contentLabel.text = self.thread.content;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    self.timeLabel.text = [formatter stringFromDate:self.thread.publishedDate];
    
    self.heartsCountLabel.text = [self.thread.likeCount stringValue];
    self.commentsCountLabel.text = [self.thread.commentCount stringValue];
    
    if ([self.thread.userLiked boolValue] == YES) {
        self.heartButton.selected = YES;
    } else {
        self.heartButton.selected = NO;
    }
}

- (void)setFriendlyDate:(NSString *)dateString
{
    self.timeLabel.text = dateString;
}

#pragma mark - IBActions
- (IBAction)heartButtonPressed:(UIButton *)sender
{
    if (self.heartButton.selected) {
        //CANCEL LIKE
        
        //Google Analytics Event Tracking
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName value:@"Thread"];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"cancel like" value:nil] build]];
        [tracker set:kGAIScreenName value:nil];
        
        NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/unlike", kMainServerURL, self.thread.threadID];
        NSURL *url = [NSURL URLWithString:urlString];
        
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
        [urlRequest setHTTPMethod:@"POST"];
        //[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSError *JSONerror;
            NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
            if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
                //SUCCESS
                self.thread.likeCount = @([self.thread.likeCount intValue] - 1);
                self.thread.userLiked = [NSNumber numberWithBool:NO];
                [[PNCoreDataStack defaultStack] saveContext];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"unlike success");
                    self.heartsCountLabel.text = [self.thread.likeCount stringValue];
                    self.heartButton.selected = NO;
                });
            } else {
                //FAIL
                NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
                NSLog(@"Error : %@", error);
            }
        }];
        [task resume];
        
    } else {
        //LIKE
        
        //Google Analytics Event Tracking
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName value:@"Thread"];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"like thread" value:nil] build]];
        [tracker set:kGAIScreenName value:nil];
        
        NSLog(@"like post");
        NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/like", kMainServerURL, self.thread.threadID];
        NSURL *url = [NSURL URLWithString:urlString];
        
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
        [urlRequest setHTTPMethod:@"POST"];
        //[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSError *JSONerror;
            NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
            if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
                //SUCCESS
                self.thread.likeCount = @([self.thread.likeCount intValue] + 1);
                self.thread.userLiked = [NSNumber numberWithBool:YES];
                [[PNCoreDataStack defaultStack] saveContext];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"like success");
                    self.heartsCountLabel.text = [self.thread.likeCount stringValue];
                    self.heartButton.selected = YES;
                });
            } else {
                //FAIL
                NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
                NSLog(@"Error : %@", error);
            }
            
        }];
        [task resume];
    }

}

#pragma mark - PNTextCellReportDelegate
- (IBAction)reportButtonPressed:(UIButton *)sender
{
    [self.delegate reportPostButtonPressed:self.thread];
}

@end
