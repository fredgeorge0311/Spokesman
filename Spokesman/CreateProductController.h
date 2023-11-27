//
//  CreateProductController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 11/03/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import AVKit;
#import "AppConstant.h"
#import "AFNetworking.h"
//@import AFNetworking;
#import "AWSCore/AWSCore.h"
#import "AWSS3/AWSS3.h"

@interface CreateProductController : NSViewController
    @property (weak) IBOutlet NSTextField *txtProductName;
    @property (strong) IBOutlet NSTextView *txtProfileDescription;
    @property (weak) IBOutlet NSTextField *txtLink5;
    @property (weak) IBOutlet NSTextField *txtLink1;
    @property (weak) IBOutlet NSTextField *txtLink2;
    @property (weak) IBOutlet NSTextField *txtLink3;
    @property (weak) IBOutlet NSTextField *txtLink4;
    @property (weak) IBOutlet NSImageView *imgProductPic;
    - (IBAction)btnCreateProductClick:(id)sender;
    - (IBAction)btnCloseClick:(id)sender;
    @property (weak) IBOutlet NSButton *btnClose;
    @property (weak) IBOutlet NSButton *btnCreate;
    @property (weak) IBOutlet NSProgressIndicator *progress;
    @property (weak) IBOutlet NSTextField *txtBrandName;
    @property (weak) IBOutlet NSButton *chkIsGeneralCategory;

    @property (strong) NSString* productId;
    @property (strong) NSString* productName;
    @property (strong) NSString* brandName;
    @property (strong) NSString* profile;
    @property (strong) NSString* keywords;
    @property (strong) NSString* originalPicture;
    @property (strong) NSString* link5;
    @property (strong) NSString* link1;
    @property (strong) NSString* link2;
    @property (strong) NSString* link3;
    @property (strong) NSString* link4;
    @property (strong) NSImage* profilePic;

    @property (strong) IBOutlet NSTextField *txtKeywords;
    - (IBAction)imageSelected:(id)sender;

    @property BOOL isEdit;
    @property BOOL isGeneralCategory;
    @property (weak) IBOutlet NSTextField *lblHeading;
@end
