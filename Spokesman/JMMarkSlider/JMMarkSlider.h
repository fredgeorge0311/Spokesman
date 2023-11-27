//
//  JMMarkSlider.h
//  Spokesman
//
//  Created by Chaitanya VRK on 19/12/17.
//  Copyright © 2017 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JMMarkSlider : NSSlider
@property (nonatomic) NSColor *markColor;
@property (nonatomic) CGFloat markWidth;
@property (nonatomic) NSArray *markPositions;
@property (nonatomic) NSColor *selectedBarColor;
@property (nonatomic) NSColor *unselectedBarColor;
@property (nonatomic) NSColor *handlerImage;
@property (nonatomic) NSColor *handlerColor;
@end
