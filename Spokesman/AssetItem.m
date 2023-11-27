//
//  AssetItem.m
//  Spokesman
//
//  Created by chaitanya venneti on 22/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "AssetItem.h"

@interface AssetItem ()

@end

@implementation AssetItem
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    
    NSImage* img = ((AssetItem*)representedObject).thumbImageContent;;
    if(img != nil)
        _thumbImage.image = img;// valueForKey:@"thumbImage"];
    
}

-(void)setSelected:(BOOL)flag
{    
    _bgbox.borderWidth = 1;
    
    if(flag)
        _bgbox.borderColor = [NSColor orangeColor];
    else
        _bgbox.borderColor = [NSColor lightGrayColor];
}
@end
