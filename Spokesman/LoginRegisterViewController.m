//
//  LoginRegisterViewController.m
//  Spokesman
//
//  Created by chaitanya venneti on 23/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "LoginRegisterViewController.h"
#import "MainCanvasViewController.h"
#import "AFNetworking.h"
//@import AFNetworking;
#import "AppConstant.h"
#import "UserModel.h"

@interface LoginRegisterViewController ()

@end

@implementation LoginRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [_loginRegisterView setWantsLayer:YES];
    [_loginRegisterView.layer setBackgroundColor:[[NSColor colorWithCalibratedRed:0/255 green:17/255 blue:24/255 alpha:1] CGColor]];
    
    //_txtSignupUsername.delegate = self;
    
    [self setButtonTitle:_btnLogin toString:@"LOGIN" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnShowLogin toString:@"LOGIN" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnSignup toString:@"SIGN UP" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnShowSignUp toString:@"SIGN UP" withColor:[NSColor whiteColor] withSize:18];
    
    [self setPlaceholderTitle:_txtSignupUsername toString:@"USERNAME" withColor:[NSColor whiteColor] withSize:14];
    [self setPlaceholderTitle:_txtSignupEmail toString:@"EMAIL" withColor:[NSColor whiteColor] withSize:14];
    [self setPlaceholderTitle:_txtSignupPassword toString:@"PASSWORD" withColor:[NSColor whiteColor] withSize:14];
    [self setPlaceholderTitle:_txtSignupConfirm toString:@"CONFIRM PASSWORD" withColor:[NSColor whiteColor] withSize:14];
    
    [self setPlaceholderTitle:_txtLoginUsername toString:@"USERNAME" withColor:[NSColor whiteColor] withSize:14];
    [self setPlaceholderTitle:_txtLoginPassword toString:@"PASSWORD" withColor:[NSColor whiteColor] withSize:14];
}

-(void)viewWillAppear{
    [super viewWillAppear];
    
    if(_showLogin)
    {
        _loginbox.hidden = false;
        _signupbox.hidden = true;
    }
    else
    {
        _loginbox.hidden = true;
        _signupbox.hidden = false;
    }
}

-(void) makeLoginAPICall
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSDictionary *dict = @{@"userId" : _txtLoginUsername.stringValue, @"password":_txtLoginPassword.stringValue};
    NSError *error = nil;
    NSData *json;
    NSString *jsonString;

    // Dictionary convertable to JSON ?
    if ([NSJSONSerialization isValidJSONObject:dict])
    {
        // Serialize the dictionary
        json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        // If no errors, let's view the JSON
        if (json != nil && error == nil)
        {
            jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
            NSLog(@"JSON: %@", jsonString);
        }
    }
    
    NSDictionary *params = @{@"data" : jsonString};
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL,LOGIN_USER];
    [self showTableRefreshAnimation];
    [manager POST:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        [self hideTableRefreshAnimation];
        NSMutableDictionary* response = responseObject;
        NSString* status = [response valueForKey:@"responseStatus"];
        if([status isEqualToString:@"200"])
        {
            //1. Save the response object to local data using SQLite
            //2. Navigate to home page
            NSDictionary *response = [responseObject valueForKey:@"responseObj"];
            NSString *userId = [response valueForKey:@"userId"];
            NSString *accessToken = [response valueForKey:@"accessToken"];
            [[NSUserDefaults standardUserDefaults] setValue:userId forKey:@"userId"];
            [[NSUserDefaults standardUserDefaults] setValue:accessToken forKey:@"accessToken"];
            [[NSUserDefaults standardUserDefaults] setValue:_txtLoginUsername.stringValue forKey:@"userName"];
            [[NSUserDefaults standardUserDefaults] setValue:[response valueForKey:@"email"] forKey:@"email"];
            [[NSUserDefaults standardUserDefaults] setValue:[response valueForKey:@"isStationPartner"] forKey:@"isStationPartner"];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self showMainCanvas:_txtLoginUsername.stringValue];
        }
        else if([status isEqualToString:@"503"] || [status isEqualToString:@"504"])
        {
            [self showAlert:@"Login Error" message:[response valueForKey:@"responseObj"]];
        }
        else
        {
            [self showAlert:@"Login Error" message:@"Incorrect Username or Password"];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self hideTableRefreshAnimation];
        [self showAlert:@"Server Error" message:@"Please try again."];
    }];
}

