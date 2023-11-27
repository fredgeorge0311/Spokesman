//
//  CustomTextFieldCell.m
//  Spokesman
//
//  Created by chaitanya venneti on 24/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "CustomTextFieldCell.h"

@implementation CustomTextFieldCell

//Function will create rect for title

//Any padding implemented in this function will be visible in title of textfieldcell

- (NSRect)titleRectForBounds:(NSRect)theRect
{
    NSRect titleFrame = [super titleRectForBounds:theRect];
    //Padding on left side
    titleFrame.origin.x = 10;
    return titleFrame;
}


- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    NSRect textFrame = aRect;
    textFrame.origin.x += 10;
    [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
    NSRect textFrame = aRect;
    textFrame.origin.x += 10;
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}



- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}

@end
