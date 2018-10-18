//
//  ChatsTableViewController.m
//  SIMplePhone
//
//  Created by Lukas Kuster on 11.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

#import "ChatsTableViewController.h"
#import "ChatPreviewTableViewCell.h"
#import "../Models/SMSChat.h"
#import <Contacts/Contacts.h>

@interface ChatsTableViewController () <UISearchControllerDelegate>

@property (nonatomic, strong) NSMutableArray *chats;
    
@end

@implementation ChatsTableViewController
    
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.chats = [@[] mutableCopy];

    [self getAllContact];
    
    NSLog(@"%@", self.chats);
    
    for (SMSChat* o in self.chats) {
        CNContact* contact = o.otherParty;
        NSLog(@"%@", contact);
    }
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UISearchController *search = [[UISearchController alloc] initWithSearchResultsController:self];
    [self.navigationItem setSearchController:search];
    
    
}
    
- (void)getAllContact {
    if([CNContactStore class]) {
        CNContactStore *addressBook = [[CNContactStore alloc] init];
        
        NSArray *keysToFetch =@[CNContactIdentifierKey,
                                CNContactEmailAddressesKey,
                                CNContactFamilyNameKey,
                                CNContactGivenNameKey,
                                CNContactPhoneNumbersKey,
                                CNContactPostalAddressesKey];
        
        CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
        fetchRequest.mutableObjects = NO;
        fetchRequest.predicate = [CNContact predicateForContactsMatchingName:@"Breznik"];
        fetchRequest.unifyResults = YES;
        fetchRequest.sortOrder = CNContactSortOrderUserDefault;
        [addressBook enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            
            [self.chats addObject:[[SMSChat alloc] initWithOtherParty:contact]];
            
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return [self.chats count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatPreviewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatPreviewCell" forIndexPath:indexPath];
    
    [cell setChat:[self.chats objectAtIndex:indexPath.row]];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
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
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
