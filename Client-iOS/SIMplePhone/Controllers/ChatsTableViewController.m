//
//  ChatsTableViewController.m
//  SIMplePhone
//
//  Created by Lukas Kuster on 11.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

#import "ChatsTableViewController.h"

@interface ChatsTableViewController () <UISearchControllerDelegate>

@property (nonatomic, strong) NSArray *chats;
@property SPManager *manager;
    
@end

@implementation ChatsTableViewController
    
- (void)viewDidLoad {
    self.manager = [SPManager sharedInstance];
    [self.manager getAllChatsWithCompletion:^(BOOL success, NSArray<SPChat *> *chats, NSError *error) {
        if(success) {
            self.chats = chats;
            [self.tableView reloadData];
        };
    }];
    
    [super viewDidLoad];
    
    UISearchController *search = [[UISearchController alloc] initWithSearchResultsController:self];
    [self.navigationItem setSearchController:search];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
