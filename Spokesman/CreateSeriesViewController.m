//
//  CreateSeriesViewController.m
//  Spokesman
//
//  Created by Chaitanya VRK on 18/06/19.
//  Copyright © 2019 troomobile. All rights reserved.
//

#import "CreateSeriesViewController.h"
#import "AFNetworking.h"
#import "AppConstant.h"
#import "PVAsyncImageView.h"
#import "AWSCore/AWSCore.h"
#import "AWSS3/AWSS3.h"

@interface CreateSeriesViewController ()
{
    NSMutableArray* seriesData;
    
    BOOL isInEdit;
}
@end

@implementation CreateSeriesViewController

NSString* s_title;
NSString* s_description;
NSString* s_producer;
NSString* s_director;
NSString* s_imageurl;
NSString* s_cast = @"-";
NSString* s_genre;
NSString* s_isFeatured;
NSString* s_seriesId;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    isInEdit = false;
    _btnCreateNewSeries.hidden = true;
    _seriesTableView.delegate = self;
    _seriesTableView.dataSource = self;
    
    _btnCreateSeries.title = @"Create New Series";
}

-(void)viewDidAppear
{
    [super viewDidAppear];
    [self loadSeries];
}

-(void)loadSeries{
    _loading.hidden = false;
    [_loading startAnimation:self];
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    [postUserData setValue:userId forKey:@"userId"];
    [postUserData setValue:accessToken forKey:@"accessToken"];
    [postUserData setValue:@"1" forKey:@"startRange"];
    [postUserData setValue:@"999" forKey:@"endRange"];
    
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, @"getSeries"];
    
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
             seriesData = [[response valueForKey:@"responseObj"] mutableCopy];
             if(seriesData != nil)
             {
                 NSLog(@"response not nil %lu", (unsigned long)seriesData.count);
                 /*for (int i = 0; i < usersData.count; i++) {
                  NSDictionary* userData = usersData[i];
                  NSLog(@"User Name: %@", [userData valueForKey:@"firstName"]);
                  }*/
                 [_seriesTableView reloadData];
             }
         }
         else
         {
             [self showAlert:@"Error getting series list" message:[NSString stringWithFormat:@"Invalid response code: %@", status]];
         }
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         _loading.hidden = true;
         [_loading stopAnimation:self];
         [self showAlert:@"Error getting series list:" message:error.localizedDescription];
         NSLog(@"Error finding artists");
     }];
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return true;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(seriesData != nil){
        return seriesData.count;
    }
    else
    {
        return 0;
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification{
    
    _btnCreateSeries.title = @"Update Series";
    
    _btnCreateNewSeries.hidden = false;
    _btnDeleteSeries.hidden = false;
    
    isInEdit = true;
    
    NSDictionary* userDetails = [seriesData objectAtIndex:_seriesTableView.selectedRow];
    
    
    s_seriesId = [userDetails valueForKey:@"seriesId"];
    NSString* thumbnail = [userDetails valueForKey:@"thumbnail"];
    NSString* featuredImage = [userDetails valueForKey:@"featuredImage"];
    NSString* backgroundImage = [NSString stringWithFormat:@"%@.seriesbg.jpg", featuredImage];
    NSString* poster = [NSString stringWithFormat:@"%@.poster.jpeg", featuredImage];
    
    [((PVAsyncImageView*)_imgSeriesThumbnail) downloadImageFromURL:thumbnail];
    [((PVAsyncImageView*)_imgSeriesIcon) downloadImageFromURL:poster];
    [((PVAsyncImageView*)_imgSeriesBackground) downloadImageFromURL:backgroundImage];
    
    _txtSeriesName.stringValue = [userDetails valueForKey:@"title"];
    _txtGenre.stringValue = [userDetails valueForKey:@"genre"];
    _txtDirector.stringValue = [userDetails valueForKey:@"director"];
    _txtProducer.stringValue = [userDetails valueForKey:@"producer"];
    _txtCast.stringValue = [userDetails valueForKey:@"cast"];
    _txtSeriesDescription.stringValue = [userDetails valueForKey:@"description"];
        
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(row == seriesData.count - 1)
    {
        _loading.hidden = true;
        [_loading stopAnimation:self];
    }
    
    NSString* value = @"";
    NSString* cellIdentifier = @"";
    
    NSDictionary* userDetails = [seriesData objectAtIndex:row];
    
    if(tableColumn == tableView.tableColumns[0])
    {//image
        value = [userDetails valueForKey:@"thumbnail"];
        //value = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        
        cellIdentifier = @"SeriesImageCell";
    }
    else if(tableColumn == tableView.tableColumns[1])
    {//series name
        value = [userDetails valueForKey:@"title"];
        cellIdentifier = @"SeriesNameCell";
    }
    /*else if(tableColumn == tableView.tableColumns[2])
    {//director name
        value = [userDetails valueForKey:@"director"];
        cellIdentifier = @"DirectorNameCell";
    }
    else if(tableColumn == tableView.tableColumns[3])
    {//description
        value = [userDetails valueForKey:@"description"];
        cellIdentifier = @"SeriesDescCell";
    }*/
    else if(tableColumn == tableView.tableColumns[2])
    {//edit
        value = @"EDIT";
        cellIdentifier = @"SeriesEditCell";
    }
    /*else if(tableColumn == tableView.tableColumns[5])
    {//delete
        value = @"";
        cellIdentifier = @"SeriesDeleteCell";
    }*/
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

- (IBAction)btnCreateSeriesClicked:(id)sender {
    //...
    if(_txtSeriesName.stringValue.length > 0)
    {
        if(_imgSeriesThumbnail.image == nil || CGSizeEqualToSize(_imgSeriesThumbnail.image.size, CGSizeZero))
        {
            [self showAlert:@"Missing thumbnail" message:@"Please drag and drop an image for series thumbnail"];
        }
        else if(_imgSeriesIcon.image == nil || CGSizeEqualToSize(_imgSeriesIcon.image.size, CGSizeZero))
        {
            [self showAlert:@"Missing featured image" message:@"Please drag and drop an image for series featured pic"];
        }
        else if(_imgSeriesBackground.image == nil || CGSizeEqualToSize(_imgSeriesBackground.image.size, CGSizeZero))
        {
            [self showAlert:@"Missing series background" message:@"Please drag and drop an image for series background"];
        }
        else if(_txtSeriesName.stringValue.length == 0)
        {
            [self showAlert:@"Missing series title" message:@"Enter series title"];
        }
        else if([self seriesExists:_txtSeriesName.stringValue])
        {
            [self showAlert:@"Series with the same name already exists" message:@"Please enter a unique series title"];
        }
        else
        {
            s_title = _txtSeriesName.stringValue;
            s_description = _txtSeriesDescription.stringValue;
            s_director = _txtDirector.stringValue;
            s_producer = _txtProducer.stringValue;
            s_cast = _txtCast.stringValue;
            s_genre = _txtGenre.stringValue;
            s_isFeatured = _chkIsFeatured.state == NSControlStateValueOn ? @"Y" : @"N";
            [self createSeries];
            [self uploadFeaturedImage];
            [self uploadBackgroundImage];
        }
    }
    else
    {
        [self showAlert:@"Missing Series Name" message:@"Enter Series Name"];
    }
}

-(BOOL)seriesExists:(NSString*)title{
    if(isInEdit) return false;
    
    for (int i = 0 ; i < seriesData.count; i++) {
        NSDictionary* userDetails = [seriesData objectAtIndex:i];
        if([title isEqualToString:[userDetails valueForKey:@"title"]])
        {
            return true;
        }
    }
    
    return false;
}

- (void)UploadImageWithAppendString:(NSString *)appendStr image:(NSImage*)image{
    NSString* tempPath = [NSTemporaryDirectory() stringByAppendingString:@"tempSeriesFeatured.png"];
    tempPath = [tempPath stringByAppendingString:appendStr];
    
    CGImageRef cgRef = [image CGImageForProposedRect:NULL
                                                                 context:nil
                                                                   hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[image size]];   // if you want the same resolution
    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:nil];
    [pngData writeToFile:tempPath atomically:YES];
    NSURL *_selectedThumbnailUrl = [[NSURL alloc] initFileURLWithPath:tempPath];
    
    
    NSCharacterSet *charactersToRemove =
    [[ NSCharacterSet alphanumericCharacterSet ] invertedSet ];
    
    NSString *trimmedKey =
    [[s_title componentsSeparatedByCharactersInSet:charactersToRemove]
     componentsJoinedByString:@""];
    
    NSString* key = [NSString stringWithFormat:@"seriesthumbnails/%@.png%@", trimmedKey, appendStr];
    
    
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"com.bon2.userdatastore";
    thumbnailUploadRequest.key = key;
    thumbnailUploadRequest.body = _selectedThumbnailUrl;
    thumbnailUploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    thumbnailUploadRequest.contentType = @"image/png";
    //thumbnailUploadRequest.contentLength = [NSNumber numberWithUnsignedLongLong:[pngData length]];
    
    
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:AWS_ACCESS_KEY secretKey:AWS_SECRET_KEY];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest1 credentialsProvider:credentialsProvider];
    
    [AWSS3TransferManager registerS3TransferManagerWithConfiguration:configuration forKey:@"ncalifornia"];
    
    [[[AWSS3TransferManager S3TransferManagerForKey:@"ncalifornia" ] upload:thumbnailUploadRequest] continueWithBlock:^id(AWSTask *task) {
        if(task.error)
        {
            NSLog(@"%@", task.error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [_loading stopAnimation:self];
            });
            [self showAlert:@"Error" message:@"Error uploading image. Please try again."];
        }
        
        return nil;
    }];
}

