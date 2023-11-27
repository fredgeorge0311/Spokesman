//
//  AnimationSliderViewController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 13/03/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AnimationSliderViewController : NSView
@property (strong) IBOutlet NSView *SliderMainView;
@property (weak) IBOutlet NSSlider *Slider;
@property (weak) IBOutlet NSSliderCell *SliderCell;

@property (weak) NSMutableArray* tickImages;

-(void)setNumberOfTicks:(int)count;

-(void)addHighlightAtTick:(int)index;
-(void)removeHighlightAtTick:(int) index;


@end
