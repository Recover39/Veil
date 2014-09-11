//
//  PNSettingsController.m
//  Veil
//
//  Created by soojin on 8/23/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNSettingsController.h"
#import "GAIDictionaryBuilder.h"

@interface PNSettingsController ()
{
    BOOL _initialValue;
}
@property (weak, nonatomic) IBOutlet UISwitch *pushNotificationSwitch;

@end

@implementation PNSettingsController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"delete cookie" style:UIBarButtonItemStylePlain target:self action:@selector(deleteCookie)];
    
    //Remove unneccessary separators
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    _initialValue = [[NSUserDefaults standardUserDefaults] boolForKey:kShouldRegisterPushKey];
    if (_initialValue) {
        [self.pushNotificationSwitch setOn:YES animated:NO];
    } else {
        [self.pushNotificationSwitch setOn:NO animated:NO];
    }
}

- (void)deleteCookie
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", kMainServerURL]]];
    if (cookies.count > 0) {
        NSHTTPCookie *cookie = [cookies firstObject];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Google Analytics Screen tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Settings"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_initialValue == self.pushNotificationSwitch.on) return;
    
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Settings"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"change" label:@"push notification" value:[NSNumber numberWithBool:self.pushNotificationSwitch.on]] build]];
    [tracker set:kGAIScreenName value:nil];
    
    if (self.pushNotificationSwitch.on) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShouldRegisterPushKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [self unregisterUserForPush];
    }
}

- (void)unregisterUserForPush
{
    NSString *URLString = [NSString stringWithFormat:@"http://%@/users/register/push", kMainServerURL];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSMutableDictionary *content = [[NSMutableDictionary alloc] init];
    [content setObject:@"ios" forKey:@"device_type"];
    [content setObject:@"" forKey:@"push_id"];
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:content options:0 error:NULL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:contentData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //Completion Block
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShouldRegisterPushKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            NSLog(@"unregister push to server success");
        }
    }];
    [task resume];
}

/*
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}
*/

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