-(void)uploadFeaturedImage{
    [self UploadImageWithAppendString:@".poster.jpeg" image:_imgSeriesIcon.image];
}

-(void)uploadBackgroundImage{
    [self UploadImageWithAppendString:@".seriesbg.jpg" image:_imgSeriesBackground.image];
}

-(void)createSeries{
    _loading.hidden = false;
    [_loading startAnimation:self];
    
    _btnCreateSeries.enabled = false;
    
    NSString* tempPath = [NSTemporaryDirectory() stringByAppendingString:@"tempSeriesThumb.png"];
    
    
    CGImageRef cgRef = [_imgSeriesThumbnail.image CGImageForProposedRect:NULL
                                                            context:nil
                                                              hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[_imgSeriesThumbnail.image size]];   // if you want the same resolution
    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:nil];
    [pngData writeToFile:tempPath atomically:YES];
    NSURL *_selectedThumbnailUrl = [[NSURL alloc] initFileURLWithPath:tempPath];
    
    NSCharacterSet *charactersToRemove =
    [[ NSCharacterSet alphanumericCharacterSet ] invertedSet ];
    
    NSString *trimmedKey =
    [[s_title componentsSeparatedByCharactersInSet:charactersToRemove]
     componentsJoinedByString:@""];
    
    NSString* key = [NSString stringWithFormat:@"seriesthumbnails/%@.png", trimmedKey];
    
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"com.bon2.userdatastore";
    thumbnailUploadRequest.key = key;
    thumbnailUploadRequest.body = _selectedThumbnailUrl;
    thumbnailUploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    thumbnailUploadRequest.contentType = @"image/png";
    //thumbnailUploadRequest.contentLength = [NSNumber numberWithUnsignedLongLong:[pngData length]];
    
    /*AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
     initWithRegionType:AWSRegionUSEast1
     identityPoolId:@"us-east-1:03036b3e-de1f-4f39-be0f-deaf60a7a7ac"];*/
    
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:AWS_ACCESS_KEY secretKey:AWS_SECRET_KEY];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest1 credentialsProvider:credentialsProvider];
    
    [AWSS3TransferManager registerS3TransferManagerWithConfiguration:configuration forKey:@"ncalifornia"];
    
    [[[AWSS3TransferManager S3TransferManagerForKey:@"ncalifornia" ] upload:thumbnailUploadRequest] continueWithBlock:^id(AWSTask *task) {
        if(task.error)
        {
            NSLog(@"%@", task.error);
            dispatch_async(dispatch_get_main_queue(), ^{
                _btnCreateSeries.enabled = true;
                _btnCloseDialog.enabled = true;
                _loading.hidden = true;
                //_txtFirstName.enabled = true;
                //_txtLastName.enabled = true;
                
                [_loading stopAnimation:self];
            });
            [self showAlert:@"Error" message:@"Error uploading thumbnail. Please try again."];
        }
        else
        {
            NSString* thumbnailUrl = [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/com.bon2.userdatastore/%@", key];
            
            if(isInEdit)
            {
                [self makeUpdateSeriesAPICall:thumbnailUrl];
            }
            else{
                [self makeCreateSeriesAPICall:thumbnailUrl];
            }
            NSLog(@"%@", @"Image Uploaded.");
        }
        
        return nil;
    }];
}

