//
//  PNThreadDetailViewController.m
//  Pine
//
//  Created by soojin on 7/15/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNThreadDetailViewController.h"
#import "PNThread.h"
#import "TMPComment.h"
#import "PNPhotoController.h"
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "PNCommentCell.h"
#import "PNContentCell.h"
#import "PNImageCell.h"
#import "UIAlertView+NSCookBook.h"
#import "HPGrowingTextView.h"
#import "PNCoreDataStack.h"

@interface PNThreadDetailViewController () <UITableViewDataSource, UITableViewDelegate, SWTableViewCellDelegate, HPGrowingTextViewDelegate>

@property (strong, nonatomic) NSManagedObjectID *managedObjectID;
@property (strong, nonatomic) PNThread *thread;

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *commentsArray;

@property (strong, nonatomic) IBOutlet UIButton *postCommentButton;
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) HPGrowingTextView *textView;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

//This is used in -heightForRowAtIndexPath: method
@property (strong, nonatomic) NSMutableDictionary *cells;

@property (nonatomic) int fetchingStatus;
@property (nonatomic) dispatch_queue_t fetchStatusQueue;

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
    [self setAutomaticallyAdjustsScrollViewInsets:YES];
    
    //Initial status
    self.fetchingStatus = 0;
    self.cells = [[NSMutableDictionary alloc] initWithCapacity:4];
    self.postCommentButton.enabled = NO;
    
    dispatch_queue_t fetchStatusQueue = dispatch_queue_create("fetchstatus queue", NULL);
    [self setFetchStatusQueue:fetchStatusQueue];

    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.containerView.hidden = YES;
    
    [self setupGrowingTextView];
    [self addTapGestureToBackground];
    [self setupTableView];
    
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.indicatorView.center = CGPointMake(self.view.center.x, self.view.center.y);
    [self.view addSubview:self.indicatorView];
    [self.indicatorView startAnimating];
    
    [self fetchThread];
    [self fetchCommentsWithCompletion:^{
        dispatch_async([self fetchStatusQueue], ^{
            self.fetchingStatus++;
            if (self.fetchingStatus == 2) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showSubViewsWithData];
                });
            }
        });
    }];
}

- (void)viewDidLayoutSubviews
{
    self.tableView.frame = self.view.frame;
    
    //Design the text view (rounded corners)
    [self.textView.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
    [self.textView.layer setBorderWidth:0.5f];
    self.textView.layer.cornerRadius = 5;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self registerForKeyboardNotifications];
    
    /*
    CGRect tableFrame = self.tableView.frame;
    CGPoint tableOffset = self.tableView.contentOffset;
    UIEdgeInsets tableInsets = self.tableView.contentInset;
    CGRect tableBounds = self.tableView.bounds;
    
    NSLog(@"d) tableView frame : (%f, %f, %f, %f)", tableFrame.origin.x, tableFrame.origin.y, tableFrame.size.width, tableFrame.size.height);
    NSLog(@"d) tableView offset : %f, %f", tableOffset.x, tableOffset.y);
    NSLog(@"d) tableView inset : %f, %f, %f, %f", tableInsets.left, tableInsets.right, tableInsets.top, tableInsets.bottom);
    NSLog(@"d) tableView bounds : (%f, %f, %f, %f)", tableBounds.origin.x, tableBounds.origin.y, tableBounds.size.width, tableBounds.size.height);
    */
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self removeKeyboardNotifications];
}

#pragma mark - Setup methods

- (void)setupTableView
{
    self.tableView = [[UITableView alloc] init];
    UIEdgeInsets newInsets = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.containerView.frame), 0);
    self.tableView.contentInset = newInsets;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.tableView registerClass:[PNCommentCell class] forCellReuseIdentifier:@"CommentCell"];
    [self.tableView registerClass:[PNContentCell class] forCellReuseIdentifier:@"ContentCell"];
    [self.tableView registerClass:[PNImageCell class] forCellReuseIdentifier:@"ImageCell"];
    //self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.allowsSelection = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //This line removes extra separator lines in tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.view insertSubview:self.tableView atIndex:0];
    self.tableView.hidden = YES;
}

- (void)addTapGestureToBackground
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewTapped)];
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
}

- (void)setupGrowingTextView
{
    self.textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(15, 7, 237, 40)];
    self.textView.maxNumberOfLines = 5;
    self.textView.minNumberOfLines = 1;
    self.textView.animateHeightChange = YES;
    self.textView.isScrollable = NO;
    self.textView.delegate = self;
    self.textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    self.textView.backgroundColor = [UIColor whiteColor];
    self.textView.placeholder = @"댓글을 입력하세요";
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.containerView addSubview:self.textView];
}

