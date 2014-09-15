//
//  PNEntireFeedViewController.m
//  Pine
//
//  Created by soojin on 6/20/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNFeedContentViewController.h"
#import "PNPostCell.h"
#import "PNTextCell.h"
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "PNThreadDetailViewController.h"
#import "PNCoreDataStack.h"
#import "PNThread.h"
#import "UIActionSheet+Blocks.h"
#import "GAIDictionaryBuilder.h"

@interface PNFeedContentViewController () <NSFetchedResultsControllerDelegate, PNPostCellReportDelegate>

//UI Controls
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

//Flags
@property (nonatomic) BOOL isUpdating;
@property (nonatomic) BOOL shouldUpdate;

//Controllers
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchRequest *threadsFetchRequest;

@end

@implementation PNFeedContentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.shouldUpdate = YES;
    self.isUpdating = NO;
    
    self.tableView.allowsSelection = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor colorWithRed:216/255.0f green:216/255.0f blue:216/255.0f alpha:1.0f];
    
    self.refreshControl = nil;
    
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.indicatorView.center = CGPointMake(self.view.center.x, self.view.center.y - 60);
    [self.view addSubview:self.indicatorView];
    [self.indicatorView startAnimating];
    
    [self.fetchedResultsController performFetch:NULL];
    [self fetchInitialThreads];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Google Analytics Screen tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Feed"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (UIRefreshControl *)myRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    
    return refreshControl;
}

#pragma mark - Helper methods

- (void)handleRefresh
{
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Feed"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"refresh" label:nil value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    [self getNewThreads];
}

- (void)fetchInitialThreads
{
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithPersistentStoreCoordinator:[PNCoreDataStack defaultStack].persistentStoreCoordinator];
    [managedObjectStore createManagedObjectContexts];
    
    RKEntityMapping *threadMapping = [RKEntityMapping mappingForEntityForName:@"PNThread" inManagedObjectStore:managedObjectStore];
    [threadMapping addAttributeMappingsFromDictionary:@{@"id": @"threadID",
                                                       @"type": @"type",
                                                       @"like_count": @"likeCount",
                                                       @"liked": @"userLiked",
                                                       @"pub_date": @"publishedDate",
                                                       @"image_url": @"imageURL",
                                                       @"content": @"content",
                                                       @"comment": @"commentCount"}];
    threadMapping.identificationAttributes = @[@"threadID"];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:threadMapping method:RKRequestMethodGET pathPattern:nil keyPath:@"data" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/timeline/friends?count=%d", kMainServerURL, 20];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    
    RKManagedObjectRequestOperation *objectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    objectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    objectRequestOperation.managedObjectCache = managedObjectStore.managedObjectCache;
    objectRequestOperation.savesToPersistentStore = YES;
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [self.fetchedResultsController performFetch:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.indicatorView isAnimating]) [self.indicatorView stopAnimating];
            self.refreshControl = [self myRefreshControl];
            [self.tableView reloadData];
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"FAIL");
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.indicatorView isAnimating]) [self.indicatorView stopAnimating];
        });
    }];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:objectRequestOperation];
}

