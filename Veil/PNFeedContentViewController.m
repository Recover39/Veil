//
//  PNEntireFeedViewController.m
//  Pine
//
//  Created by soojin on 6/20/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNFeedContentViewController.h"
#import "PNPostCell.h"
#import <RestKit/RestKit.h>
#import "TMPThread.h"
#import "PNThreadDetailViewController.h"
#import "TTTTimeIntervalFormatter.h"

@interface PNFeedContentViewController ()

@property (strong, nonatomic) NSMutableArray *threads;
@property (strong, nonatomic) NSString *isFriend;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic) BOOL isUpdating;
@property (nonatomic) BOOL shouldUpdate;

@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

@end

@implementation PNFeedContentViewController

- (NSMutableArray *)threads
{
    if (!_threads) {
        _threads = [[NSMutableArray alloc] init];
    }
    
    return _threads;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self performSegueWithIdentifier:@"showLoginSegue" sender:self];
    
    if (self.pageIndex == 0) {
        self.isFriend = @"true";
    } else {
        self.isFriend = @"false";
    }
    
    self.shouldUpdate = YES;
    self.isUpdating = NO;
    
    self.tableView.allowsSelection = YES;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.indicatorView.center = CGPointMake(self.view.center.x, self.view.center.y - 60);
    [self.view addSubview:self.indicatorView];
    [self.indicatorView startAnimating];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    [self getNewThreads];
}

#pragma mark - Helper methods

- (void)fetchInitialThreads
{
    [self.refreshControl beginRefreshing];
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/timeline/friends?count=%d", kMainServerURL, 20];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    
    //Perform ObjectRequestOperation
    [self performRKObjectRequestOperationWithURL:request completion:^(NSArray *newThreads) {
        self.threads = [newThreads mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];
            if ([self.indicatorView isAnimating]) [self.indicatorView stopAnimating];
            [self.tableView reloadData];
            
            self.refreshControl = [[UIRefreshControl alloc] init];
            [self.refreshControl addTarget:self action:@selector(getNewThreads) forControlEvents:UIControlEventValueChanged];
        });
    }];
}

- (void)getNewThreads
{
    if ([self.threads count] == 0) {
        [self fetchInitialThreads];
        return;
    }
    TMPThread *mostRecentThread = self.threads[0];
    NSString *urlString = [NSString stringWithFormat:@"http://%@/timeline/friends/since_offset?offset_id=%d&count=%d", kMainServerURL, [mostRecentThread.threadID intValue], 5];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    
    [self performRKObjectRequestOperationWithURL:request completion:^(NSArray *newThreads) {
        NSRange range = {0, [newThreads count]};
        [self.threads insertObjects:newThreads atIndexes:[NSIndexSet indexSetWithIndexesInRange: range]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self.tableView reloadData];
            if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];
            
            NSMutableArray  *indexPaths = [NSMutableArray array];
            for (NSInteger i = 0 ; i < [newThreads count] ; i++) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
            [self.tableView endUpdates];
        });
    }];
}

- (void)getMoreThreads
{
    if (self.shouldUpdate == NO) return;

    TMPThread *oldestThread = [self.threads lastObject];
    NSString *urlString = [NSString stringWithFormat:@"http://%@/timeline/friends/previous_offset?offset_id=%d&count=%d", kMainServerURL, [oldestThread.threadID intValue], 10];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    
    [self performRKObjectRequestOperationWithURL:request completion:^(NSArray *newThreads) {
        if ([newThreads count] == 0) {
            self.shouldUpdate = NO;
            self.isUpdating = NO;
            return;
        }
        
        NSInteger threadCountBeforeUpdate = [self.threads count];
        NSInteger newThreadsCount = [newThreads count];
        [self.threads addObjectsFromArray:newThreads];
        
        //Generate indexPaths to use them in inserting
        NSMutableArray *indexPaths = [NSMutableArray array];
        for (NSInteger i = threadCountBeforeUpdate ; i < threadCountBeforeUpdate + newThreadsCount ; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self.tableView reloadData];
            if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];
            
            //Insert
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
            [self.tableView endUpdates];
            
            self.isUpdating = NO;
        });
    }];
}

- (void)performRKObjectRequestOperationWithURL:(NSURLRequest *)request completion:(void(^)(NSArray *newThreads))completion
{
    RKObjectMapping *threadMapping = [RKObjectMapping mappingForClass:[TMPThread class]];
    [threadMapping addAttributeMappingsFromDictionary:@{@"id": @"threadID",
                                                        @"like_count" : @"likeCount",
                                                        @"pub_date" : @"publishedDate",
                                                        @"liked" : @"userLiked",
                                                        @"image_url" : @"imageURL",
                                                        @"content" : @"content",
                                                        @"comment" : @"commentCount"}];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:threadMapping method:RKRequestMethodGET pathPattern:nil keyPath:@"data" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        //Return the result array to the completion block
        completion(mappingResult.array);
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Operation failed With Error : %@", error);

    }];
    
    [objectRequestOperation start];
    
    //Cancel HTTP request if no answer in 10 seconds
    [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(cancelRequest:) userInfo:[NSDictionary dictionaryWithObject:objectRequestOperation forKey:@"objectRequestOperation"] repeats:NO];
}

- (void)cancelRequest:(NSTimer *)timer
{
    RKObjectRequestOperation *objectRequestOperation = [[timer userInfo] objectForKey:@"objectRequestOperation"];
    if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];
    [objectRequestOperation cancel];
    
    [timer invalidate];
    timer = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.threads count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PNPostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    static TTTTimeIntervalFormatter *_timeIntervalFormatter = nil;
    static dispatch_once_t onceTokenForTimeFormatter;
    dispatch_once(&onceTokenForTimeFormatter, ^{
        _timeIntervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
        [_timeIntervalFormatter setUsesIdiomaticDeicticExpressions:YES];
    });
    
    TMPThread *thread = self.threads[indexPath.row];
    
    /*
    NSTimeInterval timeInterval = [thread.publishedDate timeIntervalSinceNow];
    NSDate *today = [NSDate date];
    NSLog(@"current date : %@", today);
    NSLog(@"date : %@", thread.publishedDate);
    NSLog(@"time interval : %f", timeInterval);
    */
    
    // Configure the cell...
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    //[cell setFriendlyDate:[_timeIntervalFormatter stringForTimeInterval:timeInterval]];
    [cell configureCellForThread:thread];
    
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"threadDetailViewSegue" sender:self.threads[indexPath.row]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.shouldUpdate == YES) {
        CGFloat currentOffset = scrollView.contentOffset.y;
        CGFloat maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        
        if (maximumOffset > 0 && maximumOffset - currentOffset <= 320.0f * 3) {
            if (self.isUpdating == NO) {
                self.isUpdating = YES;
                [self getMoreThreads];
            } else return;
        }
    }
}

#pragma mark - Navigation
     
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"threadDetailViewSegue"]) {
        TMPThread *thread = (TMPThread *)sender;
        PNThreadDetailViewController *nextVC = segue.destinationViewController;
        nextVC.thread = thread;
    }
}


@end
