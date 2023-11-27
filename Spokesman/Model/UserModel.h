//
//  UserModel.h
//  Spokesman
//
//  Created by chaitanya venneti on 14/03/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserModel : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *lastLogin;
@property (nonatomic, strong) NSString *accessTokenRefreshTime;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *profilePicture;
@property (nonatomic, strong) NSString *userType;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSMutableArray  *musicPrefList;
@property (nonatomic, strong) NSMutableArray  *followingUserIdList;

@end
