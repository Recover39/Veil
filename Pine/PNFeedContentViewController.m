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

@interface PNFeedContentViewController ()

@property (strong, nonatomic) NSMutableArray *threads;
@property (strong, nonatomic) NSString *isFriend;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic) BOOL isUpdating;
@property (nonatomic) BOOL shouldUpdate;

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
    if (self.pageIndex == 0) {
        self.isFriend = @"true";
    } else {
        self.isFriend = @"false";
    }
    
    self.shouldUpdate = YES;
    self.isUpdating = NO;
    
    self.tableView.allowsSelection = YES;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor grayColor];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(getNewThreads) forControlEvents:UIControlEventValueChanged];

    [self fetchInitialThreads];
}

#pragma mark - Helper methods

- (void)fetchInitialThreads
{
    [self.refreshControl beginRefreshing];
    [self fetchNewThreadsWithOffset:0 andLimit:20 completion:^(NSArray *newThreads) {
        self.threads = [newThreads mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];
        });
    }];
}

- (void)getNewThreads
{
    if ([self.threads count] == 0) {
        [self fetchInitialThreads];
        return;
    }
    NSNumber *latestThreadID = [[self.threads objectAtIndex:0] threadID];
    
    NSString *URLString = [NSString stringWithFormat:@"http://%@/threads/%@/offset?user=%@&is_friend=%@", kMainServerURL, latestThreadID, kUserID, self.isFriend];
    NSURL *url = [NSURL URLWithString:URLString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse statusCode] == 200) {
                //SUCCESSFUL RESPONSE WITH RESPONSE CODE 200
                NSError *error;
                //NSLog(@"response : %@", response);
                //NSLog(@"data : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                
                NSInteger latestThreadOffset = [responseDic[@"offset"] integerValue];
                
                if (latestThreadOffset == 0) {
                    //NO MORE NEW THREADS
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];
                    });
                    return;
                } else {
                    //THERE ARE NEW THREADS
                    //AND FETCH THEM
                    [self fetchNewThreadsWithOffset:0 andLimit: latestThreadOffset completion:^(NSArray *newThreads) {
                        NSRange range = {0, latestThreadOffset};
                        [self.threads insertObjects:newThreads atIndexes:[NSIndexSet indexSetWithIndexesInRange: range]];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //[self.tableView reloadData];
                            if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];
                            
                            NSMutableArray  *indexPaths = [NSMutableArray array];
                            for (NSInteger i = 0 ; i < latestThreadOffset ; i++) {
                                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                            }
                            [self.tableView beginUpdates];
                            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                            [self.tableView endUpdates];
                        });
                    }];
                }
                
            } else {
                //WRONG RESPONSE CODE ERROR
                NSLog(@"Error with response code : %d", (int)[httpResponse statusCode]);
            }
        } else {
            //HTTP REQUEST ERROR
            NSLog(@"Error : %@", error);
        }
    }];
    [task resume];
}

- (void)getMoreThreads
{
    NSNumber *lastThreadID = [[self.threads lastObject] threadID];
    
    NSString *URLString = [NSString stringWithFormat:@"http://%@/threads/%@/offset?user=%@&is_friend=%@", kMainServerURL, lastThreadID, kUserID, self.isFriend];
    NSURL *url = [NSURL URLWithString:URLString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse statusCode] == 200) {
                //SUCCESSFUL RESPONSE WITH RESPONSE CODE 200
                NSError *error;
                //NSLog(@"response : %@", response);
                //NSLog(@"data : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                NSInteger lastThreadOffset = [responseDic[@"offset"] integerValue];

                [self fetchNewThreadsWithOffset:++lastThreadOffset andLimit:10 completion:^(NSArray *newThreads) {
                    if ([newThreads count] == 0) {
                        self.shouldUpdate = NO;
                        self.isUpdating = NO;
                        return;
                    }
                    int threadCountBeforeUpdate = [self.threads count];
                    int newThreadCount = [newThreads count];
                    [self.threads addObjectsFromArray:newThreads];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //[self.tableView reloadData];
                        
                        NSMutableArray  *indexPaths = [NSMutableArray array];
                        for (NSInteger i = threadCountBeforeUpdate ; i < threadCountBeforeUpdate + newThreadCount ; i++) {
                            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                        }
                        [self.tableView beginUpdates];
                        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                        [self.tableView endUpdates];
                        
                        self.isUpdating = NO;
                    });
                }];
                
            } else {
                //WRONG RESPONSE CODE ERROR
                NSLog(@"Error with response code : %d", (int)[httpResponse statusCode]);
            }
        } else {
            //HTTP REQUEST ERROR
            NSLog(@"Error : %@", error);
        }
    }];
    [task resume];
}

- (void)fetchNewThreadsWithOffset:(NSInteger)offset andLimit:(NSInteger)limit completion:(void(^)(NSArray *newThreads))completion
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
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/threads?user=%@&is_friend=%@&offset=%d&limit=%d", kMainServerURL, kUserID, self.isFriend, (int)offset, (int)limit];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
    
    RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        //Return the array to completion block
        completion(mappingResult.array);
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Operation failed With Error : %@", error);
    }];
    
    [objectRequestOperation start];
    
    //Cancel HTTP request if no answer in 5 seconds
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(cancelRequest:) userInfo:[NSDictionary dictionaryWithObject:objectRequestOperation forKey:@"objectRequestOperation"] repeats:NO];
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
    
    // Configure the cell...
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell configureCellForThread:self.threads[indexPath.row]];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.delegate selectedThread:self.threads[indexPath.row]];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

}
*/


@end
