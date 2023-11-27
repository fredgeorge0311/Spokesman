//
//  ADTile.h
//  Spokesman
//
//  Created by chaitanya venneti on 17/05/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AppKit;

@interface ADTile : NSObject <NSCopying, NSCoding>


@property int tileId;
@property int tileProjectId;
@property int tileAssetId;
@property (nonatomic, strong) NSString *productId;
@property (nonatomic, strong) NSString *artistId;
@property (nonatomic, strong) NSString *assetImagePath;
@property (nonatomic, strong) NSString *assetImageServerPath;

@property (nonatomic, strong) NSString *tileThumbnailName;
@property (nonatomic, strong) NSImage *tileThumbnailImage;

@property (nonatomic, strong) NSString *assetType;
@property (nonatomic, strong) NSString *assetImageName;

@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;

@property (nonatomic, strong) NSString *tileHeadingText;
@property (nonatomic, strong) NSString *tileDescription;
@property (nonatomic) NSColor *tilePlateColor;
@property (nonatomic, strong) NSString *tileLink;

@property (nonatomic, strong) NSString *fbLink;
@property (nonatomic, strong) NSString *twLink;
@property (nonatomic, strong) NSString *websiteLink;
@property (nonatomic, strong) NSString *instaLink;
@property (nonatomic, strong) NSString *pinterestLink;

@property (nonatomic) BOOL isHeadingBold;
@property (nonatomic) BOOL isHeadingItalic;
@property (nonatomic) BOOL isHeadingUnderline;
@property (nonatomic) NSString* tileHeadingAlignment;

@property (nonatomic) BOOL isDescBold;
@property (nonatomic) BOOL isDescItalic;
@property (nonatomic) BOOL isDescUnderline;
@property (nonatomic) NSString* tileDescAlignment;

@property (nonatomic) BOOL isTileDefault;
@property (nonatomic) BOOL showTileInSidebox;
@property (nonatomic) BOOL useProfileAsIcon;
@property (nonatomic) BOOL isGeneralCategory;
@property (nonatomic) NSString* tileCategory;

@property (nonatomic) NSColor *headingColor;
@property (nonatomic) NSColor *descColor;

@property (nonatomic, strong) NSString *tileTransition;
@property (nonatomic, strong) NSString *tileTransitionFrameCount;
@property (nonatomic, strong) NSString *tileAudioTransition;

@property (nonatomic) CGFloat transparency;

@property (nonatomic) CGFloat x_pos;
@property (nonatomic) CGFloat y_pos;
@property (nonatomic) CGFloat height;

-(id) copyWithZone: (NSZone *) zone;

@end
