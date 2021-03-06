//
//  PNThreadDetailViewController.m
//  Pine
//
//  Created by soojin on 7/15/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNThreadDetailViewController.h"
#import "PNThread.h"
#import "PNImageCell.h"
#import "TMPComment.h"
#import "PNPhotoController.h"
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "PNCommentCell.h"
#import "PNContentCell.h"
#import "UIAlertView+NSCookBook.h"
#import "HPGrowingTextView.h"
#import "PNCoreDataStack.h"
#import "GAIDictionaryBuilder.h"
#import "UIActionSheet+Blocks.h"

@interface PNThreadDetailViewController () <UITableViewDataSource, UITableViewDelegate, SWTableViewCellDelegate, HPGrowingTextViewDelegate>

@property (strong, nonatomic) NSManagedObjectID *managedObjectID;
@property (strong, nonatomic) PNThread *thread;

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *commentsArray;

@property (strong, nonatomic) IBOutlet UIButton *postCommentButton;
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) HPGrowingTextView *textView;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

//Footer View
@property (weak, nonatomic) IBOutlet UIView *myFooterView;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *reportButton;


//This is used in -heightForRowAtIndexPath: method
@property (strong, nonatomic) NSMutableDictionary *cells;

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
    self.cells = [[NSMutableDictionary alloc] initWithCapacity:4];
    self.postCommentButton.enabled = NO;
    [self.likeButton setImage:[UIImage imageNamed:@"ic_like"] forState:UIControlStateSelected];
    
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.containerView.hidden = YES;
    
    [self setupGrowingTextView];
    [self addTapGestureToBackground];
    [self setupTableView];
    
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.indicatorView.center = CGPointMake(self.view.center.x, self.view.center.y);
    [self.view addSubview:self.indicatorView];
    [self.indicatorView startAnimating];
    
    [self requestThreadWithCompletion:^{
        [self requestCommentsWithCompletion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showSubViewsWithData];
            });
        }];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
    
    //Google Analytics Screen tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Thread Detail"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
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
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Thread Detail"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"post comment" value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    [self.textView resignFirstResponder];
    self.postCommentButton.hidden = YES;
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicatorView.frame = CGRectMake(274, 13, 20, 20);
    [self.containerView addSubview:indicatorView];
    [indicatorView startAnimating];
    
    NSString *content = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSError *error;
    NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/comments", kMainServerURL, self.thread.threadID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSDictionary *contentDictionary = @{@"content" : content};
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
            dispatch_async(dispatch_get_main_queue(), ^{
                self.commentCountLabel.text = [self.thread.commentCount stringValue];
            });
            
            [self requestCommentsWithCompletion:^{
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.commentsArray.count-1 inSection:1];
                [self.tableView reloadData];
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
    self.likeCountLabel.text = [self.thread.likeCount stringValue];
    self.commentCountLabel.text = [self.thread.commentCount stringValue];
    if ([self.thread.userLiked boolValue] == YES) {
        self.likeButton.selected = YES;
    } else {
        self.likeButton.selected = NO;
    }
    
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

- (void)requestThreadWithCompletion:(void(^)(void))completion
{
    NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@", kMainServerURL, self.threadID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setURL:url];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        NSLog(@"request thread %@", self.threadID);
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSError *JSONerror;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            //SUCCESS
            //NSLog(@"response : %@", responseDic);
            PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
            NSDictionary *threadDic = [responseDic objectForKey:@"data"];
            
            PNThread *existingThread = [self fetchThreadWithId:threadDic[@"id"]];
            if (existingThread) {
                NSLog(@"existing thread");
                //There is an existing thread
                if ([existingThread.commentCount isEqualToNumber:[threadDic objectForKey:@"comment"]] == NO) {
                    NSLog(@"comment count updated");
                    existingThread.commentCount = [threadDic objectForKey:@"comment"];
                }
                if ([existingThread.likeCount isEqualToNumber:[threadDic objectForKey:@"like_count"]] == NO) {
                    NSLog(@"like count updated");
                    existingThread.likeCount = [threadDic objectForKey:@"like_count"];
                }
                [coreDataStack saveContext];
                self.thread = existingThread;
            } else {
                NSLog(@"new thread");
                //This one is new thread from a friend, never got it before
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                
                PNThread *newThread = [NSEntityDescription insertNewObjectForEntityForName:@"PNThread" inManagedObjectContext:coreDataStack.managedObjectContext];
                newThread.threadID = threadDic[@"id"];
                newThread.type = threadDic[@"type"];
                newThread.likeCount = threadDic[@"like_count"];
                newThread.userLiked  = threadDic[@"liked"];
                newThread.publishedDate = [dateFormatter dateFromString:threadDic[@"pub_date"]];
                newThread.imageURL = threadDic[@"image_url"];
                newThread.content = threadDic[@"content"];
                newThread.commentCount = threadDic[@"comment"];
                [coreDataStack saveContext];
                self.thread = newThread;
            }
            
            completion();            
        } else {
            //FAIL
            NSLog(@"HTTP %ld Error", (long)[httpResponse statusCode]);
            NSLog(@"Error message : %@, result : :%@", responseDic[@"message"], responseDic[@"result"]);
        }
    }];
    [task resume];
}

