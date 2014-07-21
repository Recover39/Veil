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

@interface PNThreadDetailViewController () <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *commentsArray;

@property (strong, nonatomic) IBOutlet UITextView *commentTextView;
@property (strong, nonatomic) IBOutlet UIButton *postCommentButton;
@property (strong, nonatomic) IBOutlet UIView *commentComposeView;

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
    [self registerForKeyboardNotifications];
    self.postCommentButton.enabled = NO;
    
    self.commentTextView.delegate = self;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewTapped)];
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    self.tableView = [[UITableView alloc] init];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.backgroundColor = [UIColor blueColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.view insertSubview:self.tableView atIndex:0];
}

- (void)viewDidLayoutSubviews
{
    self.tableView.frame = self.view.frame;
    UIEdgeInsets newInsets = self.tableView.contentInset;
    newInsets.bottom += CGRectGetHeight(self.commentComposeView.frame);
    self.tableView.contentInset = newInsets;
    
    //Design the text view (rounded corners)
    [self.commentTextView.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
    [self.commentTextView.layer setBorderWidth:2.0];
    self.commentTextView.layer.cornerRadius = 5;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self fetchComments];
    
    /*
    CGRect tableFrame = self.tableView.frame;
    CGPoint tableOffset = self.tableView.contentOffset;
    UIEdgeInsets tableInsets = self.tableView.contentInset;
    CGRect tableBounds = self.tableView.bounds;
    
    
    NSLog(@"tableView frame : (%f, %f, %f, %f)", tableFrame.origin.x, tableFrame.origin.y, tableFrame.size.width, tableFrame.size.height);
    NSLog(@"tableView offset : %f, %f", tableOffset.x, tableOffset.y);
    NSLog(@"tableView inset : %f, %f, %f, %f", tableInsets.left, tableInsets.right, tableInsets.top, tableInsets.bottom);
    NSLog(@"tableView bounds : (%f, %f, %f, %f)", tableBounds.origin.x, tableBounds.origin.y, tableBounds.size.width, tableBounds.size.height);
     */
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions
- (IBAction)postCommentButtonPressed:(UIButton *)sender
{
    NSError *error;
    NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/comments", kMainServerURL, self.thread.threadID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSDictionary *contentDictionary = @{@"user": kUserID,
                                        @"content" : self.commentTextView.text};
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
        if (!error && [httpResponse statusCode] == 200) {
            int commentCount = [self.thread.commentCount intValue];
            self.thread.commentCount = [NSNumber numberWithInt:++commentCount];
            [self fetchComments];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.commentTextView.text = @"";
            });
        } else {
            NSLog(@"Error : %@", error);
        }
    }];
    [task resume];
}

#pragma mark - Helpers

- (void)fetchComments
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
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/threads/%@/comments?user=%@", kMainServerURL,self.thread.threadID, kUserID];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
    
    RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        //Return the array to completion block
        self.commentsArray = [mappingResult.array mutableCopy];
        //NSLog(@"comments Array : %@", self.commentsArray);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Operation failed With Error : %@", error);
    }];
    [objectRequestOperation start];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    //Get the keyboard size
    NSDictionary *userInfo = [notification userInfo];
    CGFloat kbHeight = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    
    //Set the animation
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        CGRect newFrame = self.commentComposeView.frame;
        newFrame.origin.y -= (kbHeight - self.tabBarController.tabBar.frame.size.height);
        self.commentComposeView.frame = newFrame;
    }];
    [UIView commitAnimations];
    
    //Adjust tableview inset
    UIEdgeInsets newInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, kbHeight, 0.0);
    self.tableView.contentInset = newInsets;
    self.tableView.scrollIndicatorInsets = newInsets;
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    //Get the keyboard size
    NSDictionary *userInfo = [notification userInfo];
    CGFloat kbHeight = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    
    //Adjust tableview inset
    UIEdgeInsets newInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, 0.0, 0.0);
    self.tableView.scrollIndicatorInsets = newInsets;
    
    //Set the animation
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        CGRect newFrame = self.commentComposeView.frame;
        newFrame.origin.y += (kbHeight - self.tabBarController.tabBar.frame.size.height);
        self.commentComposeView.frame = newFrame;
        self.tableView.contentInset = newInsets;
    }];
    [UIView commitAnimations];
    
    
}

- (void)backgroundViewTapped
{
    [self.commentTextView resignFirstResponder];
}

#pragma mark - UITextView delegate

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        self.postCommentButton.enabled = NO;
    } else {
        self.postCommentButton.enabled = YES;
    }
    
    CGFloat maxHeight = 160.0f;
    CGFloat fixedWidth = textView.frame.size.width;
    CGFloat currentHeight = textView.frame.size.height;
    
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, currentHeight)];
    CGFloat changedHeight = newSize.height - currentHeight;
    
    if (changedHeight != 0 && newSize.height < maxHeight) {
        //TextView frame
        CGRect newFrame = textView.frame;
        newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), fminf(newSize.height, maxHeight));
        newFrame.origin.y -= changedHeight;
        textView.frame = newFrame;
    }
}

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
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.text = self.thread.content;
        }
        if (indexPath.row == 1) {
            [PNPhotoController imageForThread:self.thread completion:^(UIImage *image) {
                cell.imageView.image = image;
            }];
        }
    }
    
    if (indexPath.section == 1) {
        TMPComment *comment = (TMPComment *)self.commentsArray[indexPath.row];
        cell.textLabel.text = comment.content;
    }
    
    return cell;
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
