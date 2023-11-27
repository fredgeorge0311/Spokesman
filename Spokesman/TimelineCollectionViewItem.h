//
//  TimelineCollectionViewItem.h
//  Spokesman
//
//  Created by chaitanya venneti on 05/03/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TimelineCollectionViewItem : NSCollectionViewItem
@property (weak) IBOutlet NSImageView *thumbImage;
@property (weak) IBOutlet NSImage *thumbImageContent;
@property (weak) IBOutlet NSTextField *frameTime;
@property (weak) IBOutlet NSString *frameText;
@property (weak) IBOutlet NSBox *bgbox;

@end
