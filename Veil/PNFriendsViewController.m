//
//  PNFriendsViewControllerTMP.m
//  Veil
//
//  Created by soojin on 9/12/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNFriendsViewController.h"
#import "PNPhoneNumberFormatter.h"
#import "MSCellAccessory.h"
#import "PNCoreDataStack.h"
#import "Friend.h"
#import "PNFriendCell.h"
#import "GAIDictionaryBuilder.h"
#import "PNGuideViewController.h"

#define kProgressBarMiddle 0.8

@import AddressBook;

@interface PNFriendsViewController () <UITableViewDelegate, UITableViewDataSource, PNFriendCellDelegate, NSFetchedResultsControllerDelegate, UISearchDisplayDelegate, PNGuideViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *searchResults;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic) BOOL isSearching;

@property (retain, nonatomic) UIActivityIndicatorView *indicatorView;

@property (strong, nonatomic) PNGuideViewController *guideViewController;

@end

@implementation PNFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isSearching = NO;
    
    self.searchDisplayController.searchResultsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //self.searchDisplayController.searchBar.hidden = YES;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //self.tableView.scrollEnabled = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.indicatorView.center = CGPointMake(self.view.center.x, self.view.center.y-60);
    [self.view addSubview:self.indicatorView];
    
    [self.fetchedResultsController performFetch:nil];
    
    [self presentGuideViewController];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Google Analytics Screen tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Friends"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark - Lazy Instantiation

- (NSMutableArray *)searchResults
{
    if (!_searchResults) {
        _searchResults = [[NSMutableArray alloc] init];
    }
    
    return _searchResults;
}

- (PNGuideViewController *)guideViewController
{
    if (!_guideViewController) {
        _guideViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PNGuideViewController"];
        _guideViewController.delegate = self;
    }
    
    return _guideViewController;
}

#pragma mark - Helpers

- (void)rakeInUserContacts
{
    //If already loaded, just return
    BOOL loaded = [[NSUserDefaults standardUserDefaults] boolForKey:@"loadedContactsToCoreData"];
    if (loaded) {
        return;
    }
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
    
    PNPhoneNumberFormatter *phoneFormatter = [[PNPhoneNumberFormatter alloc] init];
    PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
    
    for (int i = 0 ; i < numberOfPeople ; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
        
        NSString *compositeName = (__bridge_transfer NSString*) ABRecordCopyCompositeName(person);
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        NSString *mainPhoneNumber = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
        if (mainPhoneNumber != nil) {
            NSString *strippedNumber = [phoneFormatter strip:mainPhoneNumber];
            Friend *friend = [NSEntityDescription insertNewObjectForEntityForName:@"Friend" inManagedObjectContext:coreDataStack.managedObjectContext];
            friend.name = compositeName;
            friend.phoneNumber = strippedNumber;
            friend.selected = [NSNumber numberWithBool:NO];
            friend.isAppUser = [NSNumber numberWithBool:NO];
        }
        CFRelease(phoneNumbers);
    }
    [coreDataStack saveContext];
    
    CFRelease(allPeople);
    CFRelease(addressBook);
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"loadedContactsToCoreData"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.tableView) return [self.fetchedResultsController.sections count];
    else if (tableView == self.searchDisplayController.searchResultsTableView) return 1;
    else return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.tableView) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    } else {
        //tableView == self.searchDisplayController.searchResultsTableView
        return [self.searchResults count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    PNFriendCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PNFriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (tableView == self.tableView) {
        // Configure the cell...
        [self configureCell:cell atIndexPath:indexPath];
    } else {
        Friend *friend = [self.searchResults objectAtIndex:indexPath.row];
        friend.observationInfo = nil;
        cell.nameLabel.text = friend.name;
        cell.phoneNumberLabel.text = friend.phoneNumber;
        cell.delegate = self;
        
        [friend addObserver:cell forKeyPath:@"selected" options:NSKeyValueObservingOptionNew context:NULL];
        
        if ([friend.isAppUser isEqualToNumber:[NSNumber numberWithBool:NO]]) cell.ifRegisteredLabel.hidden = YES;
        else cell.ifRegisteredLabel.hidden = NO;
        
        if ([friend.selected isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            cell.addFriendButton.hidden = YES;
        } else {
            cell.addFriendButton.hidden = NO;
        }
    }
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
        return [sectionInfo name];
    } else {
        return nil;
    }
}

- (void)configureCell:(PNFriendCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Friend *friend = [self.fetchedResultsController objectAtIndexPath:indexPath];
    friend.observationInfo = nil;
    cell.nameLabel.text = friend.name;
    cell.phoneNumberLabel.text = friend.phoneNumber;
    cell.delegate = self;
    
    [friend addObserver:cell forKeyPath:@"selected" options:NSKeyValueObservingOptionNew context:NULL];
    
    if ([friend.isAppUser isEqualToNumber:[NSNumber numberWithBool:NO]]) cell.ifRegisteredLabel.hidden = YES;
    else cell.ifRegisteredLabel.hidden = NO;
    
    if ([friend.selected isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        cell.addFriendButton.hidden = YES;
    } else {
        cell.addFriendButton.hidden = NO;
    }
}

#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        if ([self.fetchedResultsController.sections count] == 2 && indexPath.section == 0) {
            return UITableViewCellEditingStyleDelete;
        }
        return UITableViewCellEditingStyleNone;
    } else {
        Friend *friend = [self.searchResults objectAtIndex:indexPath.row];
        if ([friend.selected isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            return UITableViewCellEditingStyleDelete;
        } else return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Friends"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"destroy friend" value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
    __block Friend *friend = nil;
    __block PNFriendCell *cell = nil;
    
    if (tableView == self.tableView) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            // Delete the row from the data source
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            friend = [self.fetchedResultsController objectAtIndexPath:indexPath];
            cell = (PNFriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            
        }
    } else {
        //tableView == self.searchDisplayController.searchResultsTableView
        [self.searchDisplayController.searchResultsTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        friend = [self.searchResults objectAtIndex:indexPath.row];
        cell = (PNFriendCell *)[self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    }
    
    [cell.indicatorView startAnimating];
    [self deselectFriendRequest:friend completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([cell.indicatorView isAnimating]) [cell.indicatorView stopAnimating];
            friend.selected = [NSNumber numberWithBool:NO];
            [coreDataStack saveContext];
        });
    }];
}

