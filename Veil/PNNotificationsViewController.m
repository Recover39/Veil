//
//  PNNotificationsViewController.m
//  Pine
//
//  Created by soojin on 8/21/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNNotificationsViewController.h"
#import "PNCoreDataStack.h"
#import "PNNotificationCell.h"
#import "PNNotification.h"
#import "PNThreadDetailViewController.h"
#import "PNPhotoController.h"
#import "GAIDictionaryBuilder.h"
#import "NSDate+NVTimeAgo.h"

@interface PNNotificationsViewController () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PNNotificationsViewController

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
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.backgroundColor = [UIColor lightGrayColor];
    
    //This line removes extra separator lines in tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //self.tabBarItem doesn't work.. why??
    self.navigationController.tabBarItem.badgeValue = nil;
    
    //Google Analytics Screen tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Notification"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];

}

#pragma mark - NSFetchedResultsController

- (NSFetchRequest *)notificationsFetchRequest {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PNNotification"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
    fetchRequest.fetchLimit = 15;
    
    return fetchRequest;
}

- (NSFetchedResultsController *)fetchedResultsController{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
    NSFetchRequest *fetchRequest = [self notificationsFetchRequest];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:coreDataStack.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.fetchedResultsController.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    // Return the number of rows in the section.
    return [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PNNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(PNNotificationCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    PNNotification *notification = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.contentLabel.text = notification.content;
    cell.dateLabel.text = [notification.date formattedAsTimeAgo];
    
    if ([notification.imageURL length] == 0) {
        [cell setDefaultImage];
    }
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [PNPhotoController imageForURLString:notification.imageURL completion:^(UIImage *image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (image == nil) {
                        [cell setDefaultImage];
                    } else {
                        [cell setPostImage:image];
                    }
                    [cell setNeedsLayout];
                });
            }];
        });
    }
    
    if ([notification.isRead boolValue]) {
        cell.backgroundColor = [UIColor whiteColor];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:224/255.0f green:224/255.0f blue:224/255.0f alpha:1.0f];
    }   
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Notification"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"notification" value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    PNNotification *selectedNoti = [self.fetchedResultsController objectAtIndexPath:indexPath];
    selectedNoti.isRead = [NSNumber numberWithBool:YES];
    [[PNCoreDataStack defaultStack] saveContext];
    [self performSegueWithIdentifier:@"notificationToDetailSegue" sender:indexPath];
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
            NSLog(@"insert");
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            NSLog(@"delete");
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            NSLog(@"update");
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            NSLog(@"move");
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
    }
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"notificationToDetailSegue"]) {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        PNNotification *notification = [self.fetchedResultsController objectAtIndexPath:indexPath];
        PNThreadDetailViewController *nextVC = segue.destinationViewController;
        nextVC.threadID = notification.threadID;
    }
}


@end
