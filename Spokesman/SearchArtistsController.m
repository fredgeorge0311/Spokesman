//
//  SearchArtistsController.m
//  Spokesman
//
//  Created by Chaitanya VRK on 03/01/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "SearchArtistsController.h"
#import "AFNetworking.h"
//@import AFNetworking;
#import "AppConstant.h"
#import "PVAsyncImageView.h"
#import "CreateArtistController.h"
#import "CreateBrandController.h"
#import "CreateLocationController.h"

@interface SearchArtistsController ()
{
    NSMutableArray* artistsData;
}
@property (strong) CreateArtistController *createArtistController;
@property (strong) CreateBrandController *createBrandController;
@property (strong) CreateLocationController *createLocationController;
@end

@implementation SearchArtistsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    _artistsTableView.delegate = self;
    _artistsTableView.dataSource = self;
    
    
    
    [self setButtonTitle:_btnAddArtists toString:@"Add Selected Artists" withColor:[NSColor whiteColor] withSize:13];
    [self setButtonTitle:_btnClose toString:@"Close" withColor:[NSColor whiteColor] withSize:13];
}

-(void)setButtonTitle:(NSButton*)button toString:(NSString*)title withColor:(NSColor*)color withSize:(int)size{
    NSFont *txtFont = [NSFont systemFontOfSize:size];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             txtFont, NSFontAttributeName, color, NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:title attributes:txtDict];
    [attrStr addAttributes:[NSDictionary dictionaryWithObject:paragraphStyle forKey:NSParagraphStyleAttributeName] range:NSMakeRange(0,[attrStr length])];
    [button setAttributedTitle:attrStr];
}

-(void)viewDidAppear
{
    self.createArtistController = [self.storyboard instantiateControllerWithIdentifier:@"CreateArtistController"];
    self.createBrandController = [self.storyboard instantiateControllerWithIdentifier:@"CreateBrandController"];
    self.createLocationController = [self.storyboard instantiateControllerWithIdentifier:@"CreateLocationController"];
    //[self loadArtists:@""];
}

-(void)loadArtists:(NSString*)searchTerm{
    
    [self hideDetailsView];
    
    _loading.hidden = false;
    [_loading startAnimation:self];
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    [postUserData setValue:userId forKey:@"userId"];
    [postUserData setValue:accessToken forKey:@"accessToken"];
    [postUserData setValue:@"1" forKey:@"startRange"];
    [postUserData setValue:@"9999" forKey:@"endRange"];
    [postUserData setValue:searchTerm forKey:@"searchString"];
    
    if(_radioName.state == 1)
        [postUserData setValue:@"false" forKey:@"searchMedia"];
    else
        [postUserData setValue:@"true" forKey:@"searchMedia"];
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, SEARCH_ARTIST];
    
    NSError *error = nil;
    NSData* json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        NSLog(@"JSON: %@", jsonString);
        
        //[self showAlert:@"Send Search request" message:jsonString];
    }
    //}
    NSDictionary *params = @{@"data" : jsonString};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    if(searchTerm.length > 0)
        [manager.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];

    [manager POST:url parameters:params
          success:^(NSURLSessionDataTask * _Nonnull task, id _Nonnull responseObject)
     {
         _loading.hidden = true;
         [_loading stopAnimation:self];
         NSMutableDictionary* response = responseObject;
         NSString* status = [response valueForKey:@"responseStatus"];
         NSLog(@"Status: %@", status);
         if([status isEqualToString:@"200"])
         {
             artistsData = [[response valueForKey:@"responseObj"] mutableCopy];
             if(artistsData != nil)
             {
                 NSLog(@"response not nil %lu", (unsigned long)artistsData.count);
                 /*for (int i = 0; i < usersData.count; i++) {
                  NSDictionary* userData = usersData[i];
                  NSLog(@"User Name: %@", [userData valueForKey:@"firstName"]);
                  }*/
                 [_artistsTableView reloadData];
             }
             else
             {
                 NSLog(@"Response Array Empty");
                 [self showAlert:@"Error searching artists" message:@"No data received"];
             }
         }
         else
         {
             [self showAlert:@"Error searching artists" message:[NSString stringWithFormat:@"Invalid response code: %@", status]];
         }
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         _loading.hidden = true;
         [_loading stopAnimation:self];
         [self showAlert:@"Error searching artists" message:error.localizedDescription];
         NSLog(@"Error finding artists");
     }];
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    NSLog([NSString stringWithFormat:@"@%d", row]);
    return true;
}

