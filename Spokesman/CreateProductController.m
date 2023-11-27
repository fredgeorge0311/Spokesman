//
//  CreateProductController.m
//  Spokesman
//
//  Created by Chaitanya VRK on 11/03/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "CreateProductController.h"
#import "SearchProductsController.h"

@interface CreateProductController ()
{
    BOOL isImageChanged;
}
@end

@implementation CreateProductController

NSString* productName;
NSString* brandName;
NSString* proddescription;
NSString* productKeywords;
NSString* link1;
NSString* link2;
NSString* link3;
NSString* link4;
NSString* link5;
BOOL isGeneralCategory;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)viewDidAppear
{
    [self clearAllFields];
    
    if(_productName.length > 0)
        _txtProductName.stringValue = _productName;
    if(_brandName.length > 0)
        _txtBrandName.stringValue = _brandName;
                
    if(_profile != nil && _profile.length > 0)
       [_txtProfileDescription setString:_profile];
    
    if(_keywords != nil && _keywords.length > 0)
        _txtKeywords.stringValue = _keywords;
    
    if(_link1 != nil && _link1.length > 0)
        _txtLink1.stringValue = _link1;
    if(_link2 != nil && _link2.length > 0)
        _txtLink2.stringValue = _link2;
    if(_link3 != nil && _link3.length > 0)
        _txtLink3.stringValue = _link3;
    if(_link4 != nil && _link4.length > 0)
        _txtLink4.stringValue = _link4;
    if(_link5 != nil &&_link5.length > 0)
        _txtLink5.stringValue = _link5;

    if(_profilePic != nil)
        _imgProductPic.image = _profilePic;
    
    if(_isGeneralCategory)
        _chkIsGeneralCategory.state = 1;
    else
        _chkIsGeneralCategory.state = 0;

    [self setButtonTitle:_btnClose toString:@"Close" withColor:[NSColor whiteColor] withSize:16];
    
    if(_isEdit)
    {
        [self setButtonTitle:_btnCreate toString:@"Update Product" withColor:[NSColor whiteColor] withSize:16];
        _lblHeading.stringValue = @"Edit Product Details";
    }
    else
    {
        _lblHeading.stringValue = @"Create New Product";
        [self setButtonTitle:_btnCreate toString:@"Create Product" withColor:[NSColor whiteColor] withSize:16];
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

- (IBAction)btnCreateProductClick:(id)sender {
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId.lowercaseString isEqualToString:@"bon2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    
    if(_txtBrandName.stringValue.length > 0 && _txtLink1.stringValue.length > 0)
    {
        /*if(_txtWebsite.stringValue.length > 0 || _txtFacebook.stringValue.length > 0 || _txtTwitter.stringValue.length > 0 || _txtInstagram.stringValue.length > 0 || _txtPinterest.stringValue.length > 0)
         {*/
        if(_imgProductPic.image == nil || CGSizeEqualToSize(_imgProductPic.image.size, CGSizeZero))
        {
            [self showAlert:@"Missing product image" message:@"Please drag and drop an image for product"];
        }
        else
        {
            productName = _txtProductName.stringValue;
            brandName = _txtBrandName.stringValue;
            proddescription = _txtProfileDescription.string;
            productKeywords = _txtKeywords.stringValue;
            link1 = _txtLink1.stringValue;
            link2 = _txtLink2.stringValue;
            link3 = _txtLink3.stringValue;
            link4 = _txtLink4.stringValue;
            link5 = _txtLink5.stringValue;
            isGeneralCategory = _chkIsGeneralCategory.state;
            //To do: Add URL Validation
            if(!_isEdit)
                [self startUpload];
            else
            {
                if(isImageChanged)
                    [self startUpload];
                else{
                    _btnClose.enabled = false;
                    _btnCreate.enabled = false;
                    _txtBrandName.enabled = false;
                    _txtProductName.enabled = false;
                    _txtKeywords.enabled = false;
                    _progress.hidden = false;
                    [_progress startAnimation:self];
                    [self makeCreateArtistAPICall:_originalPicture];
                }
            }
        }
        /*}
         else
         {
         [self showAlert:@"Missing social media links" message:@"Please enter at least one social media link."];
         }*/
        
    }
    else
    {
        [self showAlert:@"Missing fields" message:@"Please enter brand name and primary link."];
    }
}

-(void)startUpload{
    _btnClose.enabled = false;
    _btnCreate.enabled = false;
    _txtBrandName.enabled = false;
    _txtProductName.enabled = false;
    _txtKeywords.enabled = false;
    _progress.hidden = false;
    [_progress startAnimation:self];
    
    //Upload profile pic
    NSString* tempPath = [NSTemporaryDirectory() stringByAppendingString:@"tempArtistThumb.png"];
    
    
    CGImageRef cgRef = [_imgProductPic.image CGImageForProposedRect:NULL
                                                            context:nil
                                                              hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[_imgProductPic.image size]];   // if you want the same resolution
    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:nil];
    [pngData writeToFile:tempPath atomically:YES];
    NSURL *_selectedThumbnailUrl = [[NSURL alloc] initFileURLWithPath:tempPath];
    
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"com.bon2.userdatastore";
    thumbnailUploadRequest.key = [NSString stringWithFormat:@"products/%@%@.png", _txtProductName.stringValue, _txtBrandName.stringValue];
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
            _txtProductName.enabled = true;
            _txtBrandName.enabled = true;
            [_progress stopAnimation:self];
            [self showAlert:@"Error" message:@"Error uploading product picture. Please try again."];
        }
        else
        {
            NSString* thumbnailUrl = [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/com.bon2.userdatastore/products/%@%@.png", productName, brandName];
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
        [postUserData setValue:_productId forKey:@"productId"];
    
    [postUserData setValue:productName forKey:@"productName"];
    [postUserData setValue:brandName forKey:@"brandName"];
    [postUserData setValue:proddescription forKey:@"productDescription"];
    [postUserData setValue:productKeywords forKey:@"keywords"];
    [postUserData setValue:thumbnailUrl forKey:@"picture"];
    [postUserData setValue:@"" forKey:@"website"];
    
    if(isGeneralCategory)///to do: send the general category name selected in dropdown
        [postUserData setValue:@"Y" forKey:@"generalCategory"];
    else
        [postUserData setValue:@"N" forKey:@"generalCategory"];
    
    if(link1.length > 0)
        [postUserData setValue:link1 forKey:@"shopLink1"];
    else
        [postUserData setValue:@"" forKey:@"shopLink1"];
    
    if(link2.length > 0)
        [postUserData setValue:link2 forKey:@"shopLink2"];
    else
        [postUserData setValue:@"" forKey:@"shopLink2"];
    
    if(link3.length > 0)
        [postUserData setValue:link3 forKey:@"shopLink3"];
    else
        [postUserData setValue:@"" forKey:@"shopLink3"];
    
    if(link4.length > 0)
        [postUserData setValue:link4 forKey:@"shopLink4"];
    else
        [postUserData setValue:@"" forKey:@"shopLink4"];
    
    if(link5.length > 0)
        [postUserData setValue:link5 forKey:@"shopLink5"];
    else
        [postUserData setValue:@"" forKey:@"shopLink5"];
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, CREATE_PRODUCT];
    
    if(_isEdit)
        url = [NSString stringWithFormat:@"%@%@",BASE_URL, UPDATE_PRODUCT];
        
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
                 _txtProductName.enabled = true;
                 _txtBrandName.enabled = true;
                 _txtKeywords.enabled = true;
                 _txtLink1.enabled = true;
                 //_txtProfileDescription.enabled = true;
                 isImageChanged = false;
                 [_progress stopAnimation:self];
                 
                 NSString* msg = [NSString stringWithFormat:@"Created product entry for %@ of brand %@.",_txtProductName.stringValue, _txtBrandName.stringValue];
                 
                 if(_isEdit){
                     msg = [NSString stringWithFormat:@"Updated product entry for %@ of brand %@.",_txtProductName.stringValue, _txtBrandName.stringValue];
                     [((SearchProductsController*)self.presentingViewController) reloadData];
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
                     _txtProductName.enabled = true;
                     _txtBrandName.enabled = true;
                     _txtLink1.enabled = true;
                     //_txtProfileDescription.enabled = true;
                     [_progress stopAnimation:self];
                     [self showAlert:@"Error" message:@"Server error while creating product. Please try again."];
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
             _txtProductName.enabled = true;
             _txtBrandName.enabled = true;
             _txtLink1.enabled = true;
             //_txtProfileDescription.enabled = true;
             [_progress stopAnimation:self];
             [self showAlert:@"Error" message:@"Error creating product. Please try again."];
         });
     }
     ];
}

-(void)viewDidDisappear
{
    _productId = @"";
}

-(void)clearAllFields
{
    _txtProductName.stringValue = @"";
    _txtBrandName.stringValue = @"";
    [_txtProfileDescription setString:@""];
    _txtLink1.stringValue = @"";
    _txtLink2.stringValue = @"";
    _txtLink3.stringValue = @"";
    _txtLink4.stringValue = @"";
    _txtLink5.stringValue = @"";
    _txtKeywords.stringValue = @"";
    
    _imgProductPic.image = nil;
    
    isImageChanged = false;
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

- (IBAction)imageSelected:(id)sender {
    isImageChanged = true;
}
@end

