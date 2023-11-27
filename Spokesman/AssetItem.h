//
//  AssetItem.h
//  Spokesman
//
//  Created by chaitanya venneti on 22/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Asset.h"

@interface AssetItem : NSCollectionViewItem
@property (weak) IBOutlet NSImageView *thumbImage;
@property (strong) IBOutlet NSImage *thumbImageContent;
@property (weak) IBOutlet NSTextField *frameTime;
@property (weak) IBOutlet NSString *frameText;
@property (weak) IBOutlet NSBox *bgbox;
@property Asset* assetForItem;
@end