-(void)makeCreateSeriesAPICall:(NSString*)thumbnailUrl{
    NSData *json;
    NSString *jsonString;
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSError *error = nil;
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];
    
    
    [postUserData setValue:userId forKey:@"userId"];
    [postUserData setValue:accessToken forKey:@"accessToken"];
    
    /*if(_isEdit)
        [postUserData setValue:_artistId forKey:@"artistId"];*/
    
    [postUserData setValue:s_title forKey:@"title"];
    [postUserData setValue:s_director forKey:@"director"];
    [postUserData setValue:s_producer forKey:@"producer"];
    [postUserData setValue:s_description forKey:@"description"];
    [postUserData setValue:s_cast forKey:@"cast"];
    [postUserData setValue:s_genre forKey:@"genre"];
    [postUserData setValue:s_isFeatured forKey:@"isFeatured"];
    
    
    [postUserData setValue:thumbnailUrl forKey:@"thumbnail"];
    [postUserData setValue:thumbnailUrl forKey:@"featuredImage"];
    
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, @"createSeries"];
    /*
    if(_isEdit)
        url = [NSString stringWithFormat:@"%@%@",BASE_URL, UPDATE_ARTIST];*/
    
    json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
    
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        NSLog(@"JSON: %@", jsonString);
    }
    //}
    NSDictionary *params = @{@"data" : jsonString};
    
    [manager POST:url parameters:params
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             NSMutableDictionary* response = responseObject;
             NSString* status = [response valueForKey:@"responseStatus"];
             if([status isEqualToString:@"200"])
             {
                 //Run UI Updates
                 _btnCreateSeries.enabled = true;
                 _btnCloseDialog.enabled = true;
                 _loading.hidden = true;
                 [_loading stopAnimation:self];
                 
                 NSString* msg = [NSString stringWithFormat:@"Created series %@",_txtSeriesName.stringValue];
                 
                 [self loadSeries];
                 
                 [self showAlert:@"Success" message:msg];
                 
                 
                 [self clearAllFields];
             }
             else{
                 dispatch_async(dispatch_get_main_queue(), ^(void){
                     _btnCreateSeries.enabled = true;
                     _btnCloseDialog.enabled = true;
                     _loading.hidden = true;
                     [_loading stopAnimation:self];
                     [self showAlert:@"Error" message:@"Server error while creating series. Please try again."];
                 });
             }
         });
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             _btnCreateSeries.enabled = true;
             _btnCloseDialog.enabled = true;
             _loading.hidden = true;
             [_loading stopAnimation:self];
             [self showAlert:@"Error" message:@"Error creating series. Please try again."];
         });
     }
     ];
}


