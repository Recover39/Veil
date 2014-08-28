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
#import "PNNotificationDetailViewController.h"
#import "PNPhotoController.h"

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
    
    UIBarButtonItem *deleteAllNotification = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deleteAllNotifications)];
    self.navigationItem.leftBarButtonItem = deleteAllNotification;
    UIBarButtonItem *date = [[UIBarButtonItem alloc] initWithTitle:@"date   " style:UIBarButtonItemStylePlain target:self action:@selector(logDate)];
    self.navigationItem.rightBarButtonItem = date;
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    //This line removes extra separator lines in tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
}

- (void)logDate
{
    NSLog(@"date : %@", [NSDate date]);
}

- (void)deleteAllNotifications
{
    PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PNNotification"];
    fetchRequest.includesPropertyValues = NO;
    
    NSArray *notifications = [coreDataStack.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    for (PNNotification *notification in notifications) {
        [coreDataStack.managedObjectContext deleteObject:notification];
    }
    [coreDataStack saveContext];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //self.tabBarItem doesn't work.. why??
    self.navigationController.tabBarItem.badgeValue = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - NSFetchedResultsController

- (NSFetchRequest *)notificationsFetchRequest {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PNNotification"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
    
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
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceTokenForDateFormatter;
    dispatch_once(&onceTokenForDateFormatter, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterFullStyle];
    });
    
    PNNotification *notification = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.contentLabel.text = notification.content;
    cell.dateLabel.text = [_dateFormatter stringFromDate:notification.date];
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
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    PNNotification *selectedNoti = [self.fetchedResultsController objectAtIndexPath:indexPath];
    selectedNoti.isRead = [NSNumber numberWithBool:YES];
    [[PNCoreDataStack defaultStack] saveContext];
    [self performSegueWithIdentifier:@"notificationDetailSegue" sender:indexPath];
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
    if ([segue.identifier isEqualToString:@"notificationDetailSegue"]) {
        NSIndexPath *indexPath = sender;
        PNNotificationDetailViewController *nextVC = segue.destinationViewController;
        nextVC.notification = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
}


@end
