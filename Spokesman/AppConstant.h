//
//  AppConstant.h
//  Spokesman
//
//  Created by chaitanya venneti on 23/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppConstant : NSObject

#define Rgb2UIColor(r, g, b) [CIColor colorWithRed:((r)/255.0) green:((g)/255.0) blue:((b)/255.0) alpha:1.0]
//#define BASE_URL @"http://ec2-54-200-27-200.us-west-2.compute.amazonaws.com:8080/bon2/services/"
#define BASE_URL @"http://bon2.co/bon/services/"
//#define BASE_URL @"http://35.174.66.223/bon/services/"
#define LOGIN_USER @"loginUser"
#define ADD_USER_MEDIA @"addUserMedia"
#define GET_USER_MEDIA @"getUserMedia"
#define CREATE_ARTIST @"createArtist"
#define DELETE_ARTIST @"deleteArtist"
#define GET_ARTIST_DETAILS @"getArtistDetails"
#define UPDATE_ARTIST @"updateArtist"
#define SEARCH_ARTIST @"searchArtist"
#define REGISTER_USER @"registerUser"
#define FIND_USERS @"getRequestUserAdmin"

#define CREATE_PRODUCT @"createProduct"
#define DELETE_PRODUCT @"deleteProduct"
#define UPDATE_PRODUCT @"updateProduct"
#define SEARCH_PRODUCT @"searchProduct"

#define AWS_ACCESS_KEY @"AKIAZGESEUDHZDLTPV7J"
#define AWS_SECRET_KEY @"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"

@end
