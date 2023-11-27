//
//  RSVerticallyCenteredSecureTextFieldCell.m
//  RSCommon
//
//  Created by Daniel Jalkut on 6/17/06.
//  Copyright 2006 Red Sweater Software. All rights reserved.
//

#import "RSVerticallyCenteredSecureTextFieldCell.h"

@implementation RSVerticallyCenteredSecureTextFieldCell

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
	// Get the parent's idea of where we should draw
	NSRect newRect = [super drawingRectForBounds:theRect];

	// When the text field is being 
	// edited or selected, we have to turn off the magic because it screws up 
	// the configuration of the field editor.  We sneak around this by 
	// intercepting selectWithFrame and editWithFrame and sneaking a 
	// reduced, centered rect in at the last minute.
	if(mIsEditingOrSelecting == NO)
	{
		// Get our ideal size for current text
		NSSize textSize = [self cellSizeForBounds:theRect];

		// Center that in the proposed rect
		float heightDelta = newRect.size.height - textSize.height;	
		if (heightDelta > 0)
		{
			newRect.size.height -= heightDelta;
			newRect.origin.y += (heightDelta / 2);
		}
        newRect.origin.x += 10;
	}
	
	return newRect;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(long)selStart length:(long)selLength
{
	aRect = [self drawingRectForBounds:aRect];
	mIsEditingOrSelecting = YES;	
	[super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
	mIsEditingOrSelecting = NO;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{	
	aRect = [self drawingRectForBounds:aRect];
	mIsEditingOrSelecting = YES;
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
	mIsEditingOrSelecting = NO;
}

-(void)drawInteriorWithFrame:(NSRect)aRect inView:(NSView *)controlView
{
    NSColor *color = [self colorWithHexColorString:@"3e3e3e"];

    //[[NSColor darkGrayColor] set];
    //NSRectFill(aRect);
    NSRect    rectList[256];  // long enough for a color table
    NSColor   *colorList[256];
    
    rectList[0] = aRect;
    colorList[0] = color;
    
    NSRectFillListWithColors(rectList, colorList, 1);
    
    aRect = [self drawingRectForBounds:aRect];
    mIsEditingOrSelecting = YES;
    [super drawInteriorWithFrame:aRect inView:controlView];
    mIsEditingOrSelecting = NO;
}

-(NSColor*)colorWithHexColorString:(NSString*)inColorString
{
    NSColor* result = nil;
    unsigned colorCode = 0;
    unsigned char redByte, greenByte, blueByte;
    
    if (nil != inColorString)
    {
        NSScanner* scanner = [NSScanner scannerWithString:inColorString];
        (void) [scanner scanHexInt:&colorCode]; // ignore error
    }
    redByte = (unsigned char)(colorCode >> 16);
    greenByte = (unsigned char)(colorCode >> 8);
    blueByte = (unsigned char)(colorCode); // masks off high bits
    
    result = [NSColor
              colorWithCalibratedRed:(CGFloat)redByte / 0xff
              green:(CGFloat)greenByte / 0xff
              blue:(CGFloat)blueByte / 0xff
              alpha:1.0];
    return result;
}

@end
