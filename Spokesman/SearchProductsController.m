//
//  SearchProductsController.m
//  Spokesman
//
//  Created by Chaitanya VRK on 03/01/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "SearchProductsController.h"
#import "AFNetworking.h"
//@import AFNetworking;
#import "AppConstant.h"
#import "PVAsyncImageView.h"
#import "CreateProductController.h"

@interface SearchProductsController ()
{
    NSMutableArray* productsData;    
}
@property (strong) CreateProductController *createProductController;
@end

@implementation SearchProductsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    _artistsTableView.delegate = self;
    _artistsTableView.dataSource = self;
    
    _isShopify = false;
    
    [self setButtonTitle:_btnAddArtists toString:@"Add Selected Products" withColor:[NSColor whiteColor] withSize:13];
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
    self.createProductController = [self.storyboard instantiateControllerWithIdentifier:@"CreateProductController"];
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
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, SEARCH_PRODUCT];
    
    if(_btnSearchShopify.state == 1)
    {
        NSString *encodedParam = [searchTerm stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];

        url = [NSString stringWithFormat:@"https://bon2.tv/ajax-get-shopify-products.php/?keywords=%@", encodedParam];
    }
    
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
    
    if(_btnSearchShopify.state == 1)
        params = [[NSDictionary alloc] init];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    if(_btnSearchShopify.state == 1){
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    
    if(searchTerm.length > 0)
        [manager.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [manager POST:url parameters:params
          success:^(NSURLSessionDataTask * _Nonnull task, id _Nonnull responseObject)
     {
         _loading.hidden = true;
         [_loading stopAnimation:self];
         
         NSError *e = nil;
         NSDictionary *resultJson = [[NSDictionary alloc] init];
         
         NSMutableDictionary* response = [[NSMutableDictionary alloc] init];
         
         if(_btnSearchShopify.state == 1)
         {
             resultJson = (NSDictionary*)[NSJSONSerialization JSONObjectWithData: responseObject options: NSJSONReadingMutableContainers error: &e];
             response = [resultJson mutableCopy];
         }
         else
             response = responseObject;
         
         NSString* status = [response valueForKey:@"responseStatus"];
         NSLog(@"Status: %@", status);
         if([status isEqualToString:@"200"])
         {
             productsData = [[response valueForKey:@"responseObj"] mutableCopy];
             if(productsData != nil)
             {
                 NSLog(@"response not nil %lu", (unsigned long)productsData.count);
                 /*for (int i = 0; i < usersData.count; i++) {
                  NSDictionary* userData = usersData[i];
                  NSLog(@"User Name: %@", [userData valueForKey:@"firstName"]);
                  }*/
                 [_artistsTableView reloadData];
             }
             else
             {
                 NSLog(@"Response Array Empty");
             }
         }
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         _loading.hidden = true;
         [_loading stopAnimation:self];
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
    [postUserData setValue:artistId forKey:@"productId"];
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, DELETE_PRODUCT];
    
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
                 [self showAlert:@"Success" message:@"Deleted product."];
                 _txtSearch.stringValue = @"";
                 [self loadArtists:@""];
             }
             else
             {
                 [self showAlert:@"Error" message:@"Error deleting product. Please try again."];
             }
             
         });
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             _loading.hidden = YES;
             [_loading stopAnimation:self];
             [self showAlert:@"Error" message:@"Error deleting product. Please try again."];
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
    if(row == productsData.count - 1)
    {
        _loading.hidden = true;
        [_loading stopAnimation:self];
    }
    
    NSString* value = @"";
    NSString* cellIdentifier = @"";
    
    NSDictionary* userDetails = [productsData objectAtIndex:row];
    
    if(tableColumn == tableView.tableColumns[0])
    {//image
        value = [userDetails valueForKey:@"picture"];
        //value = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        
        cellIdentifier = @"ArtistImageCell";
    }
    else if(tableColumn == tableView.tableColumns[1])
    {//first name
        value = [userDetails valueForKey:@"productName"];
        cellIdentifier = @"ArtistFirstNameCell";
    }
    else if(tableColumn == tableView.tableColumns[2])
    {//last name
        value = [userDetails valueForKey:@"brandName"];
        cellIdentifier = @"ArtistLastNameCell";
    }
    else if(tableColumn == tableView.tableColumns[3])
    {//email
        //value = [userDetails valueForKey:@"productDescription"];
        value = [userDetails valueForKey:@"keywords"];
        
        cellIdentifier = @"ArtistProfileCell";
    }
    else if(tableColumn == tableView.tableColumns[4])
    {//city
        value = @"EDIT";
        cellIdentifier = @"ArtistEditCell";
    }
    else
    {//city
        value = @"";
        cellIdentifier = @"ArtistDeleteCell";
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
    [productsData sortUsingDescriptors: sortDescriptors];
    [tableView reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(productsData != nil){
        return productsData.count;
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
    
    if(_isShopify)
        return;
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId.lowercaseString isEqualToString:@"bon2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    
    int i = [_artistsTableView rowForView:sender];
    NSLog([NSString stringWithFormat:@"@%d", i]);
    [_artistsTableView selectRow:i byExtendingSelection:NO];
    [self showCreateArtist:i];
}

-(void)showCreateArtist:(int)index{
    NSRect mainRect = self.view.frame;
    mainRect.size.height += 25;
    
    NSDictionary* userDetails = [productsData objectAtIndex:index];
    
    self.createProductController.isEdit = true;
    self.createProductController.productId = [userDetails valueForKey:@"productId"];
    self.createProductController.productName = [userDetails valueForKey:@"productName"];
    self.createProductController.brandName = [userDetails valueForKey:@"brandName"];
    self.createProductController.profile = [userDetails valueForKey:@"productDescription"];
    self.createProductController.link1 = [userDetails valueForKey:@"shopLink1"];
    self.createProductController.link2 = [userDetails valueForKey:@"shopLink2"];
    self.createProductController.link3 = [userDetails valueForKey:@"shopLink3"];
    self.createProductController.link4 = [userDetails valueForKey:@"shopLink4"];
    self.createProductController.link5 = [userDetails valueForKey:@"shopLink5"];
    self.createProductController.keywords = [userDetails valueForKey:@"keywords"];
    self.createProductController.originalPicture = [userDetails valueForKey:@"picture"];
    
    if([[userDetails valueForKey:@"generalCategory"] isEqualToString:@"Y"])
        self.createProductController.isGeneralCategory = YES;
    else
        self.createProductController.isGeneralCategory = NO;
    
    //self.createProductController.pinterest = [userDetails valueForKey:@"pintrestUrl"];
    
    
    NSTableCellView *cellView = [[_artistsTableView rowViewAtRow:index makeIfNecessary:NO] viewAtColumn:0];
    self.createProductController.profilePic = cellView.imageView.image;
    
    [self hideDetailsView];
    
    [self presentViewController:self.createProductController asPopoverRelativeToRect:mainRect ofView:self.view preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
}

-(void)hideDetailsView{
    if([[self.createProductController presentingViewController] isKindOfClass:[self class]])
        [self dismissViewController:self.createProductController];
}

- (IBAction)btnSearchClick:(id)sender {
    if(_txtSearch.stringValue.length > 0){
        if(_btnSearchShopify.state == 1)
            _isShopify = true;
        else
            _isShopify = false;
        
        [self loadArtists:_txtSearch.stringValue];
    }
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
    
    if(_isShopify)
        return;
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId.lowercaseString isEqualToString:@"bon2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    //To do: Add confirmation box
    
    int i = [_artistsTableView rowForView:sender];
    NSLog([NSString stringWithFormat:@"@%d", i]);
    [_artistsTableView selectRow:i byExtendingSelection:NO];
    NSDictionary* userDetails = [productsData objectAtIndex:i];
    [self deleteArtist:[userDetails valueForKey:@"productId"]];
}

- (IBAction)btnAddArtistsClick:(id)sender {
    NSIndexSet *selectedRows = [_artistsTableView selectedRowIndexes];
    NSUInteger numberOfSelectedRows = [selectedRows count];
    NSUInteger indexBuffer[numberOfSelectedRows];
    
    if(numberOfSelectedRows > 0){
        NSUInteger limit = [selectedRows getIndexes:indexBuffer maxCount:numberOfSelectedRows inIndexRange:NULL];
        
        NSMutableArray* selectedProds = [NSMutableArray array];
        
        for (unsigned iterator = 0; iterator < limit; iterator++)
        {
            NSMutableDictionary* userDetails = [[productsData objectAtIndex:indexBuffer[iterator]] mutableCopy];
                        
            NSString* url = [userDetails valueForKey:@"picture"];
            url = [url stringByReplacingOccurrencesOfString:@"https://" withString:@"https:/"];
            url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            userDetails[@"picture"] = url;
            
            NSString* shop_url = [userDetails valueForKey:@"shopLink1"];
            shop_url = [shop_url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            userDetails[@"shopLink1"] = shop_url;
            
            [selectedProds addObject:userDetails];
        }
        //Call delegate
        if ([self.delegate respondsToSelector:@selector(searchProductsController:didSelectedProducts:)]) {
            [self.delegate searchProductsController:self didSelectedProducts:selectedProds];
            //[self dismissViewController:self];
        }
    }
}

- (IBAction)btnSearchCategoryClick:(id)sender {
}
-(void)reloadData
{
    if(_txtSearch.stringValue.length > 0)
        [self loadArtists:_txtSearch.stringValue];
    else
        [self loadArtists:@""];
}
@end

