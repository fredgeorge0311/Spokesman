//
//  LoginRegisterViewController.h
//  Spokesman
//
//  Created by chaitanya venneti on 23/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreImage/CoreImage.h>

@interface LoginRegisterViewController : NSViewController<NSTextFieldDelegate>

@property BOOL showLogin;

@property (strong) IBOutlet NSView *loginRegisterView;

//Login Box fields
@property (weak) IBOutlet NSButton *btnShowSignUp;
@property (weak) IBOutlet NSButton *btnLogin;
@property (weak) IBOutlet NSBox *loginbox;
@property (weak) IBOutlet NSTextField *txtLoginUsername;
@property (weak) IBOutlet NSSecureTextField *txtLoginPassword;
@property (weak) IBOutlet NSButton *btnForgotPassword;

- (IBAction)btnLoginClick:(id)sender;
- (IBAction)btnShowSignUpClick:(id)sender;
- (IBAction)btnForgotPasswordClick:(id)sender;

//Signup Box fields
@property (weak) IBOutlet NSBox *signupbox;
@property (weak) IBOutlet NSTextField *txtSignupUsername;
@property (weak) IBOutlet NSTextField *txtSignupEmail;
@property (weak) IBOutlet NSTextField *txtSignupPassword;
@property (weak) IBOutlet NSTextField *txtSignupConfirm;
@property (weak) IBOutlet NSButton *btnSignup;
@property (weak) IBOutlet NSButton *btnShowLogin;

- (IBAction)btnSignupClick:(id)sender;
- (IBAction)btnShowLoginClick:(id)sender;

@property (weak) IBOutlet NSProgressIndicator *activityIndicator;
@property (weak) IBOutlet NSBox *activityBg;

@end
