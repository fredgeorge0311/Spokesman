//
//  InviteUserModalController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 09/02/17.
//  Copyright © 2017 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InviteUserModalController : NSWindowController
@property (weak) IBOutlet NSTextField *txtUserName;
@property (weak) IBOutlet NSTextField *txtEmail;
@property (weak) IBOutlet NSTextField *txtPassword;
@property (weak) IBOutlet NSProgressIndicator *activityIndicator;

@property (weak) IBOutlet NSBox *activityBg;
@end
