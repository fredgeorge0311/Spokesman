//
//  CreateArtistController.m
//  Spokesman
//
//  Created by Chaitanya VRK on 29/12/17.
//  Copyright © 2017 troomobile. All rights reserved.
//

#import "CreateBrandController.h"
#import "SearchArtistsController.h"

@interface CreateBrandController ()

@end

@implementation CreateBrandController

NSString* b_brandName;
NSString* b_description;
NSString* b_website;
NSString* b_genre;
NSString* b_facebook;
NSString* b_instagram;
NSString* b_twitter;
NSString* b_pinterest;
NSString* b_contributions;
NSString* b_category;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    //_popoverViewController = [self.storyboard instantiateControllerWithIdentifier:@"GenrePopoverViewController"];
}

-(void)viewDidAppear
{
    [self clearAllFields];
    
    //[_popoverViewController clearAllCheckboxes];
    
    if(_brandName.length > 0)
        _txtBrandName.stringValue = _brandName;
    
    if(_profile != nil && _profile.length > 0)
        _txtProfileDescription.stringValue = _profile;
    if(_website != nil && _website.length > 0)
        _txtWebsite.stringValue = _website;
    if(_genre != nil && _genre.length > 0)
        _txtGenre.stringValue = _genre;
    
    if(_contributions != nil && _contributions.length > 0)
    {
        [_txtArtistContribs setString:_contributions];
    }
    
    if(_category.length > 0)
        [_cmbCategory setObjectValue:_category];
    
    if(_fb != nil && _fb.length > 0)
        _txtFacebook.stringValue = _fb;
    if(_tw != nil && _tw.length > 0)
        _txtTwitter.stringValue = _tw;
    if(_insta != nil && _insta.length > 0)
        _txtInstagram.stringValue = _insta;
    if(_pinterest != nil &&_pinterest.length > 0)
        _txtPinterest.stringValue = _pinterest;
    
    if(_profilePic != nil)
        _imgProfilePic.image = _profilePic;
    
    [self setButtonTitle:_btnClose toString:@"Close" withColor:[NSColor whiteColor] withSize:16];
    
    if(_isEdit)
    {
        [self setButtonTitle:_btnCreate toString:@"Update Brand" withColor:[NSColor whiteColor] withSize:16];
        _lblHeading.stringValue = @"Edit Brand Profile";
    }
    else
    {
        _lblHeading.stringValue = @"Create New Brand Profile";
        [self setButtonTitle:_btnCreate toString:@"Create Brand" withColor:[NSColor whiteColor] withSize:16];
    }
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

-(BOOL)isEmailAdmin{
    NSString* email = [[NSUserDefaults standardUserDefaults] valueForKey:@"email"];
    
    if(email != nil && email.length > 0 && ([email hasSuffix:@"bon2.tv"] || [email hasSuffix:@"bon2.com"] || [email hasSuffix:@"watchtele.tv"])){
        return true;
    }
    else{
        return false;
    }
}

- (IBAction)btnCreateArtistClick:(id)sender {
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId.lowercaseString isEqualToString:@"bon2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    
    if(_txtBrandName.stringValue.length > 0 && _txtBrandName.stringValue.length > 0 && _txtProfileDescription.stringValue.length> 0)
    {
        /*if(_txtWebsite.stringValue.length > 0 || _txtFacebook.stringValue.length > 0 || _txtTwitter.stringValue.length > 0 || _txtInstagram.stringValue.length > 0 || _txtPinterest.stringValue.length > 0)
         {*/
        if(_imgProfilePic.image == nil || CGSizeEqualToSize(_imgProfilePic.image.size, CGSizeZero))
        {
            [self showAlert:@"Missing profile picture" message:@"Please drag and drop an image for profile picture"];
        }
        else
        {
            //firstName = _txtFirstName.stringValue;
            //lastName = _txtLastName.stringValue;
            b_brandName = _txtBrandName.stringValue;
            b_description = _txtProfileDescription.stringValue;
            b_website = _txtWebsite.stringValue;
            b_genre = _txtGenre.stringValue;
            b_facebook = _txtFacebook.stringValue;
            b_twitter = _txtTwitter.stringValue;
            b_instagram = _txtInstagram.stringValue;
            b_pinterest = _txtPinterest.stringValue;
            b_contributions = _txtArtistContribs.string;
            b_category = _cmbCategory.stringValue;
            
            if(b_facebook.length > 0 && ![b_facebook containsString:@"facebook"])
            {
                [self showAlert:@"Error" message:@"Incorrect facebook URL"];
            }
            else if(b_twitter.length > 0 && ![b_twitter containsString:@"twitter"])
            {
                [self showAlert:@"Error" message:@"Incorrect twitter URL"];
            }
            else if(b_instagram.length > 0 && ![b_instagram containsString:@"instagram"])
            {
                [self showAlert:@"Error" message:@"Incorrect instagram URL"];
            }
            else if(b_pinterest.length > 0 && ![b_pinterest containsString:@"pinterest"])
            {
                [self showAlert:@"Error" message:@"Incorrect pinterest URL"];
            }
            else
                [self startUpload];
        }
        /*}
         else
         {
         [self showAlert:@"Missing social media links" message:@"Please enter at least one social media link."];
         }*/
        
    }
    else
    {
        [self showAlert:@"Missing fields" message:@"Please enter brand name and profile."];
    }
}

-(void)startUpload{
    _btnClose.enabled = false;
    _btnCreate.enabled = false;
    //_txtFirstName.enabled = false;
    //_txtLastName.enabled = false;
    _txtBrandName.enabled = false;
    _progress.hidden = false;
    [_progress startAnimation:self];
    
    //Upload profile pic
    NSString* tempPath = [NSTemporaryDirectory() stringByAppendingString:@"tempArtistThumb.png"];
    
    
    CGImageRef cgRef = [_imgProfilePic.image CGImageForProposedRect:NULL
                                                            context:nil
                                                              hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[_imgProfilePic.image size]];   // if you want the same resolution
    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:nil];
    [pngData writeToFile:tempPath atomically:YES];
    NSURL *_selectedThumbnailUrl = [[NSURL alloc] initFileURLWithPath:tempPath];
    
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"com.bon2.userdatastore";
    thumbnailUploadRequest.key = [NSString stringWithFormat:@"artists/%@.png", _txtBrandName.stringValue];
    thumbnailUploadRequest.body = _selectedThumbnailUrl;
    thumbnailUploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    thumbnailUploadRequest.contentType = @"image/png";
    
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
            _btnCreate.enabled = true;
            _btnClose.enabled = true;
            _progress.hidden = true;
            //_txtFirstName.enabled = true;
            //_txtLastName.enabled = true;
            _txtBrandName.enabled = true;
            [_progress stopAnimation:self];
            [self showAlert:@"Error" message:@"Error uploading profile picture. Please try again."];
        }
        else
        {
            NSString* thumbnailUrl = [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/com.bon2.userdatastore/artists/%@.png", b_brandName];
            [self makeCreateArtistAPICall:thumbnailUrl];
            NSLog(@"%@", @"Image Uploaded.");
        }
        
        return nil;
    }];
}

