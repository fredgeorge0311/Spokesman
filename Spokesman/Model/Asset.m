//
//  Asset.m
//  Spokesman
//
//  Created by chaitanya venneti on 04/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "Asset.h"

@implementation Asset

-(id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.assetId = [decoder decodeIntForKey:@"assetId"];
        
        self.assetIdentifier = [decoder decodeObjectForKey:@"assetIdentifier"];
        self.assetName = [decoder decodeObjectForKey:@"assetName"];
        self.nickName = [decoder decodeObjectForKey:@"nickName"];
        self.firstName = [decoder decodeObjectForKey:@"firstName"];
        self.lastName = [decoder decodeObjectForKey:@"lastName"];
        self.assetFilePath = [decoder decodeObjectForKey:@"assetFilePath"];
        self.assetBookmark = [decoder decodeObjectForKey:@"assetBookmark"];
        self.assetType = [decoder decodeObjectForKey:@"assetType"];
        self.assetImage = [decoder decodeObjectForKey:@"assetImage"];;
        self.assetDisplayName = [decoder decodeObjectForKey:@"assetDisplayName"];
        self.assetProfileDescription = [decoder decodeObjectForKey:@"assetProfileDescription"];
        
        self.assetProjectId = [decoder decodeIntForKey:@"assetProjectId"];
        
        self.assetFacebookLink = [decoder decodeObjectForKey:@"assetFacebookLink"];
        self.assetTwitterLink = [decoder decodeObjectForKey:@"assetTwitterLink"];
        self.assetPinterestLink = [decoder decodeObjectForKey:@"assetPinterestLink"];
        self.assetInstagraamLink = [decoder decodeObjectForKey:@"assetInstagraamLink"];
        self.assetWebsiteLink = [decoder decodeObjectForKey:@"assetWebsiteLink"];;
        self.brandName = [decoder decodeObjectForKey:@"brandName"];
        self.general_category = [decoder decodeBoolForKey:@"general_category"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:self.assetId forKey:@"assetId"];
    
    [coder encodeObject:self.assetIdentifier forKey:@"assetIdentifier"];
    [coder encodeObject:self.assetName forKey:@"assetName"];
    [coder encodeObject:self.nickName forKey:@"nickName"];
    [coder encodeObject:self.firstName forKey:@"firstName"];
    [coder encodeObject:self.lastName forKey:@"lastName"];
    [coder encodeObject:self.assetFilePath forKey:@"assetFilePath"];
    [coder encodeObject:self.assetBookmark forKey:@"assetBookmark"];
    [coder encodeObject:self.assetType forKey:@"assetType"];
    [coder encodeObject:self.assetImage forKey:@"assetImage"];
    [coder encodeObject:self.assetDisplayName forKey:@"assetDisplayName"];
    [coder encodeObject:self.assetProfileDescription forKey:@"assetProfileDescription"];
    
    [coder encodeInt:self.assetProjectId forKey:@"assetProjectId"];
    
    [coder encodeObject:self.assetFacebookLink forKey:@"assetFacebookLink"];
    [coder encodeObject:self.assetTwitterLink forKey:@"assetTwitterLink"];
    [coder encodeObject:self.assetPinterestLink forKey:@"assetPinterestLink"];
    [coder encodeObject:self.assetInstagraamLink forKey:@"assetInstagraamLink"];
    [coder encodeObject:self.assetWebsiteLink forKey:@"assetWebsiteLink"];
    [coder encodeObject:self.brandName forKey:@"brandName"];
    [coder encodeBool:self.general_category forKey:@"general_category"];
}


@end