-(void)deleteArtist:(NSString*)artistId{
    NSData *json;
    NSString *jsonString;
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSError *error = nil;
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];    
    
    [postUserData setValue:userId forKey:@"userId"];
    [postUserData setValue:accessToken forKey:@"accessToken"];
    [postUserData setValue:artistId forKey:@"artistId"];
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, DELETE_ARTIST];
    
    json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
    
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        NSLog(@"JSON: %@", jsonString);
    }
    //}
    NSDictionary *params = @{@"data" : jsonString};
    _loading.hidden = NO;
    [_loading startAnimation:self];
    [manager POST:url parameters:params
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             //Run UI Updates
             _loading.hidden = YES;
             [_loading stopAnimation:self];
             NSMutableDictionary* response = responseObject;
             NSString* status = [response valueForKey:@"responseStatus"];
             if([status isEqualToString:@"200"])
             {
                 [self showAlert:@"Success" message:@"Deleted artist."];
                 //_txtSearch.stringValue = @"";
                 [self reloadData];
             }
             else
             {
                 [self showAlert:@"Error" message:@"Error deleting artist profile. Please try again."];
             }
             
         });
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             _loading.hidden = YES;
             [_loading stopAnimation:self];
             [self showAlert:@"Error" message:@"Error deleting artist profile. Please try again."];
         });
     }
     ];
}

-(void)showAlert:(NSString*)title message:(NSString*)message{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        // OK clicked, delete the record
    }
    
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(row == artistsData.count - 1)
    {
        _loading.hidden = true;
        [_loading stopAnimation:self];
    }
    
    NSString* value = @"";
    NSString* cellIdentifier = @"";
    
    NSDictionary* userDetails = [artistsData objectAtIndex:row];
    
    if(tableColumn == tableView.tableColumns[0])
    {//image
        value = [userDetails valueForKey:@"profilePicture"];
        //value = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];

        cellIdentifier = @"ArtistImageCell";
    }
    else if(tableColumn == tableView.tableColumns[1])
    {//first name
        value = [userDetails valueForKey:@"firstName"];
        cellIdentifier = @"ArtistFirstNameCell";
    }
    else if(tableColumn == tableView.tableColumns[2])
    {//last name
        value = [userDetails valueForKey:@"lastName"];
        cellIdentifier = @"ArtistLastNameCell";
    }
    else if(tableColumn == tableView.tableColumns[3])
    {//email
        value = [userDetails valueForKey:@"artistDescription"];
        cellIdentifier = @"ArtistProfileCell";
    }
    else if(tableColumn == tableView.tableColumns[4])
    {//city
        value = @"EDIT";
        cellIdentifier = @"ArtistEditCell";
    }
    else if(tableColumn == tableView.tableColumns[5])
    {//delete
        value = @"";
        cellIdentifier = @"ArtistDeleteCell";
    }
    else
    {
        value = [userDetails valueForKey:@"uploader"];
        value = [value stringByReplacingOccurrencesOfString:@"ARTIST_" withString:@""];
        cellIdentifier = @"ArtistSourceCell";
    }
    
    
    NSTableCellView *result = [tableView makeViewWithIdentifier:cellIdentifier owner:self];
    
    if(tableColumn == tableView.tableColumns[0])
    {
        [((PVAsyncImageView*)result.imageView) downloadImageFromURL:value];
    }
    else
    {
        // Set the stringValue of the cell's text field to the nameArray value at row
        if(value == nil)
            value = @"-";
        result.textField.stringValue = value;
    }
    
    return result;
}

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
    NSArray<NSSortDescriptor *> * sortDescriptors = [tableView sortDescriptors];
    [artistsData sortUsingDescriptors: sortDescriptors];
    [tableView reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(artistsData != nil){
        return artistsData.count;
    }
    else
    {
        return 0;
    }
}
- (IBAction)btnCloseClick:(id)sender {
    [self dismissViewController:self];
}

