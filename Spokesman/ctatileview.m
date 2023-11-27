//
//  ctatileview.m
//  Spokesman
//
//  Created by Chaitanya VRK on 29/09/19.
//  Copyright © 2019 troomobile. All rights reserved.
//

#import "ctatileview.h"

@implementation ctatileview

@synthesize tag;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (id)init {
    self = [super init];
    if (self) {
        [self commonConfiguration];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonConfiguration];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonConfiguration];
    }
    return self;
}

- (void)commonConfiguration {
    [self setWantsLayer:YES];
}
@end
