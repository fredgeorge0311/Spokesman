//
//  CreateArtistController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 29/12/17.
//  Copyright © 2017 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import AVKit;
#import "AppConstant.h"
#import "AFNetworking.h"
//@import AFNetworking;
#import "AWSCore/AWSCore.h"
#import "AWSS3/AWSS3.h"
#import "GenrePopoverViewController.h"

@interface CreateArtistController : NSViewController<NSPopoverDelegate>

@property (strong) NSPopover *myPopover;
@property (strong) /*ExportViewController*/GenrePopoverViewController *popoverViewController;

@property (weak) IBOutlet NSTextField *txtFirstName;
@property (weak) IBOutlet NSTextField *txtLastName;
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
@property (weak) IBOutlet NSTextField *txtNickName;
//@property (weak) IBOutlet NSTextField *txtArtistContributions;
@property (unsafe_unretained) IBOutlet NSTextView *txtArtistContribs;

@property (strong) NSString* artistId;
@property (strong) NSString* firstName;
@property (strong) NSString* lastName;
@property (strong) NSString* nickName;
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
- (IBAction)btnSelectGenre:(id)sender;

@end
