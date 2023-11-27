//
//  AnimationSliderViewController.m
//  Spokesman
//
//  Created by Chaitanya VRK on 13/03/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "AnimationSliderViewController.h"

@interface AnimationSliderViewController ()

@end

@implementation AnimationSliderViewController


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self customInit:CGRectZero];
    }
    return self;
}

-(instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if(self)
    {
        [self customInit:frameRect];
    }
    return self;
}

-(void)customInit:(NSRect)frameRect
{
    [[NSBundle mainBundle] loadNibNamed:@"AnimationSliderViewController" owner:self topLevelObjects:nil];
    [self addSubview:self.SliderMainView];
    self.SliderMainView.bounds = self.bounds;
    _tickImages = [NSMutableArray array];
    if(!CGRectEqualToRect(frameRect, CGRectZero)){
        NSRect sliderViewFrame = self.SliderMainView.frame;
        sliderViewFrame.size.width = frameRect.size.width;
        self.SliderMainView.frame = sliderViewFrame;
        
        NSRect sliderFrame = self.Slider.frame;
        sliderFrame.size.width = frameRect.size.width;
        self.Slider.frame = sliderFrame;
    }
}
/*
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    _tickImages = [NSMutableArray array];
}*/

-(void)addHighlightAtTick:(int)index
{
    if(index < _Slider.numberOfTickMarks)
    {
        NSRect tickRect = [_Slider rectOfTickMarkAtIndex:index];
        
        NSImageView* _img = _tickImages[index];
        _img.hidden = true;
        if(_img != nil)
        {
            _img.image = [NSImage imageNamed:@"login-bg-small"];
        }
        else
        {
            //..
        }
    }
    
}

-(void)removeHighlightAtTick:(int)index
{
    NSImageView* _img = _tickImages[index];
    if(_img != nil){
        _img.image = [NSImage imageNamed:@"main-bg"];
    }
}

-(void)setNumberOfTicks:(int)count
{
    _Slider.numberOfTickMarks = count;
    _tickImages = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        NSRect tickRect = [_Slider rectOfTickMarkAtIndex:i];
        NSRect imgRect = tickRect;
        imgRect.size.width = 5;
        imgRect.size.height = 5;
        imgRect.origin.y += 15;
        imgRect.origin.x -= 3;
        NSImageView* _img = [[NSImageView alloc] initWithFrame:imgRect];
        _img.image = [NSImage imageNamed:@"main-bg"];
        _img.imageScaling = NSImageScaleAxesIndependently;
        [_SliderMainView addSubview:_img];
        
        [_tickImages insertObject:_img atIndex:i];
    }
}

@end
