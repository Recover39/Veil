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

#define kProgressBarMiddle 0.5

@import AddressBook;

@interface PNFriendsViewController () <UITableViewDelegate, UITableViewDataSource, PNFriendCellDelegate, NSFetchedResultsControllerDelegate, UISearchDisplayDelegate, PNGuideViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *searchResults;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

//Collection properties to hold the updates from NSFetchedResultsController
@property (strong, nonatomic) NSMutableIndexSet *deletedSectionIndexes;
@property (strong, nonatomic) NSMutableIndexSet *insertedSectionIndexes;
@property (strong, nonatomic) NSMutableArray *deletedRowIndexPaths;
@property (strong, nonatomic) NSMutableArray *insertedRowIndexPaths;
@property (strong, nonatomic) NSMutableArray *updatedRowIndexPaths;

@property (nonatomic) BOOL isSearching;

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
    
    [self.fetchedResultsController performFetch:nil];
    NSLog(@"initial fetched : %d", self.fetchedResultsController.fetchedObjects.count);
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"didUploadContacts"] == NO) {
        [self presentGuideViewController];
    }
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

- (NSMutableIndexSet *)deletedSectionIndexes
{
    if (_deletedSectionIndexes == nil) {
        _deletedSectionIndexes = [[NSMutableIndexSet alloc] init];
    }
    
    return _deletedSectionIndexes;
}

- (NSMutableIndexSet *)insertedSectionIndexes
{
    if (_insertedSectionIndexes == nil) {
        _insertedSectionIndexes = [[NSMutableIndexSet alloc] init];
    }
    
    return _insertedSectionIndexes;
}

- (NSMutableArray *)deletedRowIndexPaths
{
    if (_deletedRowIndexPaths == nil) {
        _deletedRowIndexPaths = [[NSMutableArray alloc] init];
    }
    
    return _deletedRowIndexPaths;
}

- (NSMutableArray *)insertedRowIndexPaths
{
    if (_insertedRowIndexPaths == nil) {
        _insertedRowIndexPaths = [[NSMutableArray alloc] init];
    }
    
    return _insertedRowIndexPaths;
}

- (NSMutableArray *)updatedRowIndexPaths
{
    if (_updatedRowIndexPaths == nil) {
        _updatedRowIndexPaths = [[NSMutableArray alloc] init];
    }
    
    return _updatedRowIndexPaths;
}

#pragma mark - Helpers