- (PNThread *)fetchThreadWithId:(NSNumber *)threadID
{
    NSManagedObjectContext *moc = [[PNCoreDataStack defaultStack] managedObjectContext];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"PNThread" inManagedObjectContext:moc];
    NSFetchRequest *fetchReqeust = [[NSFetchRequest alloc] init];
    [fetchReqeust setEntity:entityDesc];
    
    NSPredicate *idPredicate = [NSPredicate predicateWithFormat:@"threadID == %@", threadID];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"publishedDate" ascending:YES];
    [fetchReqeust setPredicate:idPredicate];
    [fetchReqeust setSortDescriptors:@[sortDescriptor]];
    
    NSError *error;
    NSArray *array = [moc executeFetchRequest:fetchReqeust error:&error];
    
    if (array.count == 1) {
        return [array firstObject];
    } else {
        return nil;
    }
}

- (void)requestCommentsWithCompletion:(void(^)(void))completion
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
        if (self.thread) {
            self.thread.commentCount = @(self.commentsArray.count);
            [[PNCoreDataStack defaultStack] saveContext];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.commentCountLabel.text = [self.thread.commentCount stringValue];
        });
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

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return 15;
    }
    else return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return self.myFooterView;
    }
    
    else return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 1) {
        return 0;
    }
    else return CGRectGetHeight(self.myFooterView.bounds) + 1;
}

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
            return 321;
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
    return 0.0;
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
            //Google Analytics Event Tracking
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [tracker set:kGAIScreenName value:@"Thread Detail"];
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"report comment" value:nil] build]];
            [tracker set:kGAIScreenName value:nil];
            
            NSString *urlString = [NSString stringWithFormat:@"http://%@/comments/%@/report", kMainServerURL, cell.comment.commentID];
            NSURL *url = [NSURL URLWithString:urlString];
            NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
            [urlRequest setHTTPMethod:@"POST"];
            
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSError *JSONerror;
                NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
                NSLog(@"dic : %@", responseDic);
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
            
            //Google Analytics Event Tracking
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [tracker set:kGAIScreenName value:@"Thread Detail"];
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"block comment author" value:nil] build]];
            [tracker set:kGAIScreenName value:nil];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"사용자를 차단하면 되돌릴 수 없습니다.\n 계속하시겠습니까?" delegate:nil cancelButtonTitle:@"아니오" otherButtonTitles:@"예", nil];
            [alertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
                switch (buttonIndex) {
                    case 0:
                        break;
                    case 1:
                    {
                        NSString *urlString = [NSString stringWithFormat:@"http://%@/comments/%@/block", kMainServerURL, cell.comment.commentID];
                        NSURL *url = [NSURL URLWithString:urlString];
                        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
                        [urlRequest setHTTPMethod:@"POST"];
                        
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

#pragma mark - FooterView IBActions
- (IBAction)likeButtonPressed:(UIButton *)sender
{
    if (self.likeButton.selected) {
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
                    self.likeCountLabel.text = [self.thread.likeCount stringValue];
                    self.likeButton.selected = NO;
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
                    self.likeCountLabel.text = [self.thread.likeCount stringValue];
                    self.likeButton.selected = YES;
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
    [UIActionSheet showInView:self.view withTitle:nil cancelButtonTitle:@"취소" destructiveButtonTitle:nil otherButtonTitles:@[@"사용자 차단", @"악성글 신고"] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            //사용자 차단
            
            //Google Analytics Event Tracking
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [tracker set:kGAIScreenName value:@"Feed"];
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"block" value:nil] build]];
            [tracker set:kGAIScreenName value:nil];
            
            NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/block", kMainServerURL, self.threadID];
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
                    NSLog(@"response : %@", responseDic);
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
            
            NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/report", kMainServerURL, self.threadID];
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
