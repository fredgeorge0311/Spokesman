//
//  ViewController.m
//  Spokesman
//
//  Created by chaitanya venneti on 23/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "ViewController.h"
#import "LoginRegisterViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self setButtonTitle:_btnLogin toString:@"LOGIN" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnSignup toString:@"SIGN UP" withColor:[NSColor whiteColor] withSize:18];
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

-(void)viewWillAppear{
    [super viewWillAppear];
    
    [_landingPageView setWantsLayer:YES];
    [_landingPageView.layer setBackgroundColor:[[NSColor blackColor] CGColor]];
    
    NSString* terms = [[NSUserDefaults standardUserDefaults] valueForKey:@"terms-agreed"];
    
    if(terms != nil && [terms isEqualToString:@"yes"])
    {
        _smallLogo.hidden = true;
        _txtTerms.hidden = true;
        _btnExit.hidden = true;
        _btnAgree.hidden = true;
        
        _mainLogo.hidden = false;
        _btnLogin.hidden = false;
        _btnSignup.hidden = false;

//        NSString* token = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];
//        if (token != nil && token.length > 0) {
//            [self showLoginSignup:true];
//        }
    }
    else{
        _smallLogo.hidden = false;
        _txtTerms.hidden = false;
        _btnExit.hidden = false;
        _btnAgree.hidden = false;
        
        _mainLogo.hidden = true;
        _btnLogin.hidden = true;
        _btnSignup.hidden = true;
    }
}

- (IBAction)btnAgreeClick:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"terms-agreed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    _smallLogo.hidden = true;
    _txtTerms.hidden = true;
    _btnExit.hidden = true;
    _btnAgree.hidden = true;
    
    _mainLogo.hidden = false;
    _btnLogin.hidden = false;
    _btnSignup.hidden = false;
}

- (IBAction)btnExitClick:(id)sender {
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction)btnLoginClick:(id)sender {
    [self showLoginSignup:true];
}

-(void)showLoginSignup:(BOOL)showLogin{
    LoginRegisterViewController *loginViewController = [self.storyboard instantiateControllerWithIdentifier:@"LoginRegisterViewController"];
    loginViewController.showLogin = showLogin;
    NSRect _mainframe = _landingPageView.frame;
    [[loginViewController view] setFrame:_mainframe];
    self.view.window.contentViewController = loginViewController;
}

- (IBAction)btnSignupClick:(id)sender {
    [self showLoginSignup:false];
}
@end
