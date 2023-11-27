//
//  TileAnimationProperties.m
//  Spokesman
//
//  Created by Chaitanya VRK on 15/03/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "TileAnimationProperties.h"

@implementation TileAnimationProperties

-(id) copyWithZone: (NSZone *) zone
{
    TileAnimationProperties *tCopy = [[TileAnimationProperties allocWithZone: zone] init];
    
    [tCopy setHidden:self.hidden];
    [tCopy setX:self.x];
    [tCopy setY:self.y];
    [tCopy setX_percent:self.x_percent];
    [tCopy setY_percent:self.y_percent];
    
    [tCopy setOpacity:self.opacity];
    [tCopy setScale:self.scale];

    return tCopy;
}

-(instancetype)init
{
    if (self = [super init]) {
        self.opacity = 1;
        self.scale = 1;
        self.hidden = false;
        self.x = -1;
        self.y = -1;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.x = [decoder decodeFloatForKey:@"x"];
        self.y = [decoder decodeFloatForKey:@"y"];
        self.x_percent = [decoder decodeFloatForKey:@"x_percent"];
        self.y_percent = [decoder decodeFloatForKey:@"y_percent"];
        self.scale = [decoder decodeFloatForKey:@"scale"];
        self.opacity = [decoder decodeFloatForKey:@"opacity"];
        self.hidden = [decoder decodeBoolForKey:@"hidden"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeFloat:self.x forKey:@"x"];
    [coder encodeFloat:self.y forKey:@"y"];
    [coder encodeFloat:self.x_percent forKey:@"x_percent"];
    [coder encodeFloat:self.y_percent forKey:@"y_percent"];
    [coder encodeFloat:self.scale forKey:@"scale"];
    [coder encodeFloat:self.opacity forKey:@"opacity"];
    [coder encodeBool:self.hidden forKey:@"hidden"];
}

@end
