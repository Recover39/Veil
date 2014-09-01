//
//  PNPostCellTableViewCell.m
//  Pine
//
//  Created by soojin on 6/23/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNPostCell.h"
#import "PNPhotoController.h"
#import "PNCoreDataStack.h"
#import "GAIDictionaryBuilder.h"

@interface PNPostCell ()

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UIView *bottomAccessoryView;
@property (strong, nonatomic) IBOutlet UILabel *contentLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *heartsCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *heartButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIButton *reportButton;

@property (strong, nonatomic) PNThread *thread;

@end

@implementation PNPostCell

- (void)layoutSubviews
{
    self.containerView.layer.cornerRadius = 2.0f;
    self.containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.containerView.layer.shadowOpacity = 0.7;
    self.containerView.layer.shadowOffset = CGSizeMake(0, 0);
    self.containerView.layer.shadowRadius = 0.6f;
    
    //BackgroundImageView mask
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.backgroundImageView.bounds
                                     byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                           cornerRadii:CGSizeMake(2.0, 2.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.backgroundImageView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.backgroundImageView.layer.mask = maskLayer;
    self.backgroundImageView.layer.masksToBounds = YES;
    
    self.bottomAccessoryView.layer.cornerRadius = 2.0f;

    [super layoutSubviews];
}

/* set left & right inset
- (void)setFrame:(CGRect)frame
{
    float inset = -14.0f;
    float dx = frame.origin.x - inset;
    frame.origin.x += dx;
    frame.size.width -= 2*dx;
    [super setFrame:frame];
}
*/

- (void)configureCellForThread:(PNThread *)thread
{
    _thread = thread;
    self.backgroundImageView.image = nil;
    
    [self.heartButton setImage:[UIImage imageNamed:@"filled_heart"] forState:UIControlStateSelected];
    
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
    
    self.backgroundImageView.image = [UIImage imageNamed:@"placeholder_image.jpg"];
    
    NSString *imageName = self.thread.imageURL;
    if ([imageName length] != 0) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [PNPhotoController imageForURLString:thread.imageURL completion:^(UIImage *image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.backgroundImageView.image = image;
                    [self setNeedsLayout];
                });
            }];
        });
    } else if ([imageName length] == 0) {
        self.backgroundImageView.image = nil;
    } else {
        NSLog(@"image length weird");
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
- (IBAction)reportButtonPressed:(UIButton *)sender
{
    [self.delegate reportPostButtonPressed:self.thread];
    /*
    NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/report", kMainServerURL, self.thread.threadID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSError *JSONerror;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            //SUCCESS
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Successfully reported!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alertView show];
            });
        } else {
            //FAIL
            NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
            NSLog(@"Error : %@", error);
        }
    }];
    [task resume];
     */
}

@end