-(void)makeCreateArtistAPICall:(NSString*)thumbnailUrl{
    NSData *json;
    NSString *jsonString;
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSError *error = nil;
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];
    
    
    [postUserData setValue:userId forKey:@"userId"];
    [postUserData setValue:accessToken forKey:@"accessToken"];
    
    if(_isEdit)
        [postUserData setValue:_artistId forKey:@"artistId"];
    
    [postUserData setValue:b_brandName forKey:@"firstName"];
    [postUserData setValue:@"" forKey:@"lastName"];
    [postUserData setValue:b_brandName forKey:@"nickName"];
    [postUserData setValue:b_description forKey:@"artistDescription"];
    [postUserData setValue:b_category forKey:@"generalCategory"];
    [postUserData setValue:NULL forKey:@"birthday"];
    [postUserData setValue:@"#" forKey:@"nationality"];
    [postUserData setValue:@"#" forKey:@"tags"];
    [postUserData setValue:@"#" forKey:@"age"];
    
    [postUserData setValue:b_genre forKey:@"genre"];
    [postUserData setValue:thumbnailUrl forKey:@"profilePicture"];
    
    if(b_facebook.length > 0)
        [postUserData setValue:b_facebook forKey:@"fbUrl"];
    else
        [postUserData setValue:@"" forKey:@"fbUrl"];
    
    if(b_instagram.length > 0)
        [postUserData setValue:b_instagram forKey:@"instagramUrl"];
    else
        [postUserData setValue:@"" forKey:@"instagramUrl"];
    
    if(b_pinterest.length > 0)
        [postUserData setValue:b_pinterest forKey:@"pintrestUrl"];
    else
        [postUserData setValue:@"" forKey:@"pintrestUrl"];
    
    if(b_twitter.length > 0)
        [postUserData setValue:b_twitter forKey:@"youtubeUrl"];
    else
        [postUserData setValue:@"" forKey:@"youtubeUrl"];
    
    if(b_website.length > 0)
        [postUserData setValue:b_website forKey:@"bon2Url"];
    else
        [postUserData setValue:@"" forKey:@"bon2Url"];
    
    
    NSArray *contribs;
    if(b_contributions.length > 0)
        contribs = [b_contributions componentsSeparatedByString: @"\n"]; //new line
    
    if(contribs != nil && contribs.count > 0)
    {
        NSMutableArray* artist_contribs = [NSMutableArray array];
        
        for (int i = 0; i < contribs.count; i++) {
            NSMutableDictionary* contribution_data = [[NSMutableDictionary alloc] init];
            [contribution_data setValue:contribs[i] forKey:@"mediaName"];
            [contribution_data setValue:contribs[i] forKey:@"description"];
            [contribution_data setValue:contribs[i] forKey:@"tags"];
            
            [artist_contribs addObject:contribution_data];
        }
        
        if(artist_contribs.count > 0)
            [postUserData setObject:artist_contribs forKey:@"mediaList"];
        
    }
    
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, CREATE_ARTIST];
    
    if(_isEdit)
        url = [NSString stringWithFormat:@"%@%@",BASE_URL, UPDATE_ARTIST];
    
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
                 _btnCreate.enabled = true;
                 _btnClose.enabled = true;
                 _progress.hidden = true;
                 //_txtFirstName.enabled = true;
                 //_txtLastName.enabled = true;
                 _txtBrandName.enabled = true;
                 //_txtProfileDescription.enabled = true;
                 [_progress stopAnimation:self];
                 
                 NSString* msg = [NSString stringWithFormat:@"Created brand profile for %@",_txtBrandName.stringValue];
                 
                 if(_isEdit){
                     msg = [NSString stringWithFormat:@"Updated brand profile for %@",_txtBrandName.stringValue];
                     [((SearchArtistsController*)self.presentingViewController) reloadData];
                 }
                 
                 [self showAlert:@"Success" message:msg];
                 
                 if(!_isEdit)
                     [self clearAllFields];
             }
             else{
                 dispatch_async(dispatch_get_main_queue(), ^(void){
                     _btnCreate.enabled = true;
                     _btnClose.enabled = true;
                     _progress.hidden = true;
                     //_txtFirstName.enabled = true;
                     //_txtLastName.enabled = true;
                     _txtBrandName.enabled = true;
                     //_txtProfileDescription.enabled = true;
                     [_progress stopAnimation:self];
                     [self showAlert:@"Error" message:@"Server error while creating brand profile. Please try again."];
                 });
             }
         });
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"%@", task.error);
         dispatch_async(dispatch_get_main_queue(), ^(void){
             _btnCreate.enabled = true;
             _btnClose.enabled = true;
             _progress.hidden = true;
             //_txtFirstName.enabled = true;
             //_txtLastName.enabled = true;
             _txtBrandName.enabled = true;
             //_txtProfileDescription.enabled = true;
             [_progress stopAnimation:self];
             [self showAlert:@"Error" message:@"Error creating brand profile. Please try again."];
         });
     }
     ];
}

