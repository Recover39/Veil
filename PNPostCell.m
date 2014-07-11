//
//  PNPostCellTableViewCell.m
//  Pine
//
//  Created by soojin on 6/23/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNPostCell.h"
#import "PNPhotoController.h"

@interface PNPostCell ()

@property (strong, nonatomic) IBOutlet UIView *bottomAccessoryView;
@property (strong, nonatomic) IBOutlet UILabel *contentLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *heartsCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *heartButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIButton *reportButton;

@property (strong, nonatomic) TMPThread *thread;

@end

@implementation PNPostCell

- (void)layoutSubviews
{
    self.imageView.frame = self.contentView.bounds;
    [self.contentView sendSubviewToBack:self.imageView];
}

- (void)configureCellForThread:(TMPThread *)thread
{
    _thread = thread;
    
    [self.heartButton setImage:[UIImage imageNamed:@"hearted.png"] forState:UIControlStateSelected];
    
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
    
    NSString *imageName = self.thread.imageURL;
    if ([imageName length] != 0) {
        [PNPhotoController imageForThread:thread completion:^(UIImage *image) {
            self.imageView.image = image;
        }];
    } else if ([imageName length] == 0) {
        self.imageView.image = nil;
    } else {
        NSLog(@"image length weird");
    }
}

#pragma mark - IBActions

- (IBAction)heartButtonPressed:(UIButton *)sender
{
    if (self.heartButton.selected) {
        //CANCEL LIKE
        NSError *error;
        NSString *urlString = [NSString stringWithFormat:@"http://10.73.45.42:5000/threads/%@/unlike", self.thread.threadID];
        NSURL *url = [NSURL URLWithString:urlString];
        NSDictionary *contentDictionary = @{@"user" : kUserID};
        NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDictionary options:0 error:&error];
        
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        //[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [urlRequest setHTTPBody:contentData];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            if (!error) {
                //NSLog(@"Data : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] == 200) {
                    //SUCCESS!
                    self.thread.likeCount = @([self.thread.likeCount intValue] - 1);
                    self.thread.userLiked = [NSNumber numberWithBool:NO];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"unlike success");
                        self.heartsCountLabel.text = [self.thread.likeCount stringValue];
                        self.heartButton.selected = NO;
                    });
                } else NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
            } else {
                NSLog(@"Error : %@", error);
            }
        }];
        [task resume];
        
    } else {
        //LIKE
        NSError *error;
        NSString *urlString = [NSString stringWithFormat:@"http://10.73.45.42:5000/threads/%@/like", self.thread.threadID];
        NSURL *url = [NSURL URLWithString:urlString];
        NSDictionary *contentDictionary = @{@"user" : kUserID};
        NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDictionary options:0 error:&error];
        
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        //[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [urlRequest setHTTPBody:contentData];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            if (!error) {
                //NSLog(@"Data : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] == 200) {
                    //SUCCESS!
                    self.thread.likeCount = @([self.thread.likeCount intValue] + 1);
                    self.thread.userLiked = [NSNumber numberWithBool:YES];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"like success");
                        self.heartsCountLabel.text = [self.thread.likeCount stringValue];
                        self.heartButton.selected = YES;
                    });
                } else NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
            } else {
                NSLog(@"Error : %@", error);
            }
        }];
        [task resume];
    }
}
- (IBAction)reportButtonPressed:(UIButton *)sender
{
    NSError *error;
    NSString *urlString = [NSString stringWithFormat:@"http://10.73.45.42:5000/threads/%@/report", self.thread.threadID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSDictionary *contentDictionary = @{@"user" : kUserID};
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDictionary options:0 error:&error];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setHTTPBody:contentData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        if (!error) {
            //NSLog(@"Data : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse statusCode] == 200) {
                NSLog(@"report success");
                dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Successfully reported!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alertView show];
                });
            } else NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
        } else {
            NSLog(@"Error : %@", error);
        }
    }];
    [task resume];}


@end
