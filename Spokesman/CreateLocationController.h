//
//  CreateLocationController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 10/12/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "ViewController.h"
#import <Cocoa/Cocoa.h>
@import AVKit;
#import "AppConstant.h"
#import "AFNetworking.h"
//@import AFNetworking;
#import "AWSCore/AWSCore.h"
#import "AWSS3/AWSS3.h"

NS_ASSUME_NONNULL_BEGIN

@interface CreateLocationController : NSViewController
@property (weak) IBOutlet NSTextField *txtProfileDescription;
@property (weak) IBOutlet NSTextField *txtWebsite;
@property (weak) IBOutlet NSTextField *txtGenre;
@property (weak) IBOutlet NSTextField *txtFacebook;
@property (weak) IBOutlet NSTextField *txtInstagram;
@property (weak) IBOutlet NSTextField *txtPinterest;
@property (weak) IBOutlet NSTextField *txtTwitter;
@property (weak) IBOutlet NSImageView *imgProfilePic;
- (IBAction)btnCreateArtistClick:(id)sender;
- (IBAction)btnCloseClick:(id)sender;
@property (weak) IBOutlet NSButton *btnClose;
@property (weak) IBOutlet NSButton *btnCreate;
@property (weak) IBOutlet NSProgressIndicator *progress;
@property (weak) IBOutlet NSTextField *txtLocationName;
//@property (weak) IBOutlet NSTextField *txtArtistContributions;
@property (unsafe_unretained) IBOutlet NSTextView *txtArtistContribs;

@property (strong) NSString* artistId;
@property (strong) NSString* locationName;
@property (strong) NSString* profile;
@property (strong) NSString* website;
@property (strong) NSString* genre;
@property (strong) NSString* fb;
@property (strong) NSString* tw;
@property (strong) NSString* insta;
@property (strong) NSString* pinterest;
@property (strong) NSString* contributions;
@property (strong) NSImage* profilePic;

@property BOOL isEdit;
@property (weak) IBOutlet NSTextField *lblHeading;
@end

NS_ASSUME_NONNULL_END
