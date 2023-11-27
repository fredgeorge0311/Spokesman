//
//  ItemSelectionCellView.h
//  Spokesman
//
//  Created by chaitanya venneti on 08/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Asset.h"

@interface ItemSelectionCellView : NSTableCellView

@property (weak) IBOutlet NSButton *ListItem;
@property BOOL isSelected;
@property (weak) Asset* AssetForItem;

@end