-(void)makeUpdateSeriesAPICall:(NSString*)thumbnailUrl{
    NSData *json;
    NSString *jsonString;
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSError *error = nil;
    
    /*if(_isEdit)
        [postUserData setValue:_artistId forKey:@"artistId"];*/
    
    [postUserData setValue:s_title forKey:@"title"];
    [postUserData setValue:s_director forKey:@"director"];
    [postUserData setValue:s_producer forKey:@"producer"];
    [postUserData setValue:s_description forKey:@"description"];
    [postUserData setValue:s_cast forKey:@"cast"];
    [postUserData setValue:s_genre forKey:@"genre"];
    [postUserData setValue:s_isFeatured forKey:@"isFeatured"];
    [postUserData setValue:thumbnailUrl forKey:@"thumbnail"];
    [postUserData setValue:thumbnailUrl forKey:@"featuredImage"];
    [postUserData setValue:s_seriesId forKey:@"seriesId"];
    
    
    NSString *url = [NSString stringWithFormat:@"http://bon2.tv/ajax-update-series.php"];
    /*
    if(_isEdit)
        url = [NSString stringWithFormat:@"%@%@",BASE_URL, UPDATE_ARTIST];*/
    
    json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
    
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        NSLog(@"JSON: %@", jsonString);
    }

    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    
    [manager POST:url parameters:postUserData
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             NSError *e = nil;
             NSDictionary *resultJson = (NSDictionary*)[NSJSONSerialization JSONObjectWithData: responseObject options: NSJSONReadingMutableContainers error: &e];
             NSMutableDictionary* response = [resultJson mutableCopy];
             
             NSString* status = [response valueForKey:@"status"];
             NSString* _message = [response valueForKey:@"response"];
             if([status isEqualToString:@"200"])
             {
                 //Run UI Updates
                 _btnCreateSeries.enabled = true;
                 _btnCloseDialog.enabled = true;
                 _loading.hidden = true;
                 [_loading stopAnimation:self];
                 
                 NSString* msg = [NSString stringWithFormat:@"Updated the series %@",_txtSeriesName.stringValue];
                 
                 [self loadSeries];
                 
                 [self showAlert:@"Success" message:msg];
                 
                 
                 [self clearAllFields];
             }
             else{
                 dispatch_async(dispatch_get_main_queue(), ^(void){
                     _btnCreateSeries.enabled = true;
                     _btnCloseDialog.enabled = true;
                     _loading.hidden = true;
                     [_loading stopAnimation:self];
                     [self showAlert:@"Error" message:_message];
                 });
             }
         });
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             _btnCreateSeries.enabled = true;
             _btnCloseDialog.enabled = true;
             _loading.hidden = true;
             [_loading stopAnimation:self];
             [self showAlert:@"Error" message:@"Error creating series. Please try again."];
         });
     }
     ];
}

