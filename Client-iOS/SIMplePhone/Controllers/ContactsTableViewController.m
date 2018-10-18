//
//  ContactsTableViewController.m
//  SIMplePhone
//
//  Created by Lukas Kuster on 09.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

#import "ContactsTableViewController.h"
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>
#import "SIMplePhone-Swift.h"

@interface ContactsTableViewController () <UITableViewDataSource, UITableViewDelegate, UISearchControllerDelegate>
    
    @property (nonatomic, strong) NSMutableArray *groupOfContacts;

    @property (nonatomic, strong) NSDictionary *orderedContacts;
    @property (nonatomic, strong) NSArray *sortedContactKeys;
    
    
@end

@implementation ContactsTableViewController

- (void)viewDidLoad {
    self.groupOfContacts = [@[] mutableCopy];
    [self getAllContact];
    
    self.title = @"Contacts";
    
    UISearchController *search = [[UISearchController alloc] initWithSearchResultsController:self];
    [self.navigationItem setSearchController:search];
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    
//    NSDate *now = [[NSDate alloc] init];
//    
//    CNPhoneNumber *number = [[CNPhoneNumber alloc] initWithStringValue:@"+436641817908"];
//    
//    Voicemail *voicemail = [[Voicemail alloc] initWithDate:now origin:number audio:@"/test.m4a"];
//    
//    NSLog(@"%@", voicemail);
    
    [super viewDidLoad];
}
    
- (void)getAllContact {
    if([CNContactStore class]) {
        CNContactStore *addressBook = [[CNContactStore alloc] init];
        
        NSArray *keysToFetch =@[CNContactIdentifierKey,
                                CNContactEmailAddressesKey,
                                CNContactFamilyNameKey,
                                CNContactGivenNameKey,
                                CNContactPhoneNumbersKey,
                                CNContactPostalAddressesKey,
                                CNContactViewController.descriptorForRequiredKeys];
        
        CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
        fetchRequest.mutableObjects = NO;
        fetchRequest.unifyResults = YES;
        fetchRequest.sortOrder = CNContactSortOrderUserDefault;
        [addressBook enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
           
            [self.groupOfContacts addObject:contact];
            
            
            
            NSString *letter = [[CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName] substringToIndex:1];
            
            [[self.orderedContacts objectForKey:letter] addObject:contact];
            
        }];
    }
    NSLog(@"%@", [self.orderedContacts objectForKey:@"A"]);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.groupOfContacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
  
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    CNContact *contact = [self.groupOfContacts objectAtIndex:indexPath.row];
    
    
    NSAttributedString *displayString = [CNContactFormatter attributedStringFromContact:contact style:CNContactFormatterStyleFullName defaultAttributes:nil];
    cell.textLabel.attributedText = displayString;
    
    return cell;
}
    
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CNContact *selectedContact = [self.groupOfContacts objectAtIndex:indexPath.row];
    NSLog(@"%@", selectedContact);
    CNContactViewController *contactView = [CNContactViewController viewControllerForContact:selectedContact];
    [self.navigationController pushViewController:contactView animated:YES];
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
