//
//  LibraryItem.m
//  Spokesman
//
//  Created by chaitanya venneti on 18/05/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "LibraryItem.h"

@interface LibraryItem ()

@end

@implementation LibraryItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    
    NSImage* img = ((LibraryItem*)representedObject).thumbImage;
    if(img != nil)
        _thumbImageView.image = img;// valueForKey:@"thumbImage"];
    
    if(((LibraryItem*)representedObject).heading != nil)
        _txtHeading.stringValue = ((LibraryItem*)representedObject).heading;
    
    if(((LibraryItem*)representedObject).desc != nil)
        _txtDesc.stringValue = ((LibraryItem*)representedObject).desc;
    
    _itemContainerView.layer.backgroundColor = (__bridge CGColorRef _Nullable)(((LibraryItem*)representedObject).plateColor);
    self.view.layer.backgroundColor = (__bridge CGColorRef _Nullable)(((LibraryItem*)representedObject).plateColor);
}

-(void)setSelected:(BOOL)flag
{
    _itemContainerView.borderWidth = 1;
    
    if(flag)
        _itemContainerView.borderColor = [NSColor orangeColor];
    else
        _itemContainerView.borderColor = [NSColor lightGrayColor];
}

@end
