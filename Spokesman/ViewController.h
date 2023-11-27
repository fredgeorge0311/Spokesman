//
//  ViewController.h
//  Spokesman
//
//  Created by chaitanya venneti on 23/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (strong) IBOutlet NSView *landingPageView;
@property (weak) IBOutlet NSImageView* bgImageView;
@property (weak) IBOutlet NSButton *btnLogin;
@property (weak) IBOutlet NSButton *btnSignup;
@property (strong) IBOutlet NSButton *btnAgree;
@property (strong) IBOutlet NSButton *btnExit;
@property (strong) IBOutlet NSScrollView *txtTerms;
- (IBAction)btnAgreeClick:(id)sender;
- (IBAction)btnExitClick:(id)sender;
@property (strong) IBOutlet NSImageView *mainLogo;
@property (strong) IBOutlet NSImageView *smallLogo;

- (IBAction)btnLoginClick:(id)sender;
- (IBAction)btnSignupClick:(id)sender;
@end