#pragma mark - IBActions
- (IBAction)postCommentButtonPressed:(UIButton *)sender
{
    [self.textView resignFirstResponder];
    self.postCommentButton.hidden = YES;
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicatorView.frame = CGRectMake(274, 13, 20, 20);
    [self.containerView addSubview:indicatorView];
    [indicatorView startAnimating];
    
    NSError *error;
    NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/comments", kMainServerURL, self.thread.threadID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSDictionary *contentDictionary = @{@"content" : self.textView.text};
    NSLog(@"JSON : %@", contentDictionary);
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDictionary options:0 error:&error];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setURL:url];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setHTTPBody:contentData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSError *JSONerror;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            //SUCCESS
            int commentCount = [self.thread.commentCount intValue];
            self.thread.commentCount = [NSNumber numberWithInt:++commentCount];
            [[PNCoreDataStack defaultStack] saveContext];
            
            [self fetchCommentsWithCompletion:^{
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.commentsArray.count-1 inSection:1];
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                [indicatorView stopAnimating];
                self.textView.text = @"";
                self.postCommentButton.hidden = NO;
            }];
            
        } else {
            //FAIL
            NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
            NSLog(@"Error : %@", error);
        }
    }];
    [task resume];
}

#pragma mark - Helpers

- (void)showSubViewsWithData
{
    [self.indicatorView stopAnimating];
    
    [self.tableView reloadData];
    self.tableView.hidden = NO;
    
    if ([self.thread.type integerValue] == PNThreadTypeSelf) self.textView.placeholder = @"이 글은 당신의 글입니다";
    else self.textView.placeholder = @"댓글을 입력하세요";
    self.containerView.hidden = NO;
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    // get keyboard size and loctaion
	CGRect keyboardBounds;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    // Need to translate the bounds to account for rotation.
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    
	// get a rect for the textView frame
	CGRect containerFrame = self.containerView.frame;
    containerFrame.origin.y = self.view.bounds.size.height - (keyboardBounds.size.height + containerFrame.size.height);
	// Animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
	self.containerView.frame = containerFrame;
	[UIView commitAnimations];
    
    //Adjust table view inset
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom = CGRectGetHeight(keyboardBounds) + CGRectGetHeight(self.containerView.frame);
    self.tableView.contentInset = insets;
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	// get a rect for the textView frame
	CGRect containerFrame = self.containerView.frame;
    containerFrame.origin.y = self.view.bounds.size.height - containerFrame.size.height - self.tabBarController.tabBar.frame.size.height;
	
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
	self.containerView.frame = containerFrame;
	[UIView commitAnimations];
    
    //Adjust table view inset
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom = CGRectGetHeight(self.containerView.frame) + CGRectGetHeight(self.tabBarController.tabBar.frame);
    self.tableView.contentInset = insets;
}

- (void)backgroundViewTapped
{
    [self.textView resignFirstResponder];
}

#pragma mark - Networking Methods

- (void)fetchThread
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
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@", kMainServerURL,self.threadID];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    
    RKManagedObjectRequestOperation *objectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    objectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    objectRequestOperation.managedObjectCache = managedObjectStore.managedObjectCache;
    objectRequestOperation.savesToPersistentStore = YES;
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"SUCCESS");
        //NSLog(@"mapping result : %@", mappingResult);
        PNThread *thread = [mappingResult.array objectAtIndex:0];
        self.managedObjectID = thread.objectID;
        self.thread = (PNThread *)[[PNCoreDataStack defaultStack].managedObjectContext existingObjectWithID:self.managedObjectID error:NULL];
        dispatch_async([self fetchStatusQueue], ^{
            self.fetchingStatus++;
            if (self.fetchingStatus == 2) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showSubViewsWithData];
                });
            }
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"FAIL");
    }];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:objectRequestOperation];
}

- (void)fetchCommentsWithCompletion:(void(^)(void))completion
{
    RKObjectMapping *commentMapping = [RKObjectMapping mappingForClass:[TMPComment class]];
    [commentMapping addAttributeMappingsFromDictionary:@{@"id": @"commentID",
                                                         @"like_count" : @"likeCount",
                                                         @"liked" : @"userLiked",
                                                         @"pub_date" : @"publishedDate",
                                                         @"comment_type" : @"commentType",
                                                         @"comment_user_id" : @"commenterID",
                                                         @"content" : @"content"}];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:commentMapping method:RKRequestMethodGET pathPattern:nil keyPath:@"data" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/comments", kMainServerURL,self.threadID];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
    
    RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        //Main Thread
        self.commentsArray = [mappingResult.array mutableCopy];
        completion();
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Operation failed With Error : %@", error);
    }];
    [objectRequestOperation start];
}


