//
//  TimelineCollectionViewItem.m
//  Spokesman
//
//  Created by chaitanya venneti on 05/03/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "TimelineCollectionViewItem.h"

@interface TimelineCollectionViewItem ()

@end

@implementation TimelineCollectionViewItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    
    NSString* texttoshow = ((TimelineCollectionViewItem*)representedObject).frameText;
    
    if(texttoshow != nil && texttoshow.length > 0)
        [_frameTime setStringValue:texttoshow];
                   //valueForKey:@"frameTime"]];
    
    NSImage* img = ((TimelineCollectionViewItem*)representedObject).thumbImageContent;;
    if(img != nil)
        _thumbImage.image = img;// valueForKey:@"thumbImage"];

}

-(void)setSelected:(BOOL)flag
{
    _bgbox.hidden = !flag;
}

@end
