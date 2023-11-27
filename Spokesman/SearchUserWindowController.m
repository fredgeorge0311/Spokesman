//
//  SeachUserWindowController.m
//  Spokesman
//
//  Created by Chaitanya VRK on 05/03/17.
//  Copyright © 2017 troomobile. All rights reserved.
//

#import "SearchUserWindowController.h"
#import "AFNetworking.h"
//@import AFNetworking;
#import "AppConstant.h"

@interface SearchUserWindowController ()
{
    NSMutableArray* usersData;
}
@end

@implementation SearchUserWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _txtSearchUser.delegate = self;
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)didTapCancelButton:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    
    //[self showTableRefreshAnimation];
}

- (IBAction)didTapDoneButton:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

-(void)searchFieldDidEndSearching:(NSSearchField *)sender
{
 NSLog(@"search field did end: %@", sender.stringValue);
}

-(void)searchFieldDidStartSearching:(NSSearchField *)sender
{
    NSLog(@"search field did start: %@", sender.stringValue);
    
    
    
    //manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    //[manager.requestSerializer setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];

    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    [postUserData setValue:userId forKey:@"userId"];
    [postUserData setValue:accessToken forKey:@"accessToken"];
    [postUserData setValue:@"1" forKey:@"startRange"];
    [postUserData setValue:@"9999" forKey:@"endRange"];
    [postUserData setValue:sender.stringValue forKey:@"searchString"];
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, FIND_USERS];
    
    NSError *error = nil;
    NSData* json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        NSLog(@"JSON: %@", jsonString);
    }
    //}
    NSDictionary *params = @{@"data" : jsonString};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:url parameters:params
          success:^(NSURLSessionDataTask * _Nonnull task, id _Nonnull responseObject)
     {
         NSMutableDictionary* response = responseObject;
         NSString* status = [response valueForKey:@"responseStatus"];
         NSLog(@"Status: %@", status);
         if([status isEqualToString:@"200"])
         {
             usersData = [response valueForKey:@"responseObj"];
             if(usersData != nil)
             {
                 NSLog(@"response not nil %lu", (unsigned long)usersData.count);
                 /*for (int i = 0; i < usersData.count; i++) {
                     NSDictionary* userData = usersData[i];
                     NSLog(@"User Name: %@", [userData valueForKey:@"firstName"]);
                 }*/
                 [_tableView reloadData];
             }
             else
             {
                 NSLog(@"Response Array Empty");
             }
         }
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         //
         NSLog(@"Error finding user");
     }];
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString* value = @"";
    NSString* cellIdentifier = @"";
    
    NSDictionary* userDetails = [usersData objectAtIndex:row];
    
    if(tableColumn == tableView.tableColumns[0])
    {//image
        value = @"";
        cellIdentifier = @"UserImageCell";
    }
    else if(tableColumn == tableView.tableColumns[1])
    {//first name
        value = [userDetails valueForKey:@"firstName"];
        cellIdentifier = @"FirstNameCell";
    }
    else if(tableColumn == tableView.tableColumns[0])
    {//last name
        value = [userDetails valueForKey:@"lastName"];
        cellIdentifier = @"LastNameCell";
    }
    else if(tableColumn == tableView.tableColumns[0])
    {//email
        value = [userDetails valueForKey:@"email"];
        cellIdentifier = @"EmailCell";
    }
    else
    {//city
        value = [userDetails valueForKey:@"location"];
        cellIdentifier = @"CityCell";
    }
    
    NSTableCellView *result = [tableView makeViewWithIdentifier:cellIdentifier owner:self];
    
    if(tableColumn == tableView.tableColumns[0])
    {
        //
    }
    else
    {
        // Set the stringValue of the cell's text field to the nameArray value at row
        if(value == nil)
            value = @"";
        result.textField.stringValue = value;
    }
    
    return result;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(usersData != nil){
        return usersData.count;
    }
    else
    {
        return 0;
    }
}

@end