-(BOOL)isEmailAdmin{
    NSString* email = [[NSUserDefaults standardUserDefaults] valueForKey:@"email"];
    
    if(email != nil && email.length > 0 && ([email hasSuffix:@"bon2.tv"] || [email hasSuffix:@"bon2.com"] || [email hasSuffix:@"watchtele.tv"])){
        return true;
    }
    else{
        return false;
    }
}

- (IBAction)btnEditArtistClick:(id)sender {
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId.lowercaseString isEqualToString:@"bon2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    
    int i = [_artistsTableView rowForView:sender];
    NSLog([NSString stringWithFormat:@"@%d", i]);
    [_artistsTableView selectRow:i byExtendingSelection:NO];
    
    NSDictionary* userDetails = [artistsData objectAtIndex:i];
    
    NSData *json;
    NSString *jsonString;
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSError *error = nil;
    
    //NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];
    
    [postUserData setValue:userId forKey:@"userId"];
    [postUserData setValue:accessToken forKey:@"accessToken"];
    [postUserData setValue:[userDetails valueForKey:@"artistId"] forKey:@"artistId"];
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, GET_ARTIST_DETAILS];
    
    json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
    
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        NSLog(@"JSON: %@", jsonString);
    }
    //}
    NSDictionary *params = @{@"data" : jsonString};
    _loading.hidden = NO;
    [_loading startAnimation:self];
    [manager POST:url parameters:params
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             //Run UI Updates
             _loading.hidden = YES;
             [_loading stopAnimation:self];
             NSMutableDictionary* response = responseObject;
             NSString* status = [response valueForKey:@"responseStatus"];
             if([status isEqualToString:@"200"])
             {
                 //[self showAlert:@"Success" message:@"Deleted artist."];
                 //_txtSearch.stringValue = @"";
                 //[self loadArtists:@""];
                 [self showCreateArtist:[response objectForKey:@"responseObj"] index:i];
             }
             else
             {
                 [self showAlert:@"Error" message:@"Error getting artist details. Please try again."];
             }
             
         });
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             _loading.hidden = YES;
             [_loading stopAnimation:self];
             [self showAlert:@"Error" message:@"Error getting artist details. Please try again."];
         });
     }
     ];
}

