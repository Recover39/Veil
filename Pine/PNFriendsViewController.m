//
//  PNFriendsViewController.m
//  Pine
//
//  Created by soojin on 6/12/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNFriendsViewController.h"
#import "PNPhoneNumberFormatter.h"
#import "TMPPerson.h"
#import "MSCellAccessory.h"
@import AddressBook;

@interface PNFriendsViewController ()

@property (strong, nonatomic) NSMutableArray *allPeople;
@property (strong, nonatomic) NSMutableArray *searchResults;
@property (strong, nonatomic) NSMutableArray *selectedPeople;

@end

@implementation PNFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
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
                NSLog(@"granted");
                [weakSelf rakeInUserContacts];
                [weakSelf.tableView reloadData];
            });
            break;
        }
        case kABAuthorizationStatusDenied:
        case kABAuthorizationStatusRestricted:
        {
            //Do something to encourage user to allow access to his/her contacts
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *cantAccessContactAlert = [[UIAlertView alloc] initWithTitle:nil message: @"연락처에 대한 접근 권한을 허용해주세요" delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
                [cantAccessContactAlert show];
            });
            break;
        }
        case kABAuthorizationStatusAuthorized:
        {
            //Authorized
            NSLog(@"authorized");
            if ([self.allPeople count] == 0) {
                [self rakeInUserContacts];
                [self.tableView reloadData];
            }
        }
        default:
            break;
    }
}

- (NSMutableArray *)allPeople
{
    if (!_allPeople) {
        _allPeople = [[NSMutableArray alloc] init];
    }
    
    return _allPeople;
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
    NSLog(@"rake in");
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
    
    PNPhoneNumberFormatter *phoneFormatter = [[PNPhoneNumberFormatter alloc] init];
    
    for (int i = 0 ; i < numberOfPeople ; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
        
        NSString *compositeName = (__bridge_transfer NSString*) ABRecordCopyCompositeName(person);
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        NSString *mainPhoneNumber = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
        if (mainPhoneNumber != nil) {
            NSString *strippedNumber = [phoneFormatter strip:mainPhoneNumber];
            TMPPerson *person = [[TMPPerson alloc] init];
            person.name = compositeName;
            person.phoneNumber = strippedNumber;
            [self.allPeople addObject:person];
        }
        CFRelease(phoneNumbers);
    }
    
    //Sort Array
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [self.allPeople sortUsingDescriptors:@[sortDescriptor]];
    
    //한글-영문-숫자-특수문자 순으로 정렬
    self.allPeople = [[self.allPeople sortedArrayUsingSelector:@selector(sortForIndex:)] mutableCopy];
    
    CFRelease(allPeople);
    CFRelease(addressBook);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.searchDisplayController.searchResultsTableView) return 1;
    else return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.searchResults count];
    } else {
        if (section == 0) return [self.selectedPeople count];
        else if (section == 1) return [self.allPeople count];
        else return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    TMPPerson *person = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        person = [self.searchResults objectAtIndex:indexPath.row];
    } else {
        if (indexPath.section == 0) {
            person = [self.selectedPeople objectAtIndex:indexPath.row];
        } else if (indexPath.section == 1) {
            person = [self.allPeople objectAtIndex:indexPath.row];
            cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_PLUS_INDICATOR color:[UIColor redColor]];
        } else {
            person = nil;
        }
    }
    
    cell.textLabel.text = person.name;
    cell.detailTextLabel.text = person.phoneNumber;
    
    return cell;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView != self.searchDisplayController.searchResultsTableView) {
        if (section == 0) {
            return @"선택한 사람들";
        } else if (section == 1) {
            return @"연락처 사람들";
        } else return @"";
    } else {
        return nil;
    }
}

#pragma mark - Search Method

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [self.searchResults removeAllObjects];
    
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
    
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", searchText];
    self.searchResults = [[self.selectedPeople filteredArrayUsingPredicate:resultPredicate] mutableCopy];
    [self.searchResults addObjectsFromArray:[self.allPeople filteredArrayUsingPredicate:resultPredicate]];
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

#pragma mark - 초성 검색 메서드

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

- (IBAction)didInviteBarButtonItemPressed:(UIBarButtonItem *)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"초대하기" delegate:nil cancelButtonTitle:@"취소" destructiveButtonTitle:nil otherButtonTitles:@"SMS로 초대", @"이메일로 초대", nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}
@end