-(void)viewDidDisappear
{
    _artistId = @"";
}

-(void)clearAllFields
{
    //_txtFirstName.stringValue = @"";
    //_txtLastName.stringValue = @"";
    _txtBrandName.stringValue = @"";
    _txtGenre.stringValue = @"Brand";
    _txtWebsite.stringValue = @"";
    _txtProfileDescription.stringValue = @"";
    _txtFacebook.stringValue = @"";
    _txtInstagram.stringValue = @"";
    _txtPinterest.stringValue = @"";
    _txtTwitter.stringValue = @"";
    [_cmbCategory setObjectValue:@"No Category"];
    _imgProfilePic.image = nil;
}

- (IBAction)btnCloseClick:(id)sender {
    [self dismissViewController:self];
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

/*
// -------------------------------------------------------------------------------
//  createPopover
// -------------------------------------------------------------------------------
- (void)createPopover
{
    if (self.myPopover == nil)
    {
        // create and setup our popover
        _myPopover = [[NSPopover alloc] init];
        
        // the popover retains us and we retain the popover,
        // we drop the popover whenever it is closed to avoid a cycle
        
        self.myPopover.contentViewController = self.popoverViewController;
        
        self.myPopover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
        
        self.myPopover.animates = true;
        
        // AppKit will close the popover when the user interacts with a user interface element outside the popover.
        // note that interacting with menus or panels that become key only when needed will not cause a transient popover to close.
        self.myPopover.behavior = NSPopoverBehaviorTransient;
        
        // so we can be notified when the popover appears or closes
        self.myPopover.delegate = self;
    }
}

// -------------------------------------------------------------------------------
// Invoked on the delegate to give permission to detach popover as a separate window.
// -------------------------------------------------------------------------------
- (BOOL)popoverShouldDetach:(NSPopover *)popover
{
    return NO;
}

- (IBAction)btnSelectGenre:(id)sender {
    [self createPopover];
    NSButton *targetButton = (NSButton *)sender;
    [self.myPopover showRelativeToRect:targetButton.bounds ofView:sender preferredEdge:NSMaxYEdge];
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverDidCloseNotification notification is sent.
// This method will also be invoked on the popover.
// -------------------------------------------------------------------------------
- (void)popoverDidClose:(NSNotification *)notification
{
    NSString *closeReason = [notification.userInfo valueForKey:NSPopoverCloseReasonKey];
    if (closeReason)
    {
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        //
        // add new code here if you want to respond "after" the popover closes
        //
        NSString* selectedTags = @"";
        for (int i = 0; i < _popoverViewController.selectedGenres.count; i++) {
            selectedTags = [selectedTags stringByAppendingString:[NSString stringWithFormat:@"%@, ",[_popoverViewController.selectedGenres objectAtIndex:i]] ];
        }
        
        if([selectedTags hasSuffix:@", "])
        {
            selectedTags = [selectedTags substringToIndex:[selectedTags length] - 2];
        }
        
        _txtGenre.stringValue = selectedTags;
    }
    
    // release our popover since it closed
    _myPopover = nil;
}
*/
@end