-(void)showCreateArtist:(NSDictionary*)userDetails index:(int)index{
    NSRect mainRect = self.view.frame;
    mainRect.size.height += 25;
    
    //NSDictionary* userDetails = [artistsData objectAtIndex:index];
    
    if([[userDetails valueForKey:@"genre"] isEqualToString:@"Brand"] || [[userDetails valueForKey:@"genre"] isEqualToString:@"brand"])
    {
        self.createBrandController.isEdit = true;
        self.createBrandController.artistId = [userDetails valueForKey:@"artistId"];
        //self.createBrandController.firstName = [userDetails valueForKey:@"firstName"];
        //self.createBrandController.lastName = [userDetails valueForKey:@"lastName"];
        self.createBrandController.brandName = [userDetails valueForKey:@"nickName"];
        self.createBrandController.profile = [userDetails valueForKey:@"artistDescription"];
        self.createBrandController.website = [userDetails valueForKey:@"bon2Url"];
        self.createBrandController.genre = @"Brand";//[userDetails valueForKey:@"genre"];
        self.createBrandController.category = [userDetails valueForKey:@"generalCategory"];
        self.createBrandController.fb = [userDetails valueForKey:@"fbUrl"];
        self.createBrandController.tw = [userDetails valueForKey:@"youtubeUrl"];
        self.createBrandController.insta = [userDetails valueForKey:@"instagramUrl"];
        self.createBrandController.pinterest = [userDetails valueForKey:@"pintrestUrl"];
        
        NSArray* contribs = [userDetails valueForKey:@"mediaList"];
        
        if(contribs.count > 0)
            self.createBrandController.contributions = [[contribs valueForKey:@"mediaName"] componentsJoinedByString:@"\n"];
        
        NSTableCellView *cellView = [[_artistsTableView rowViewAtRow:index makeIfNecessary:NO] viewAtColumn:0];
        self.createBrandController.profilePic = cellView.imageView.image;
        
        [self hideDetailsView];
        
        [self presentViewController:self.createBrandController asPopoverRelativeToRect:mainRect ofView:self.view preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    }
    else if([[userDetails valueForKey:@"genre"] isEqualToString:@"Location"] || [[userDetails valueForKey:@"genre"] isEqualToString:@"location"])
    {
        self.createLocationController.isEdit = true;
        self.createLocationController.artistId = [userDetails valueForKey:@"artistId"];
        //self.createBrandController.firstName = [userDetails valueForKey:@"firstName"];
        //self.createBrandController.lastName = [userDetails valueForKey:@"lastName"];
        self.createLocationController.locationName = [userDetails valueForKey:@"nickName"];
        self.createLocationController.profile = [userDetails valueForKey:@"artistDescription"];
        self.createLocationController.website = [userDetails valueForKey:@"bon2Url"];
        self.createLocationController.genre = @"Location";//[userDetails valueForKey:@"genre"];
        
        self.createLocationController.fb = [userDetails valueForKey:@"fbUrl"];
        self.createLocationController.tw = [userDetails valueForKey:@"youtubeUrl"];
        self.createLocationController.insta = [userDetails valueForKey:@"instagramUrl"];
        self.createLocationController.pinterest = [userDetails valueForKey:@"pintrestUrl"];
        
        NSArray* contribs = [userDetails valueForKey:@"mediaList"];
        
        if(contribs.count > 0)
            self.createLocationController.contributions = [[contribs valueForKey:@"mediaName"] componentsJoinedByString:@"\n"];
        
        NSTableCellView *cellView = [[_artistsTableView rowViewAtRow:index makeIfNecessary:NO] viewAtColumn:0];
        self.createLocationController.profilePic = cellView.imageView.image;
        
        [self hideDetailsView];
        
        [self presentViewController:self.createLocationController asPopoverRelativeToRect:mainRect ofView:self.view preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    }
    else
    {
        self.createArtistController.isEdit = true;
        self.createArtistController.artistId = [userDetails valueForKey:@"artistId"];
        self.createArtistController.firstName = [userDetails valueForKey:@"firstName"];
        self.createArtistController.lastName = [userDetails valueForKey:@"lastName"];
        self.createArtistController.nickName = [userDetails valueForKey:@"nickName"];
        self.createArtistController.profile = [userDetails valueForKey:@"artistDescription"];
        self.createArtistController.website = [userDetails valueForKey:@"bon2Url"];
        self.createArtistController.genre = [userDetails valueForKey:@"genre"];
        
        self.createArtistController.fb = [userDetails valueForKey:@"fbUrl"];
        self.createArtistController.tw = [userDetails valueForKey:@"youtubeUrl"];
        self.createArtistController.insta = [userDetails valueForKey:@"instagramUrl"];
        self.createArtistController.pinterest = [userDetails valueForKey:@"pintrestUrl"];

        NSArray* contribs = [userDetails valueForKey:@"mediaList"];
        
        if(contribs.count > 0)
            self.createArtistController.contributions = [[contribs valueForKey:@"mediaName"] componentsJoinedByString:@"\n"];
        
        NSTableCellView *cellView = [[_artistsTableView rowViewAtRow:index makeIfNecessary:NO] viewAtColumn:0];
        self.createArtistController.profilePic = cellView.imageView.image;
        
        [self hideDetailsView];
        
        [self presentViewController:self.createArtistController asPopoverRelativeToRect:mainRect ofView:self.view preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    }
}

-(void)hideDetailsView{
    if([[self.createArtistController presentingViewController] isKindOfClass:[self class]])
        [self dismissViewController:self.createArtistController];
    
    if([[self.createBrandController presentingViewController] isKindOfClass:[self class]])
        [self dismissViewController:self.createBrandController];

    if([[self.createLocationController presentingViewController] isKindOfClass:[self class]])
        [self dismissViewController:self.createLocationController];}

- (IBAction)btnSearchClick:(id)sender {
    if(_txtSearch.stringValue.length > 0)
        [self loadArtists:_txtSearch.stringValue];
}

- (IBAction)btnReloadAllClick:(id)sender {
    _txtSearch.stringValue = @"";
    [self loadArtists:@""];
}

- (IBAction)txtSearchEnter:(id)sender {
    if(_txtSearch.stringValue.length > 0)
        [self loadArtists:_txtSearch.stringValue];
}

- (IBAction)btnDeleteArtistClick:(id)sender {
    NSString* email = [[NSUserDefaults standardUserDefaults] objectForKey:@"email"];
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId.lowercaseString isEqualToString:@"bon2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this action."];
        return;
    }
    //To do: Add confirmation box
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Confirm"];
    [alert setInformativeText:@"Are you sure you want to delete?"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSInteger answer = [alert runModal] ;
    
    if (answer == NSAlertFirstButtonReturn) {
        // OK clicked, delete the record
        int i = [_artistsTableView rowForView:sender];
        NSLog([NSString stringWithFormat:@"@%d", i]);
        [_artistsTableView selectRow:i byExtendingSelection:NO];
        NSDictionary* userDetails = [artistsData objectAtIndex:i];
        [self deleteArtist:[userDetails valueForKey:@"artistId"]];
    }
    else
    {
        //...
    }
    
    
    
}

- (IBAction)btnAddArtistsClick:(id)sender {
    NSString* email = [[NSUserDefaults standardUserDefaults] objectForKey:@"email"];
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId isEqualToString:@"rajani"] && ![userId.lowercaseString isEqualToString:@"bon2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this action."];
        return;
    }
    
    NSIndexSet *selectedRows = [_artistsTableView selectedRowIndexes];
    NSUInteger numberOfSelectedRows = [selectedRows count];
    NSUInteger indexBuffer[numberOfSelectedRows];
    
    if(numberOfSelectedRows > 0){
        NSUInteger limit = [selectedRows getIndexes:indexBuffer maxCount:numberOfSelectedRows inIndexRange:NULL];
        
        NSMutableArray* selectedArtists = [NSMutableArray array];
        
        for (unsigned iterator = 0; iterator < limit; iterator++)
        {
            NSMutableDictionary* userDetails = [[artistsData objectAtIndex:indexBuffer[iterator]] mutableCopy];
            
            
            NSString* url = [userDetails valueForKey:@"profilePicture"];
            url = [url stringByReplacingOccurrencesOfString:@"https://" withString:@"https:/"];
            
            url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            userDetails[@"profilePicture"] = url;
            
            [selectedArtists addObject:userDetails];
        }
        //Call delegate
        if ([self.delegate respondsToSelector:@selector(searchArtistsController:didSelectedArtists:)]) {
            [self.delegate searchArtistsController:self didSelectedArtists:selectedArtists];
            //[self dismissViewController:self];
        }
    }
}

- (IBAction)radioSearchTypeSet:(id)sender {
}
-(void)reloadData{
    if(_txtSearch.stringValue.length > 0)
        [self loadArtists:_txtSearch.stringValue];
    else
        [self loadArtists:@""];
}
@end