-(void) registerUser{
    NSData *json;
    NSString *jsonString;
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSError *error = nil;
    
    UserModel *registerUser = [[UserModel alloc] init];
    
    registerUser.userId = _txtSignupUsername.stringValue;
    registerUser.password = _txtSignupPassword.stringValue;
    registerUser.email = _txtSignupEmail.stringValue;
    registerUser.profilePicture = @"";
    
    //Preparing data for API Call
    
    [postUserData setValue:registerUser.userId forKey:@"userId"];
    [postUserData setValue:registerUser.password forKey:@"password"];
    [postUserData setValue:registerUser.accessToken forKey:@"accessToken"];
    [postUserData setValue:registerUser.lastLogin forKey:@"lastLogin"];
    [postUserData setValue:registerUser.accessTokenRefreshTime forKey:@"accessTokenRefreshTime"];
    [postUserData setValue:registerUser.firstName forKey:@"firstName"];
    [postUserData setValue:registerUser.lastName forKey:@"lastName"];
    
    if (registerUser.email.length != 0)
    {
        [postUserData setValue:registerUser.email forKey:@"email"];
    }
    
    [postUserData setValue:registerUser.phone forKey:@"phone"];
    [postUserData setValue:registerUser.profilePicture forKey:@"profilePicture"];
    [postUserData setValue:@"normalUser" forKey:@"userType"];
    [postUserData setValue:registerUser.location forKey:@"location"];
    
    NSMutableArray* musicPrefList = [[NSMutableArray alloc] init];
    [postUserData setValue:musicPrefList forKey:@"musicPrefList"];

    json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
        
    // If no errors, let's view the JSON
    
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        NSLog(@"JSON: %@", jsonString);
    }
    
    NSDictionary *params = @{@"data" : jsonString};
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, REGISTER_USER];

    [self showTableRefreshAnimation];

    [manager POST:url parameters:params
            success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject)
            {
                [self hideTableRefreshAnimation];
                
                NSMutableDictionary* response = responseObject;
                NSString* status = [response valueForKey:@"responseStatus"];
                
                if([status isEqualToString:@"200"])
                {
                     NSDictionary* response = [responseObject objectForKey:@"responseObj"];
                     NSString *accessToken = [response objectForKey:@"accessToken"];
                     NSString *userId = [response valueForKey:@"userId"];
                     [[NSUserDefaults standardUserDefaults] setValue:userId forKey:@"userId"];
                     [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"accessToken"];
                     [[NSUserDefaults standardUserDefaults] setValue:_txtSignupEmail.stringValue forKey:@"email"];
                     [[NSUserDefaults standardUserDefaults] synchronize];
                
                    [self showMainCanvas:_txtSignupUsername.stringValue];
                }
                else
                {                                        
                    [self showAlert:@"Registration Error" message:[[responseObject objectForKey:@"status"] objectForKey:@"message"]];
                }
            }
            failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
            {
                [self hideTableRefreshAnimation];
                [self showAlert:@"Server Error" message:@"Please try again."];
            }
     ];
}

-(void)hideTableRefreshAnimation
{
    _activityBg.hidden = true;
    _activityIndicator.hidden = true;
    [_activityIndicator stopAnimation:_activityIndicator];
}

-(void)showTableRefreshAnimation
{
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:@"3.0" forKey:@"inputRadius"];
    
    _activityBg.backgroundFilters = [NSArray arrayWithObject:blurFilter];
    
    _activityBg.hidden = false;
    _activityIndicator.hidden = false;
    [_activityIndicator startAnimation:_activityIndicator];
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

-(void)showMainCanvas:(NSString*)username{
    MainCanvasViewController *canvasViewController = [self.storyboard instantiateControllerWithIdentifier:@"MainCanvasViewController"];
    
    if(username.length == 0)
        username = @"Username";
    
    canvasViewController.username = username;
    NSRect _mainframe = _loginRegisterView.frame;
    [[canvasViewController view] setFrame:_mainframe];
    self.view.window.contentViewController = canvasViewController;
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

-(void)setPlaceholderTitle:(NSTextField*)txtField toString:(NSString*)title withColor:(NSColor*)color withSize:(int)size{
    NSFont *txtFont = [NSFont systemFontOfSize:size];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
    [paragraphStyle setAlignment:NSTextAlignmentLeft];

    NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             txtFont, NSFontAttributeName, color, NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:title attributes:txtDict];
    [attrStr addAttributes:[NSDictionary dictionaryWithObject:paragraphStyle forKey:NSParagraphStyleAttributeName] range:NSMakeRange(0,[attrStr length])];

    //[attrStr addAttribute: NSBaselineOffsetAttributeName value: [NSNumber numberWithFloat: -10.0] range: NSMakeRange(0, [attrStr length])];

    [txtField setPlaceholderAttributedString:attrStr];
}

- (IBAction)btnShowSignUpClick:(id)sender {
    _loginbox.hidden = true;
    _signupbox.hidden = false;
}

- (IBAction)btnForgotPasswordClick:(id)sender {
}

- (IBAction)btnSignupClick:(id)sender {
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,10}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];

    if ([emailTest evaluateWithObject:_txtSignupEmail.stringValue] == NO) {

        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Invalid Email!"];
        [alert setInformativeText:@"Please enter a valid email address."];
        [alert setAlertStyle:NSWarningAlertStyle];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked, delete the record
        }

        return;
    }

    if (_txtSignupUsername.stringValue.length == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Invalid Username!"];
        [alert setInformativeText:@"Username cannot be empty."];
        [alert setAlertStyle:NSWarningAlertStyle];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked, delete the record
        }

        return;
    }

    if (_txtSignupPassword.stringValue.length == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Invalid Password!"];
        [alert setInformativeText:@"Password cannot be empty."];
        [alert setAlertStyle:NSWarningAlertStyle];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked, delete the record
        }

        return;
    }

    if (![_txtSignupPassword.stringValue isEqualToString:_txtSignupConfirm.stringValue]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Invalid Passwords!"];
        [alert setInformativeText:@"Passwords does not match."];
        [alert setAlertStyle:NSWarningAlertStyle];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked, delete the record
        }

        return;
    }

    [self registerUser];
}

- (IBAction)btnShowLoginClick:(id)sender {
    _loginbox.hidden = false;
    _signupbox.hidden = true;
}

- (IBAction)btnLoginClick:(id)sender {
    if (_txtLoginUsername.stringValue.length == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Invalid Username!"];
        [alert setInformativeText:@"Username cannot be empty."];
        [alert setAlertStyle:NSWarningAlertStyle];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked, delete the record
        }

        return;
    }

    if (_txtLoginPassword.stringValue.length == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Invalid Password!"];
        [alert setInformativeText:@"Password cannot be empty."];
        [alert setAlertStyle:NSWarningAlertStyle];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked, delete the record
        }

        return;
    }

    [self makeLoginAPICall];
}
@end
