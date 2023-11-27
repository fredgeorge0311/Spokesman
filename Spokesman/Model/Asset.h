//
//  Asset.h
//  Spokesman
//
//  Created by chaitanya venneti on 04/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Asset : NSObject<NSCoding>

@property int assetId;
@property (nonatomic, strong) NSString* assetIdentifier;
@property (nonatomic, strong) NSString *assetName;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *assetFilePath;
@property (nonatomic, strong) NSData *assetBookmark;
@property (nonatomic, strong) NSString *assetType;
@property int assetProjectId;
@property (nonatomic, strong) NSImage *assetImage;

@property (nonatomic, strong) NSString *assetDisplayName;
@property (nonatomic, strong) NSString *assetProfileDescription;

@property (nonatomic, strong) NSString *assetFacebookLink;
@property (nonatomic, strong) NSString *assetTwitterLink;
@property (nonatomic, strong) NSString *assetPinterestLink;
@property (nonatomic, strong) NSString *assetInstagraamLink;
@property (nonatomic, strong) NSString *assetWebsiteLink;


//Product
@property BOOL general_category;
@property (nonatomic, strong) NSString *brandName;
@property (nonatomic, strong) NSString *link1;
@property (nonatomic, strong) NSString *link2;
@property (nonatomic, strong) NSString *link3;
@property (nonatomic, strong) NSString *link4;
@property (nonatomic, strong) NSString *link5;

@end
