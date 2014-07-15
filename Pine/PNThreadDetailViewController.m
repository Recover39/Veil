//
//  PNThreadDetailViewController.m
//  Pine
//
//  Created by soojin on 7/15/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNThreadDetailViewController.h"
#import "TMPThread.h"
#import "TMPComment.h"
#import "PNPhotoController.h"
#import <RestKit/RestKit.h>

@interface PNThreadDetailViewController ()
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIImageView *threadImage;
@property (strong, nonatomic) IBOutlet UILabel *contentLabel;

@end

@implementation PNThreadDetailViewController

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
    
    self.contentLabel.text = self.thread.content;
    
    NSString *imageName = self.thread.imageURL;
    if ([imageName length] != 0) {
        [PNPhotoController imageForThread:self.thread completion:^(UIImage *image) {
            self.threadImage.image = image;
        }];
    } else if ([imageName length] == 0) {
        self.threadImage.image = nil;
    } else {
        NSLog(@"image length weird");
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self fetchComments];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Helpers

- (void)fetchComments
{
    RKObjectMapping *commentMapping = [RKObjectMapping mappingForClass:[TMPComment class]];
    [commentMapping addAttributeMappingsFromDictionary:@{@"id": @"commentID",
                                                        @"likes" : @"likeCount",
                                                        @"pub_date" : @"publishedDate",
                                                        @"comment_type" : @"commentType",
                                                        @"comment_user_id" : @"commenterID",
                                                        @"content" : @"content"}];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:commentMapping method:RKRequestMethodGET pathPattern:nil keyPath:@"data" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSString *urlString = [NSString stringWithFormat:@"http://10.73.45.42:5000/threads/%@/comments?user=%@", self.thread.threadID, kUserID];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
    
    RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        //Return the array to completion block
        NSMutableArray *commentsArray = [mappingResult.array mutableCopy];
        NSLog(@"comments Array : %@", commentsArray);
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Operation failed With Error : %@", error);
    }];
    
    [objectRequestOperation start];
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