- (void)rakeInUserContacts
{
    NSLog(@"rake in");
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

/*
- (void)deleteAllContacts
{
    NSLog(@"start of delete contacts method");
    PNCoreDataStack *coreDataStack = [PNCoreDataStack defaultStack];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Friend"];
    [fetchRequest setIncludesPropertyValues:NO];
    
    NSError *error;
    NSArray *allFriends = [coreDataStack.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSLog(@"friend count(in delete) : %d", allFriends.count);
    if (allFriends.count > 0){
        for (Friend *friend in allFriends) {
            [coreDataStack.managedObjectContext deleteObject:friend];
        }
        
        [coreDataStack saveContext];
        NSLog(@"deleted");
    } else return;
}
*/

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
        
        if ([friend.isAppUser isEqualToNumber:[NSNumber numberWithBool:NO]]) {
            //가입 안되어 있는 친구
            cell.ifRegisteredLabel.hidden = YES;
        } else {
            //가입되어 있는 친구
            cell.ifRegisteredLabel.hidden = NO;
        }
        
        if ([friend.selected isEqualToNumber:[NSNumber numberWithBool:NO]] && [friend.isAppUser isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            //If friend is an app user and not selected, show add friend button
            cell.addFriendButton.hidden = NO;
        } else {
            cell.addFriendButton.hidden = YES;
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
    cell.nameLabel.text = friend.name;
    cell.phoneNumberLabel.text = friend.phoneNumber;
    cell.delegate = self;
    
    if ([friend.isAppUser isEqualToNumber:[NSNumber numberWithBool:NO]]) {
        //가입 안되어 있는 친구
        cell.ifRegisteredLabel.hidden = YES;
        cell.addFriendButton.hidden = YES;
    } else {
        //가입되어 있는 친구 중
        cell.ifRegisteredLabel.hidden = NO;
        
        if ([friend.selected isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            //가입 + 선택
            cell.addFriendButton.hidden = YES;
        } else {
            cell.addFriendButton.hidden = NO;
        }
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
        NSInteger num = [[NSUserDefaults standardUserDefaults] integerForKey:@"numberOfFriends"];
        [[NSUserDefaults standardUserDefaults] setInteger:--num forKey:@"numberOfFriends"];
        NSLog(@"num after deselect: %d", num);
        [[NSUserDefaults standardUserDefaults] synchronize];
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
    NSSortDescriptor *registeredSort = [NSSortDescriptor sortDescriptorWithKey:@"isAppUser" ascending:NO];
    NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    fetchRequest.sortDescriptors = @[selectionSort, registeredSort, nameSort];
    
    return fetchRequest;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.insertedSectionIndexes addIndex:sectionIndex];
            break;
        case NSFetchedResultsChangeDelete:
            [self.deletedSectionIndexes addIndex:sectionIndex];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    [self.tableView setEditing:NO animated:NO];
    switch (type) {
        case NSFetchedResultsChangeUpdate:
            [self.updatedRowIndexPaths addObject:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            if ([self.insertedSectionIndexes containsIndex:newIndexPath.section] == NO) {
                [self.insertedRowIndexPaths addObject:newIndexPath];
            }
            if ([self.deletedSectionIndexes containsIndex:indexPath.section] == NO) {
                [self.deletedRowIndexPaths addObject:indexPath];;
            }
            break;
        case NSFetchedResultsChangeInsert:
            if ([self.insertedSectionIndexes containsIndex:newIndexPath.section]) {
                //Skip it since it will be handled by the section insertion
                return;
            }
            [self.insertedRowIndexPaths addObject:newIndexPath];
            break;
            
        case NSFetchedResultsChangeDelete:
            if ([self.deletedSectionIndexes containsIndex:newIndexPath.section]) {
                //Skip it since it will be handled by the section deletion
                return;
            }
            [self.deletedRowIndexPaths addObject:indexPath];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger totalChanges = [self.deletedSectionIndexes count] +
        [self.insertedSectionIndexes count] +
        [self.deletedRowIndexPaths count] +
        [self.insertedRowIndexPaths count] +
        [self.updatedRowIndexPaths count];
        
        if (totalChanges > 50) {
            self.insertedSectionIndexes = nil;
            self.deletedSectionIndexes = nil;
            self.deletedRowIndexPaths = nil;
            self.insertedRowIndexPaths = nil;
            self.updatedRowIndexPaths = nil;
            
            [self.tableView reloadData];
            return;
        }
        
        [self.tableView beginUpdates];
        
        [self.tableView deleteSections:self.deletedSectionIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView insertSections:self.insertedSectionIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView deleteRowsAtIndexPaths:self.deletedRowIndexPaths withRowAnimation:UITableViewRowAnimationLeft];
        [self.tableView insertRowsAtIndexPaths:self.insertedRowIndexPaths withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView reloadRowsAtIndexPaths:self.updatedRowIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        self.insertedSectionIndexes = nil;
        self.deletedSectionIndexes = nil;
        self.insertedRowIndexPaths = nil;
        self.deletedRowIndexPaths = nil;
        self.updatedRowIndexPaths = nil;
    });
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
        NSInteger num = [[NSUserDefaults standardUserDefaults] integerForKey:@"numberOfFriends"];
        [[NSUserDefaults standardUserDefaults] setInteger:++num forKey:@"numberOfFriends"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"num after select: %d", num);
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
    NSMutableArray *phoneNumbers = [self friendsPhoneNumbersArray:YES];

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
            if (registeredFriends.count > 0 ) {
                float rate = (1-kProgressBarMiddle)/registeredFriends.count;
                
                for (NSString *phoneNumber in registeredFriends) {
                    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"phoneNumber == %@", phoneNumber];
                    Friend *friend = [[self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:resultPredicate] firstObject];
                    friend.isAppUser = [NSNumber numberWithBool:YES];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.guideViewController increaseProgressByRate:rate];
                    });
                }
                [[PNCoreDataStack defaultStack] saveContext];
            } else {
                //No friend
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.guideViewController increaseProgressByRate:(1-kProgressBarMiddle)];
                });
            }
            
            //finished
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didUploadContacts"];
            
            [self requestFriendsList];
        }
    }];
    [task resume];
}

- (void)requestFriendsList
{
    NSString *URLString = [NSString stringWithFormat:@"http://%@/friends/list", kMainServerURL];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([httpResponse statusCode] == 200 && [responseDic[@"result"] isEqualToString:@"pine"]) {
            NSArray *existingFriends = [responseDic objectForKey:@"data"];
            NSLog(@"existing friends : %@", existingFriends);
            if (existingFriends.count > 0 ) {
                [[NSUserDefaults standardUserDefaults] setInteger:existingFriends.count forKey:@"numberOfFriends"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                NSLog(@"num after request: %d", existingFriends.count);
                for (NSString *phoneNumber in existingFriends) {
                    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"phoneNumber == %@", phoneNumber];
                    Friend *friend = [[self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:resultPredicate] firstObject];
                    if (friend) {
                        friend.selected = [NSNumber numberWithBool:YES];
                    }
                }
                [[PNCoreDataStack defaultStack] saveContext];
            } else {
                //No friend yet
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.6f delay:0.3f options:0 animations:^{
                    self.guideViewController.loadingLabel.frame = CGRectMake(self.guideViewController.loadingLabel.frame.origin.x, -300,
                                                                             CGRectGetWidth(self.guideViewController.loadingLabel.frame), CGRectGetHeight(self.guideViewController.loadingLabel.frame));
                    self.guideViewController.indicatorView.frame = CGRectMake(self.guideViewController.indicatorView.frame.origin.x, -300,
                                                                              CGRectGetWidth(self.guideViewController.indicatorView.frame), CGRectGetHeight(self.guideViewController.indicatorView.frame));
                    self.guideViewController.progressBar.frame = CGRectMake(self.guideViewController.progressBar.frame.origin.x, 700,
                                                                            CGRectGetWidth(self.guideViewController.progressBar.frame), CGRectGetHeight(self.guideViewController.progressBar.frame));
                } completion:^(BOOL finished) {
                    //Remove controller
                    [self.guideViewController.view removeFromSuperview];
                    [self.guideViewController removeFromParentViewController];
                }];
            });
        }
    }];
    [task resume];
}

