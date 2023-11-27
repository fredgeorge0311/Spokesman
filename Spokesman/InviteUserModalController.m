//
//  InviteUserModalController.m
//  Spokesman
//
//  Created by Chaitanya VRK on 09/02/17.
//  Copyright © 2017 troomobile. All rights reserved.
//

#import "InviteUserModalController.h"
#import "AFNetworking.h"
//@import AFNetworking;
#import "AppConstant.h"
#import "UserModel.h"

@import CoreImage;

@interface InviteUserModalController ()

@end

@implementation InviteUserModalController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)didTapCancelButton:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    
    //[self showTableRefreshAnimation];
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

- (IBAction)didTapDoneButton:(id)sender {
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId.lowercaseString isEqualToString:@"bon2admin"]  && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    
    if(_txtEmail.stringValue.length > 0 && _txtPassword.stringValue.length > 0 && _txtUserName.stringValue.length > 0)
    {
        [self registerUser];
    }
    else
    {
        [self showAlert:@"Validation error" message:@"All fields are mandatory."];
    }
}

-(void)showAlert:(NSString*)title message:(NSString*)message{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        // OK clicked
    }
    
}

-(void)hideTableRefreshAnimation
{
    _activityBg.backgroundFilters = nil;
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

-(void) registerUser{
        
        NSData *json;
        NSString *jsonString;
        NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
        
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        
        NSError *error = nil;
        
        UserModel *registerUser = [[UserModel alloc] init];
        
        registerUser.userId = _txtUserName.stringValue;
        registerUser.password = _txtPassword.stringValue;
        registerUser.email = _txtEmail.stringValue;
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
                 [self showAlert:@"New User Created" message:@"A Spokesman account is created and the details are e-mailed to the user."];
                 
                 _txtUserName.stringValue = @"";
                 _txtPassword.stringValue = @"";
                 _txtEmail.stringValue = @"";
                 
                 //[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
             }
             else
             {
                 [self showAlert:@"Registration Error" message:[responseObject objectForKey:@"responseObj"]];
             }
         }
              failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
         {
             [self hideTableRefreshAnimation];
             [self showAlert:@"Server Error" message:@"Please try again."];
         }
         ];
}

@end
