//
//  PNEntireFeedViewController.m
//  Pine
//
//  Created by soojin on 6/20/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNFeedContentViewController.h"
#import "PNPostCell.h"

@interface PNFeedContentViewController ()

@property (strong, nonatomic) NSMutableArray *feeds;
@property (strong, nonatomic) NSString *isFriend;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end

@implementation PNFeedContentViewController

- (NSMutableArray *)feeds
{
    if (!_feeds) {
        _feeds = [[NSMutableArray alloc] init];
    }
    
    return _feeds;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.pageIndex == 0) {
        self.isFriend = @"true";
    } else {
        self.isFriend = @"false";
    }
    
    self.tableView.separatorColor = [UIColor clearColor];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(updateFeeds) forControlEvents:UIControlEventValueChanged];

    [self updateFeeds];
}

#pragma mark - Helper methods

- (void)updateFeeds
{
    NSString *urlString = [NSString stringWithFormat:@"http://10.73.45.42:5000/threads?user=%d&is_friend=%@&offset=%d&limit=%d", 2, self.isFriend, 0, 20];
    NSURL *getURL = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:getURL];
    [urlRequest setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSError *error;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            self.feeds = [dictionary[@"data"] mutableCopy];
            //NSLog(@"feeds array : %@", self.feeds);
        } else {
            NSLog(@"error : %@", error);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            
            if ([self.refreshControl isRefreshing]) {
                [self.refreshControl endRefreshing];
            }
        });
    }];
    [task resume];
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
    return [self.feeds count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PNPostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    [cell configureCellForPost:self.feeds[indexPath.row]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


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