#pragma mark - Search Method

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [self.searchResults removeAllObjects];
    
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", searchText];
    self.searchResults = [[self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:resultPredicate] mutableCopy];
}

#pragma mark - UISearchDisplayController delegate

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView
{
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Friends"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"search" label:nil value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    self.isSearching = YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
{
    self.isSearching = NO;
}

#pragma mark - NSFetchedResultsController and Delegate

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
    NSFetchRequest *fetchRequest = [self friendsFetchRequest];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:coreDataStack.managedObjectContext sectionNameKeyPath:@"sectionIdentifier" cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

- (NSFetchRequest *)friendsFetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Friend"];
    NSSortDescriptor *selectionSort = [NSSortDescriptor sortDescriptorWithKey:@"selected" ascending:NO];
    NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    fetchRequest.sortDescriptors = @[selectionSort, nameSort];
    
    return fetchRequest;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    [self.tableView setEditing:NO animated:NO];
    switch (type) {
        case NSFetchedResultsChangeUpdate:
            NSLog(@"update");
            break;
            
        case NSFetchedResultsChangeMove:
            //NSLog(@"move");
            if ([[self.fetchedResultsController.sections objectAtIndex:0] numberOfObjects] ==1 ) {
                //When there is only one person on the 'selected' section
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                //[self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            } else if ([self.fetchedResultsController.sections count] == 1) {
                //When the last contact is removed from the 'selected' section
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            }
            break;
            
        case NSFetchedResultsChangeInsert:
            NSLog(@"insert row");
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            NSLog(@"delete");
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark - PNFriendCellDelegate

- (void)addFriendOfCell:(PNFriendCell *)cell
{
    //Google Analytics Event Tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Friends"];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"touch" label:@"add friend" value:nil] build]];
    [tracker set:kGAIScreenName value:nil];
    
    PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
    NSIndexPath *indexPath = nil;
    __block Friend *friend = nil;
    if (self.isSearching == NO) {
        indexPath = [self.tableView indexPathForCell:cell];
        friend = [self.fetchedResultsController objectAtIndexPath:indexPath];
    } else {
        indexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:cell];
        friend = [self.searchResults objectAtIndex:indexPath.row];
    }
    
    [self selectFriendRequest:friend completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([cell.indicatorView isAnimating]) [cell.indicatorView stopAnimating];
            friend.selected = [NSNumber numberWithBool:YES];
            [coreDataStack saveContext];
        });
    }];
}

#pragma mark - HTTP Friend Request Methods

-(void)selectFriendRequest:(Friend *)friend completion:(void(^)(void))completion
{
    //friend == null
    [self sendFriendHTTPRequest:@"create" withFriends:@[friend.phoneNumber] completion:^{
        completion();
    }];
}

-(void)deselectFriendRequest:(Friend *)friend completion:(void(^)(void))completion
{
    [self sendFriendHTTPRequest:@"destroy" withFriends:@[friend.phoneNumber] completion:^{
        completion();
    }];
}

-(void)sendFriendHTTPRequest:(NSString *)method withFriends:(NSArray *)friends completion:(void(^)(void))completion
{
    NSError *error;
    NSDictionary *dic = [NSDictionary dictionaryWithObject:friends forKey:@"phone_numbers"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
    
    NSString *URLString = [NSString stringWithFormat:@"http://%@/friends/%@", kMainServerURL, method];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:data];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            NSLog(@"%@ friend SUCCESS", method);
            completion();
        }
    }];
    [task resume];
}