- (void)getNewThreads
{
    PNThread *mostRecentThread = [self.fetchedResultsController.fetchedObjects firstObject];
    NSString *urlString = [NSString stringWithFormat:@"http://%@/timeline/friends/since_offset?offset_id=%d&count=%d", kMainServerURL, [mostRecentThread.threadID intValue], 5];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    
    
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithPersistentStoreCoordinator:[PNCoreDataStack defaultStack].persistentStoreCoordinator];
    [managedObjectStore createManagedObjectContexts];
    
    RKEntityMapping *threadMapping = [RKEntityMapping mappingForEntityForName:@"PNThread" inManagedObjectStore:managedObjectStore];
    [threadMapping addAttributeMappingsFromDictionary:@{@"id": @"threadID",
                                                        @"type": @"type",
                                                        @"like_count": @"likeCount",
                                                        @"liked": @"userLiked",
                                                        @"pub_date": @"publishedDate",
                                                        @"image_url": @"imageURL",
                                                        @"content": @"content",
                                                        @"comment": @"commentCount"}];
    threadMapping.identificationAttributes = @[@"threadID"];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:threadMapping method:RKRequestMethodGET pathPattern:nil keyPath:@"data" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKManagedObjectRequestOperation *objectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    objectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    objectRequestOperation.managedObjectCache = managedObjectStore.managedObjectCache;
    objectRequestOperation.savesToPersistentStore = YES;
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"SUCCESS");
        [self.fetchedResultsController performFetch:NULL];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];
            [self.tableView reloadData];
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"FAIL");
    }];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:objectRequestOperation];
    
    //Cancel HTTP request if no answer in 25 seconds
    [NSTimer scheduledTimerWithTimeInterval:25.0 target:self selector:@selector(cancelRequest:) userInfo:[NSDictionary dictionaryWithObject:objectRequestOperation forKey:@"objectRequestOperation"] repeats:NO];
}

- (void)getMoreThreads
{
    if (self.shouldUpdate == NO) return;
    
    PNThread *oldestThread = [self.fetchedResultsController.fetchedObjects lastObject];
    
    NSFetchRequest *newFetch = self.threadsFetchRequest;
    newFetch.fetchLimit += 20;
    
    //Replace self.fetchedResultsController with new fetch request (increased fetch limit by 20)
    NSFetchedResultsController *newFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:newFetch managedObjectContext:[[PNCoreDataStack defaultStack] managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
    newFetchedResultsController.delegate = self;
    self.fetchedResultsController = newFetchedResultsController;
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/timeline/friends/previous_offset?offset_id=%d&count=%d", kMainServerURL, [oldestThread.threadID intValue], 10];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithPersistentStoreCoordinator:[PNCoreDataStack defaultStack].persistentStoreCoordinator];
    [managedObjectStore createManagedObjectContexts];
    
    RKEntityMapping *threadMapping = [RKEntityMapping mappingForEntityForName:@"PNThread" inManagedObjectStore:managedObjectStore];
    [threadMapping addAttributeMappingsFromDictionary:@{@"id": @"threadID",
                                                        @"type": @"type",
                                                        @"like_count": @"likeCount",
                                                        @"liked": @"userLiked",
                                                        @"pub_date": @"publishedDate",
                                                        @"image_url": @"imageURL",
                                                        @"content": @"content",
                                                        @"comment": @"commentCount"}];
    threadMapping.identificationAttributes = @[@"threadID"];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:threadMapping method:RKRequestMethodGET pathPattern:nil keyPath:@"data" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKManagedObjectRequestOperation *objectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    objectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    objectRequestOperation.managedObjectCache = managedObjectStore.managedObjectCache;
    objectRequestOperation.savesToPersistentStore = YES;
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"==================================get more threads SUCCESS=======================================");
        self.isUpdating = NO;
        NSLog(@"mapping result : %lu", (unsigned long)mappingResult.count);
        if ([mappingResult count] == 0) {
            self.shouldUpdate = NO;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"reload tableview");
            [self.tableView reloadData];
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"FAIL");
        self.isUpdating = NO;
    }];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:objectRequestOperation];
}