- (NSMutableArray *)friendsPhoneNumbersArray:(BOOL)shouldIncreaseProgress {
    int totalFriendsNum = [self.fetchedResultsController.fetchedObjects count];
    float rate = kProgressBarMiddle/totalFriendsNum;
    NSMutableArray *phoneNumberArray = [[NSMutableArray alloc] init];
    
    for (int i = 0 ; i < totalFriendsNum ; i++) {
        Friend *friend = [self.fetchedResultsController.fetchedObjects objectAtIndex:i];
        [phoneNumberArray addObject:friend.phoneNumber];
        if (shouldIncreaseProgress) [self.guideViewController increaseProgressByRate:rate];
    }
    
    return phoneNumberArray;
}

#pragma mark - Guide Methods

- (void)presentGuideViewController
{
    if (self.guideViewController) {
        [self.guideViewController willMoveToParentViewController:nil];
        [self.guideViewController.view removeFromSuperview];
        [self.guideViewController removeFromParentViewController];
    }
    
    [self addChildViewController:self.guideViewController];
    
    [self.guideViewController resetOutlets];
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
    /*
    CGRect exOneRect = self.guideViewController.explanationOne.frame;
    CGRect exTwoRect = self.guideViewController.explanationTwo.frame;
    CGRect buttonRect = self.guideViewController.useContactsButton.frame;
    CGRect labelRect = self.guideViewController.loadingLabel.frame;
    CGRect indicatorRect = self.guideViewController.indicatorView.frame;
    CGRect progressBarRect = self.guideViewController.progressBar.frame;
    */
    
    [UIView animateWithDuration:0.6f animations:^{
        //self.guideViewController.view.frame = CGRectMake(-2000, 0, CGRectGetWidth(self.guideViewController.view.frame), CGRectGetHeight(self.guideViewController.view.frame));
        self.guideViewController.explanationOne.frame = CGRectMake(-1200, CGRectGetMinY(self.guideViewController.explanationOne.frame), CGRectGetWidth(self.guideViewController.explanationOne.frame), CGRectGetHeight(self.guideViewController.explanationOne.frame));
        self.guideViewController.explanationTwo.frame = CGRectMake(-700, CGRectGetMinY(self.guideViewController.explanationTwo.frame), CGRectGetWidth(self.guideViewController.explanationTwo.frame), CGRectGetHeight(self.guideViewController.explanationTwo.frame));
        self.guideViewController.useContactsButton.frame = CGRectMake(-300, CGRectGetMinY(self.guideViewController.useContactsButton.frame), CGRectGetWidth(self.guideViewController.useContactsButton.frame), CGRectGetHeight(self.guideViewController.useContactsButton.frame));
    } completion:^(BOOL finished) {
        //[self.guideViewController.explanationOne removeFromSuperview];
        //[self.guideViewController.explanationTwo removeFromSuperview];
        //[self.guideViewController.useContactsButton removeFromSuperview];
        self.guideViewController.explanationOne.hidden = YES;
        self.guideViewController.explanationTwo.hidden = YES;
        self.guideViewController.useContactsButton.hidden = YES;
        
        [UIView animateWithDuration:0.5f animations:^{
            self.guideViewController.loadingLabel.frame = CGRectMake(62, self.guideViewController.loadingLabel.frame.origin.y,
                                                                     CGRectGetWidth(self.guideViewController.loadingLabel.frame), CGRectGetHeight(self.guideViewController.loadingLabel.frame));
            self.guideViewController.indicatorView.frame = CGRectMake(249, self.guideViewController.loadingLabel.frame.origin.y,
                                                                      CGRectGetWidth(self.guideViewController.indicatorView.frame), CGRectGetHeight(self.guideViewController.indicatorView.frame));
            self.guideViewController.progressBar.frame = CGRectMake(62, self.guideViewController.progressBar.frame.origin.y,
                                                                    CGRectGetWidth(self.guideViewController.progressBar.frame), CGRectGetHeight(self.guideViewController.progressBar.frame));
            
        } completion:^(BOOL finished) {
            [self.guideViewController.indicatorView startAnimating];
            [self rakeInUserContacts];
            [self.fetchedResultsController performFetch:nil];
            [self findRegisteredFriends];
        }];
    }];
}

#pragma mark - IBActions

- (IBAction)syncFriendList:(UIBarButtonItem *)sender
{
    [self presentGuideViewController];
}

@end