- (void)findRegisteredFriends
{
    NSMutableArray *phoneNumbers = [self friendsPhoneNumbersArray];

    NSError *error;
    NSDictionary *dic = [NSDictionary dictionaryWithObject:phoneNumbers forKey:@"phone_numbers"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
    
    NSString *URLString = [NSString stringWithFormat:@"http://%@/friends/get", kMainServerURL];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:data];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            NSArray *registeredFriends = [responseDic objectForKey:@"data"];
            
            float rate = (1-kProgressBarMiddle)/registeredFriends.count;
            
            for (NSString *phoneNumber in registeredFriends) {
                NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"phoneNumber == %@", phoneNumber];
                Friend *friend = [[self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:resultPredicate] firstObject];
                friend.isAppUser = [NSNumber numberWithBool:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.guideViewController increaseProgressByRate:rate];
                });
                NSLog(@"friend : %@", friend);
            }
            [[PNCoreDataStack defaultStack] saveContext];
        }
    }];
    [task resume];
}

- (NSMutableArray *)friendsPhoneNumbersArray {
    int totalFriendsNum = [self.fetchedResultsController.fetchedObjects count];
    float rate = kProgressBarMiddle/totalFriendsNum;
    NSMutableArray *phoneNumberArray = [[NSMutableArray alloc] init];
    
    for (int i = 0 ; i < totalFriendsNum ; i++) {
        Friend *friend = [self.fetchedResultsController.fetchedObjects objectAtIndex:i];
        [phoneNumberArray addObject:friend.phoneNumber];
        [self.guideViewController increaseProgressByRate:rate];
    }
    
    return phoneNumberArray;
}

#pragma mark - Guide Methods

- (void)presentGuideViewController
{
    [self addChildViewController:self.guideViewController];
    
    self.guideViewController.view.frame = [self frameForGuideController];
    
    [self.view insertSubview:self.guideViewController.view aboveSubview:self.tableView];
    
    [self.guideViewController didMoveToParentViewController:self];
}

- (CGRect)frameForGuideController
{
    return self.view.bounds;
}

#pragma mark - PNGuideViewDelegate

- (void)didAuthorizeAddressbook
{
    CGRect exOneRect = self.guideViewController.explanationOne.frame;
    CGRect exTwoRect = self.guideViewController.explanationTwo.frame;
    CGRect buttonRect = self.guideViewController.useContactsButton.frame;
    CGRect labelRect = self.guideViewController.loadingLabel.frame;
    CGRect indicatorRect = self.guideViewController.indicatorView.frame;
    CGRect progressBarRect = self.guideViewController.progressBar.frame;
    
    [UIView animateWithDuration:0.6f animations:^{
        //self.guideViewController.view.frame = CGRectMake(-2000, 0, CGRectGetWidth(self.guideViewController.view.frame), CGRectGetHeight(self.guideViewController.view.frame));
        self.guideViewController.explanationOne.frame = CGRectMake(-1200, CGRectGetMinY(self.guideViewController.explanationOne.frame), CGRectGetWidth(self.guideViewController.explanationOne.frame), CGRectGetHeight(self.guideViewController.explanationOne.frame));
        self.guideViewController.explanationTwo.frame = CGRectMake(-700, CGRectGetMinY(self.guideViewController.explanationTwo.frame), CGRectGetWidth(self.guideViewController.explanationTwo.frame), CGRectGetHeight(self.guideViewController.explanationTwo.frame));
        self.guideViewController.useContactsButton.frame = CGRectMake(-300, CGRectGetMinY(self.guideViewController.useContactsButton.frame), CGRectGetWidth(self.guideViewController.useContactsButton.frame), CGRectGetHeight(self.guideViewController.useContactsButton.frame));
    } completion:^(BOOL finished) {
        [self.guideViewController.explanationOne removeFromSuperview];
        [self.guideViewController.explanationTwo removeFromSuperview];
        [self.guideViewController.useContactsButton removeFromSuperview];
        
        [UIView animateWithDuration:0.5f animations:^{
            self.guideViewController.loadingLabel.frame = CGRectMake(62, self.guideViewController.loadingLabel.frame.origin.y,
                                                                     CGRectGetWidth(self.guideViewController.loadingLabel.frame), CGRectGetHeight(self.guideViewController.loadingLabel.frame));
            self.guideViewController.indicatorView.frame = CGRectMake(249, self.guideViewController.loadingLabel.frame.origin.y,
                                                                      CGRectGetWidth(self.guideViewController.indicatorView.frame), CGRectGetHeight(self.guideViewController.indicatorView.frame));
            self.guideViewController.progressBar.frame = CGRectMake(62, self.guideViewController.progressBar.frame.origin.y,
                                                                    CGRectGetWidth(self.guideViewController.progressBar.frame), CGRectGetHeight(self.guideViewController.progressBar.frame));
            
        } completion:^(BOOL finished) {

            /*
            [self.guideViewController.indicatorView startAnimating];
            
            [self rakeInUserContacts];
            [self.fetchedResultsController performFetch:nil];
            [self findRegisteredFriends];
             */
        }];
    }];
}


@end