- (void)cancelRequest:(NSTimer *)timer
{
    RKManagedObjectRequestOperation *objectRequestOperation = [[timer userInfo] objectForKey:@"objectRequestOperation"];
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
    //id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [self.fetchedResultsController.fetchedObjects count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PNThread *thread;
    if (indexPath.row < self.fetchedResultsController.fetchedObjects.count) {
        thread = [self.fetchedResultsController objectAtIndexPath:indexPath];
    } else if (indexPath.row == self.fetchedResultsController.fetchedObjects.count){
        UITableViewCell *lastCell = [tableView dequeueReusableCellWithIdentifier:@"LastCell"];
        NSLog(@"lastcell");
        return lastCell;
    }
    
    UITableViewCell<PNCellProtocol> *cell = nil;
    if ([thread.imageURL length] != 0) {
        cell = (PNPostCell *)[tableView dequeueReusableCellWithIdentifier:@"ImageCell" forIndexPath:indexPath];
    } else {
        cell = (PNTextCell *)[tableView dequeueReusableCellWithIdentifier:@"TextCell" forIndexPath:indexPath];
    }
    
    // Configure the cell...
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell setReportDelegate:self];
    [cell configureCellForThread:thread];
        
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Feed"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"thread" value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self performSegueWithIdentifier:@"threadDetailViewSegue" sender:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PNThread *thread = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([thread.imageURL length] != 0) {
        return 337;
    } else return 160;
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

#pragma mark - NSFetchedResultsController

- (NSFetchRequest *)threadsFetchRequest
{
    /*
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PNThread"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedDate" ascending:NO]];
    fetchRequest.fetchBatchSize = 20;
    fetchRequest.fetchLimit = 20;
    */
    if (!_threadsFetchRequest) {
        //Initial
        _threadsFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PNThread"];
        _threadsFetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedDate" ascending:NO]];
        _threadsFetchRequest.fetchBatchSize = 20;
        _threadsFetchRequest.fetchLimit = 20;
    }
    
    return _threadsFetchRequest;
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
    NSFetchRequest *fetchRequest = self.threadsFetchRequest;
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:coreDataStack.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"feed content vc insert");
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            NSLog(@"delete");
            break;
        case NSFetchedResultsChangeUpdate:
            NSLog(@"feed content vc update");
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeMove:
            NSLog(@"move");
            break;
    }
}

#pragma mark - PNPostCellReportDelegate

- (void)reportPostButtonPressed:(PNThread *)thread
{
    [UIActionSheet showInView:self.view withTitle:nil cancelButtonTitle:@"취소" destructiveButtonTitle:nil otherButtonTitles:@[@"사용자 차단", @"악성글 신고"] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            //사용자 차단
            
            //Google Analytics Event Tracking
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [tracker set:kGAIScreenName value:@"Feed"];
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"block" value:nil] build]];
            [tracker set:kGAIScreenName value:nil];
            
            NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/block", kMainServerURL, thread.threadID];
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
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"글쓴이를 차단했습니다!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [alertView show];
                    });
                } else {
                    //FAIL
                    NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
                    NSLog(@"Error : %@", error);
                    if ([responseDic[@"message"] isEqualToString:@"Warn: Cannot block yourself"]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"오잉?" message:@"본인은 차단할 수 없습니다!" delegate:nil cancelButtonTitle:@"네" otherButtonTitles:nil, nil];
                            [alertView show];
                        });
                        
                    }
                }
            }];
            [task resume];
        } else if (buttonIndex == 1) {
            //악성글 신고
            
            //Google Analytics Event Tracking
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [tracker set:kGAIScreenName value:@"Feed"];
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"report" value:nil] build]];
            [tracker set:kGAIScreenName value:nil];
            
            NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/report", kMainServerURL, thread.threadID];
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
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"악성글을 신고했습니다!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [alertView show];
                    });
                } else {
                    //FAIL
                    NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
                    NSLog(@"Error : %@", error);
                    if ([responseDic[@"message"] isEqualToString:@"Warn: Cannot report yourself."]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"오잉?" message:@"본인의 글은 신고를 할 수 없습니다!" delegate:nil cancelButtonTitle:@"네" otherButtonTitles:nil, nil];
                            [alertView show];
                        });
                        
                    }
                }
            }];
            [task resume];
        }
    }];
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"threadDetailViewSegue"]) {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        PNThread *thread = [self.fetchedResultsController objectAtIndexPath:indexPath];
        PNThreadDetailViewController *nextVC = segue.destinationViewController;
        nextVC.threadID = thread.threadID;
    }
}

@end