//
//  PNFriendsViewController.m
//  Pine
//
//  Created by soojin on 6/12/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNFriendsViewController.h"
#import "PNPhoneNumberFormatter.h"
#import "MSCellAccessory.h"
#import "PNCoreDataStack.h"
#import "Friend.h"
#import "PNFriendCell.h"
#import "GAIDictionaryBuilder.h"

@import AddressBook;

@interface PNFriendsViewController () <PNFriendCellDelegate, NSFetchedResultsControllerDelegate, UISearchDisplayDelegate>

@property (strong, nonatomic) NSMutableArray *searchResults;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic) BOOL isSearching;

@end

@implementation PNFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.isSearching = NO;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Google Analytics Screen tracking
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Friends"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    PNFriendsViewController * __weak weakSelf = self;
    
    switch (ABAddressBookGetAuthorizationStatus()) {
        case kABAuthorizationStatusNotDetermined:
        {
            ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
                if (!granted) return;
                //GRANTED
                [weakSelf rakeInUserContacts];
                [weakSelf.fetchedResultsController performFetch:NULL];
                [weakSelf.tableView reloadData];
            });
            break;
        }
        case kABAuthorizationStatusAuthorized:
        {
            //Authorized
            if ([self.fetchedResultsController.fetchedObjects count] == 0) {
                //this is when the user denies the first request and changes the settings afterward.
                [weakSelf rakeInUserContacts];
                [weakSelf.fetchedResultsController performFetch:NULL];
                [weakSelf.tableView reloadData];
            }
            break;
        }
        case kABAuthorizationStatusDenied:
        case kABAuthorizationStatusRestricted:
        {
            //Do something to encourage user to allow access to his/her contacts
            UIAlertView *cantAccessContactAlert = [[UIAlertView alloc] initWithTitle:nil message: @"연락처에 대한 접근 권한을 허용해주세요" delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
            [cantAccessContactAlert show];
            
            break;
        }
        
        default:
            break;
    }
}

- (NSMutableArray *)searchResults
{
    if (!_searchResults) {
        _searchResults = [[NSMutableArray alloc] init];
    }
    
    return _searchResults;
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
        }
        CFRelease(phoneNumbers);
    }
    [coreDataStack saveContext];

    CFRelease(allPeople);
    CFRelease(addressBook);
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"loadedContactsToCoreData"];
}

//초성 검색
- (NSString *)getUTF8String:(NSString *)hangeulString
{
    NSArray *choSung = [[NSArray alloc] initWithObjects:@"ㄱ", @"ㄲ", @"ㄴ", @"ㄷ", @"ㄸ", @"ㄹ", @"ㅁ", @"ㅂ", @"ㅃ", @"ㅅ", @"ㅆ", @"ㅇ", @"ㅈ", @"ㅉ", @"ㅊ", @"ㅋ", @"ㅌ", @"ㅍ", @"ㅎ", nil];
    //NSArray *joongSung = [[NSArray alloc] initWithObjects:@"ㅏ",@"ㅐ",@"ㅑ",@"ㅒ",@"ㅓ",@"ㅔ",@"ㅕ",@"ㅖ",@"ㅗ",@"ㅘ",@" ㅙ",@"ㅚ",@"ㅛ",@"ㅜ",@"ㅝ",@"ㅞ",@"ㅟ",@"ㅠ",@"ㅡ",@"ㅢ",@"ㅣ",nil];
    //NSArray *jongSung = [[NSArray alloc] initWithObjects:@"",@"ㄱ",@"ㄲ",@"ㄳ",@"ㄴ",@"ㄵ",@"ㄶ",@"ㄷ",@"ㄹ",@"ㄺ",@"ㄻ",@" ㄼ",@"ㄽ",@"ㄾ",@"ㄿ",@"ㅀ",@"ㅁ",@"ㅂ",@"ㅄ",@"ㅅ",@"ㅆ",@"ㅇ",@"ㅈ",@"ㅊ",@"ㅋ",@" ㅌ",@"ㅍ",@"ㅎ",nil];
    
    NSString *returnString = @"";
    
    for (int i = 0 ; i < [hangeulString length] ; i++) {
        NSInteger code = [hangeulString characterAtIndex:i];
        if (code >= 0xAC00 && code <= 0xD7A3) { //유니코드 한글 영역에서만 처리
            NSInteger uniCode = code - 0xAC00; //한글 시작 영역을 제거
            NSInteger choSungIndex = uniCode / 21 / 28; //초성
            //NSInteger joongSungIndex = uniCode%(21*28)/28; //중성
            //NSInteger jongSungIndex = uniCode%28; //종성
            //returnString = [NSString stringWithFormat:@"%@%@%@%@", returnString, [choSung objectAtIndex:choSungIndex], [joongSung objectAtIndex:joongSungIndex], [jongSung objectAtIndex:jongSungIndex]];
            returnString = [NSString stringWithFormat:@"%@%@", returnString, [choSung objectAtIndex:choSungIndex]];
        } else {
            returnString = [NSString stringWithFormat:@"%@%@", returnString, [hangeulString substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    
    return returnString;
}


#pragma mark - NSFetchedResultsController and delegate

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

#pragma mark - PNFriendCell delegate

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
    
    /* 초성검색
    //검색 문자열을 초성 문자열로 변환
    NSString *searchString = [self getUTF8String:searchText];
    
    //for 루프로 확인
    for (TMPPerson *person in self.allPeople) {
        NSString *personName = [self getUTF8String:person.name];
        BOOL found = [personName rangeOfString:searchString].location != NSNotFound;
        if (found) {
            [self.searchResults addObject:person];
        }
    }
    */
    
    //NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", searchText];
    //self.searchResults = [[self.selectedPeople filteredArrayUsingPredicate:resultPredicate] mutableCopy];
    //[self.searchResults addObjectsFromArray:[self.allPeople filteredArrayUsingPredicate:resultPredicate]];
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

#pragma mark - HTTP Request methods

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


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
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