-(void)deleteSeries:(NSString*)seriesId{
    NSData *json;
    NSString *jsonString;
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSError *error = nil;
    
    [postUserData setValue:@"yP%TFya(-{yTh9uPG=sSS%SPE_8{" forKey:@"key"];
    [postUserData setValue:seriesId forKey:@"seriesId"];
    
    
    NSString *url = [NSString stringWithFormat:@"http://bon2.tv/ajax-delete-series.php"];
    /*
    if(_isEdit)
        url = [NSString stringWithFormat:@"%@%@",BASE_URL, UPDATE_ARTIST];*/
    
    json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
    
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        NSLog(@"JSON: %@", jsonString);
    }

    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    
    [manager POST:url parameters:postUserData
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             NSError *e = nil;
             NSDictionary *resultJson = (NSDictionary*)[NSJSONSerialization JSONObjectWithData: responseObject options: NSJSONReadingMutableContainers error: &e];
             NSMutableDictionary* response = [resultJson mutableCopy];
             
             NSString* status = [response valueForKey:@"status"];
             NSString* _message = [response valueForKey:@"response"];
             if([status isEqualToString:@"200"])
             {
                 [_loading stopAnimation:self];
                 [self loadSeries];
                 [self showAlert:@"Success" message:_message];
                 [self clearAllFields];
             }
             else{
                 dispatch_async(dispatch_get_main_queue(), ^(void){
                     _btnCreateSeries.enabled = true;
                     _btnCloseDialog.enabled = true;
                     _loading.hidden = true;
                     [_loading stopAnimation:self];
                     [self showAlert:@"Error" message:_message];
                 });
             }
         });
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             _btnCreateSeries.enabled = true;
             _btnCloseDialog.enabled = true;
             _loading.hidden = true;
             [_loading stopAnimation:self];
             [self showAlert:@"Error" message:@"Error deleting series. Please try again."];
         });
     }
     ];
}

-(void)clearAllFields
{
    _txtSeriesName.stringValue = @"";
    _txtSeriesDescription.stringValue = @"";
    _txtProducer.stringValue = @"";
    _txtDirector.stringValue = @"";
    _imgSeriesThumbnail.image = nil;
    _imgSeriesIcon.image = nil;
    _imgSeriesBackground.image = nil;
    _txtCast.stringValue = @"-";
    _txtGenre.stringValue = @"";
}

- (IBAction)btnCloseDialogClicked:(id)sender {
    [self dismissViewController:self];
}

- (IBAction)resetFieldsForNewSeries:(id)sender {
    [self clearAllFields];
    _btnCreateSeries.title = @"Create New Series";
    _btnDeleteSeries.hidden = true;
    isInEdit = false;
    s_seriesId = @"-1";
}
- (IBAction)btnDeleteSetiesClicked:(id)sender {
    NSDictionary* userDetails = [seriesData objectAtIndex:_seriesTableView.selectedRow];
    NSString* msg = [NSString stringWithFormat:@"Are you sure you want to delete the series %@", [userDetails valueForKey:@"title"]];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Confirm"];
    [alert setInformativeText:msg];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSInteger answer = [alert runModal] ;
    
    if (answer == NSAlertFirstButtonReturn) {
        // OK clicked, delete the record
        [self deleteSeries:[userDetails valueForKey:@"seriesId"]];
    }
    else
    {
        //...
    }
}
@end
