//
//  EDL.m
//  Spokesman
//
//  Created by chaitanya venneti on 11/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "EDL.h"
@import AVFoundation;

@implementation EDL

-(id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.editNumber = [decoder decodeObjectForKey:@"editNumber"];
        self.reelName = [decoder decodeObjectForKey:@"reelName"];
        self.channel = [decoder decodeObjectForKey:@"channel"];
        self.operation = [decoder decodeObjectForKey:@"operation"];
        self.sourceIn = [decoder decodeObjectForKey:@"sourceIn"];
        self.sourceOut = [decoder decodeObjectForKey:@"sourceOut"];;
        self.destIn = [decoder decodeObjectForKey:@"destIn"];
        self.destOut = [decoder decodeObjectForKey:@"destOut"];
        
        self.time = [decoder decodeCMTimeForKey:@"time"];

        //@property ADTile* tile;
        self.tiles = [decoder decodeObjectForKey:@"tiles"];
        self.frames = [decoder decodeObjectForKey:@"frames"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.editNumber forKey:@"editNumber"];
    [coder encodeObject:self.reelName forKey:@"reelName"];
    [coder encodeObject:self.channel forKey:@"channel"];
    [coder encodeObject:self.operation forKey:@"operation"];
    [coder encodeObject:self.sourceIn forKey:@"sourceIn"];
    [coder encodeObject:self.sourceOut forKey:@"sourceOut"];
    [coder encodeObject:self.destIn forKey:@"destIn"];
    [coder encodeObject:self.destOut forKey:@"destOut"];
    
    [coder encodeCMTime:self.time forKey:@"time"];
    
    [coder encodeObject:self.tiles forKey:@"tiles"];
    [coder encodeObject:self.frames forKey:@"frames"];
}
@end
