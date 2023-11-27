//
//  NonRespondingAVPlayerView.m
//  Spokesman
//
//  Created by Chaitanya VRK on 28/02/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "NonRespondingAVPlayerView.h"

@implementation NonRespondingAVPlayerView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)scrollWheel:(NSEvent *)event{
    //do nothing
}

- (BOOL)acceptsFirstResponder {
    return NO;
}

@end