#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        if ([self.thread.imageURL isEqualToString:@""]) {
            return 1;
        } else return 2;
    } else if (section == 1) {
        return [self.commentsArray count];
    } else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            PNContentCell *cell = (PNContentCell *)[tableView dequeueReusableCellWithIdentifier:@"ContentCell" forIndexPath:indexPath];
            cell.contentLabel.text = self.thread.content;
            return cell;
        }
        if (indexPath.row == 1) {
            PNImageCell *cell = (PNImageCell *)[tableView dequeueReusableCellWithIdentifier:@"ImageCell" forIndexPath:indexPath];
            NSString *imageURL = self.thread.imageURL;
            if (self.thread.imageURL != nil){

                [PNPhotoController imageForURLString:imageURL completion:^(UIImage *image) {
                    cell.threadImageView.image = image;
                }];
            }
            return cell;
        }
    }
    
    if (indexPath.section == 1) {
        PNCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell" forIndexPath:indexPath];
        TMPComment *comment = (TMPComment *)self.commentsArray[indexPath.row];
        if ([comment.commentType integerValue] == PNCommentTypeNormal || [comment.commentType integerValue] == PNCommentTypeAuthor) {
            cell.rightUtilityButtons = [self rightButtons];
            cell.delegate = self;
        }
        [cell configureCellWithComment:comment];
        
        return cell;
    }
    
    return nil;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            PNContentCell *cell = [self.cells objectForKey:@"ContentCell"];
            if (!cell) {
                cell = [[PNContentCell alloc] init];
                [self.cells setObject:cell forKey:@"ContentCell"];
            }
            
            cell.contentLabel.text = self.thread.content;
            
            [cell updateConstraintsIfNeeded];
            [cell layoutIfNeeded];
            
            CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
            
            return height + 1;
        } else if (indexPath.row == 1) {
            return 320;
        }

    }
    if (indexPath.section == 1) {
        PNCommentCell *cell = [self.cells objectForKey:@"CommentCell"];
        if (!cell) {
            cell = [[PNCommentCell alloc] init];
            [self.cells setObject:cell forKey:@"CommentCell"];
        }
        
        TMPComment *comment = self.commentsArray[indexPath.row];
        
        //Configure the cell
        [cell configureCellWithComment:comment];
        
        //Layout Cell
        [cell updateConstraintsIfNeeded];
        [cell layoutIfNeeded];
        
        //Get the height
        CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        
        //one more pixel for the cell separator
        return height + 1;
    }
    return 130;
}

#pragma mark - SWTableViewCell delegate

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] title:@"신고"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:@"차단"];
    
    return rightUtilityButtons;
}

- (void)swipeableTableViewCell:(PNCommentCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            //REPORT COMMENT
            NSString *urlString = [NSString stringWithFormat:@"http://%@/comments/%@/report", kMainServerURL, cell.comment.commentID];
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
                    NSLog(@"REPORT COMMENT SUCCESS");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"신고 완료!" message:@"해당 댓글이 성공적으로 신고되었습니다" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [alertView show];
                    });
                } else {
                    //FAIL
                    NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
                    NSLog(@"Error : %@", error);
                }
            }];
            [task resume];
            break;
        }
        case 1:
        {
            //BLOCK COMMENT WRITER
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"사용자를 차단하면 되돌릴 수 없습니다.\n 계속하시겠습니까?" delegate:nil cancelButtonTitle:@"아니오" otherButtonTitles:@"예", nil];
            [alertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
                switch (buttonIndex) {
                    case 0:
                        NSLog(@"button index : %ld", (long)buttonIndex);
                        break;
                    case 1:
                    {
                        NSString *urlString = [NSString stringWithFormat:@"http://%@/comments/%@/block", kMainServerURL, cell.comment.commentID];
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
                                NSLog(@"BLOCK COMMENT WRITER SUCCESS");
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"차단 완료!" message:@"작성자를 차단했습니다.\n앞으로 이 유저의 글을 보지 않습니다." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                    [alertView show];
                                });
                            } else {
                                //FAIL
                                NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
                                NSLog(@"Error : %@", error);
                            }
                        }];
                        [task resume];
                        break;
                    }
                    default:
                        break;
                }
            }];
            break;
        }
        default:
            break;
    }
}


#pragma mark - HPGrowingTextViewDelegate

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
	CGRect r = self.containerView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	self.containerView.frame = r;
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    NSString *text = [growingTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([growingTextView.text isEqualToString:@""]) {
        self.postCommentButton.enabled = NO;
    } else if ([text length] == 0) {
        self.postCommentButton.enabled = NO;
    } else {
        self.postCommentButton.enabled = YES;
    }
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
