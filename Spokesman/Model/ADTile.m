//
//  ADTile.m
//  Spokesman
//
//  Created by chaitanya venneti on 17/05/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "ADTile.h"

@implementation ADTile

-(id) copyWithZone: (NSZone *) zone
{
    ADTile *tCopy = [[ADTile allocWithZone: zone] init];
    
    [tCopy setTileId:self.tileId];
    [tCopy setTileProjectId:self.tileProjectId];
    [tCopy setTileAssetId:self.tileAssetId];
    [tCopy setAssetImagePath:self.assetImagePath];
    [tCopy setAssetImageServerPath:self.assetImageServerPath];
    
    [tCopy setTileHeadingText:self.tileHeadingText];
    [tCopy setTileDescription:self.tileDescription];
    [tCopy setTilePlateColor:self.tilePlateColor];
    [tCopy setTileLink:self.tileLink];
    [tCopy setWebsiteLink:self.websiteLink];
    
    [tCopy setPinterestLink:self.pinterestLink];
    [tCopy setFbLink:self.fbLink];
    [tCopy setTwLink:self.twLink];
    [tCopy setInstaLink:self.instaLink];
    
    [tCopy setIsHeadingBold:self.isHeadingBold];
    [tCopy setIsHeadingItalic:self.isHeadingItalic];
    [tCopy setIsHeadingUnderline:self.isHeadingUnderline];
    [tCopy setTileHeadingAlignment:self.tileHeadingAlignment];
    
    [tCopy setIsDescBold:self.isDescBold];
    [tCopy setIsDescItalic:self.isDescItalic];
    [tCopy setIsDescUnderline:self.isDescUnderline];
    [tCopy setTileDescAlignment:self.tileDescAlignment];
    
    [tCopy setIsTileDefault:self.isTileDefault];
    
    [tCopy setShowTileInSidebox:self.showTileInSidebox];
    
    [tCopy setHeadingColor:self.headingColor];
    [tCopy setDescColor:self.descColor];
    
    [tCopy setTileThumbnailImage:self.tileThumbnailImage];
    
    [tCopy setAssetType:self.assetType];
    [tCopy setAssetImageName:self.assetImageName];
    
    [tCopy setTileTransition:self.tileTransition];
    [tCopy setTileTransitionFrameCount:self.tileTransitionFrameCount];
    
    [tCopy setTileAudioTransition:self.tileAudioTransition];
    
    [tCopy setX_pos:self.x_pos];
    [tCopy setY_pos:self.y_pos];
    [tCopy setHeight:self.height];
    
    [tCopy setUseProfileAsIcon:self.useProfileAsIcon];
    
    [tCopy setIsGeneralCategory:self.isGeneralCategory];
    
    [tCopy setTileCategory:self.tileCategory];
    
    [tCopy setArtistId:self.artistId];
    [tCopy setProductId:self.productId];
    
    [tCopy setNickName:self.nickName];
    [tCopy setLastName:self.lastName];
    [tCopy setFirstName:self.firstName];
    
    [tCopy setTransparency:self.transparency];
    
    return tCopy;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    
    if (self = [super init]) {
        self.tileId = [decoder decodeIntForKey:@"tileId"];
        self.tileProjectId = [decoder decodeIntForKey:@"tileProjectId"];
        self.tileAssetId = [decoder decodeIntForKey:@"tileAssetId"];
        
        self.assetImagePath = [decoder decodeObjectForKey:@"assetImagePath"];
        self.assetImageServerPath = [decoder decodeObjectForKey:@"assetImageServerPath"];
        
        self.tileHeadingText = [decoder decodeObjectForKey:@"tileHeadingText"];;
        self.tileDescription = [decoder decodeObjectForKey:@"tileDescription"];
        self.tilePlateColor = [decoder decodeObjectForKey:@"tilePlateColor"];
        
        self.tileLink = [decoder decodeObjectForKey:@"tileLink"];;
        self.websiteLink = [decoder decodeObjectForKey:@"websiteLink"];
        self.pinterestLink = [decoder decodeObjectForKey:@"pinterestLink"];
        self.fbLink = [decoder decodeObjectForKey:@"fbLink"];
        self.twLink = [decoder decodeObjectForKey:@"twLink"];
        self.instaLink = [decoder decodeObjectForKey:@"instaLink"];
        
        self.isHeadingBold = [decoder decodeBoolForKey:@"isHeadingBold"];
        self.isHeadingItalic = [decoder decodeBoolForKey:@"isHeadingItalic"];
        self.isHeadingUnderline = [decoder decodeBoolForKey:@"isHeadingUnderline"];
        self.tileHeadingAlignment = [decoder decodeObjectForKey:@"tileHeadingAlignment"];
        
        
        self.isDescBold = [decoder decodeBoolForKey:@"isDescBold"];
        self.isDescItalic = [decoder decodeBoolForKey:@"isDescItalic"];
        self.isDescUnderline = [decoder decodeBoolForKey:@"isDescUnderline"];
        self.tileDescAlignment = [decoder decodeObjectForKey:@"tileDescAlignment"];
        
        self.isTileDefault = [decoder decodeBoolForKey:@"isTileDefault"];
        
        self.showTileInSidebox = [decoder decodeBoolForKey:@"showTileInSidebox"];
        
        self.headingColor = [decoder decodeObjectForKey:@"headingColor"];
        self.descColor = [decoder decodeObjectForKey:@"descColor"];
        
        self.tileThumbnailImage = [decoder decodeObjectForKey:@"tileThumbnailImage"];
        
        self.assetType = [decoder decodeObjectForKey:@"assetType"];
        self.assetImageName = [decoder decodeObjectForKey:@"assetImageName"];
        
        self.tileTransitionFrameCount = [decoder decodeObjectForKey:@"tileTransitionFrameCount"];
        self.tileTransition = [decoder decodeObjectForKey:@"tileTransition"];
        self.tileAudioTransition = [decoder decodeObjectForKey:@"tileAudioTransition"];
        
        self.artistId = [decoder decodeObjectForKey:@"artistId"];
        self.productId = [decoder decodeObjectForKey:@"productId"];
        
        self.nickName = [decoder decodeObjectForKey:@"nickName"];
        self.firstName = [decoder decodeObjectForKey:@"firstName"];
        self.lastName = [decoder decodeObjectForKey:@"lastName"];
        
        self.x_pos = [decoder decodeFloatForKey:@"x_pos"];
        self.y_pos = [decoder decodeFloatForKey:@"y_pos"];
        self.height = [decoder decodeFloatForKey:@"height"];
        
        self.useProfileAsIcon = [decoder decodeBoolForKey:@"useProfileAsIcon"];
        
        self.isGeneralCategory = [decoder decodeBoolForKey:@"isGeneralCategory"];
        
        self.tileCategory = [decoder decodeObjectForKey:@"tileCategory"];
        
        self.transparency = [decoder decodeFloatForKey:@"transparency"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:self.tileId forKey:@"tileId"];
    [coder encodeInt:self.tileProjectId forKey:@"tileProjectId"];
    [coder encodeInt:self.tileAssetId forKey:@"tileAssetId"];
    
    [coder encodeObject:self.assetImagePath forKey:@"assetImagePath"];
    [coder encodeObject:self.assetImageServerPath forKey:@"assetImageServerPath"];
    
    [coder encodeObject:self.tileHeadingText forKey:@"tileHeadingText"];
    [coder encodeObject:self.tileDescription forKey:@"tileDescription"];
    [coder encodeObject:self.tilePlateColor forKey:@"tilePlateColor"];
    
    [coder encodeObject:self.tileLink forKey:@"tileLink"];
    [coder encodeObject:self.websiteLink forKey:@"websiteLink"];
    [coder encodeObject:self.pinterestLink forKey:@"pinterestLink"];
    [coder encodeObject:self.fbLink forKey:@"fbLink"];
    [coder encodeObject:self.twLink forKey:@"twLink"];
    [coder encodeObject:self.instaLink forKey:@"instaLink"];
    
    [coder encodeBool:self.isHeadingBold forKey:@"isHeadingBold"];
    [coder encodeBool:self.isHeadingItalic forKey:@"isHeadingItalic"];
    [coder encodeBool:self.isHeadingUnderline forKey:@"isHeadingUnderline"];
    [coder encodeObject:self.tileHeadingAlignment forKey:@"tileHeadingAlignment"];
    
    [coder encodeBool:self.isDescBold forKey:@"isDescBold"];
    [coder encodeBool:self.isDescItalic forKey:@"isDescItalic"];
    [coder encodeBool:self.isDescUnderline forKey:@"isDescUnderline"];
    [coder encodeObject:self.tileDescAlignment forKey:@"tileDescAlignment"];
    
    [coder encodeBool:self.isTileDefault forKey:@"isTileDefault"];
    [coder encodeBool:self.useProfileAsIcon forKey:@"useProfileAsIcon"];
    [coder encodeBool:self.showTileInSidebox forKey:@"showTileInSidebox"];
    
    [coder encodeBool:self.isGeneralCategory forKey:@"isGeneralCategory"];
    [coder encodeObject:self.tileCategory forKey:@"tileCategory"];
    
    [coder encodeObject:self.headingColor forKey:@"headingColor"];
    [coder encodeObject:self.descColor forKey:@"descColor"];
    
    [coder encodeObject:self.tileThumbnailImage forKey:@"tileThumbnailImage"];
    
    [coder encodeObject:self.assetType forKey:@"assetType"];
    [coder encodeObject:self.assetImageName forKey:@"assetImageName"];
    
    [coder encodeObject:self.tileTransitionFrameCount forKey:@"tileTransitionFrameCount"];
    [coder encodeObject:self.tileTransition forKey:@"tileTransition"];
    [coder encodeObject:self.tileAudioTransition forKey:@"tileAudioTransition"];
    
    [coder encodeObject:self.productId forKey:@"productId"];
    [coder encodeObject:self.artistId forKey:@"artistId"];
    [coder encodeObject:self.nickName forKey:@"nickName"];
    [coder encodeObject:self.lastName forKey:@"lastName"];
    [coder encodeObject:self.firstName forKey:@"firstName"];
    
    [coder encodeFloat:self.x_pos forKey:@"x_pos"];
    [coder encodeFloat:self.y_pos forKey:@"y_pos"];
    [coder encodeFloat:self.height forKey:@"height"];
    [coder encodeFloat:self.transparency forKey:@"transparency"];

}
@end
