//
//  LibraryItem.h
//  Spokesman
//
//  Created by chaitanya venneti on 18/05/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LibraryItem : NSCollectionViewItem

@property (strong) IBOutlet NSImage *thumbImage;
@property (strong) IBOutlet NSString *heading;
@property (strong) IBOutlet NSString *desc;
@property (strong) IBOutlet NSColor *plateColor;

@property (strong, nonatomic) IBOutlet NSImageView *thumbImageView;
@property (strong, nonatomic) IBOutlet NSTextField *txtHeading;
@property (strong, nonatomic) IBOutlet NSTextField *txtDesc;
@property (weak) IBOutlet NSBox *itemContainerView;

@end
