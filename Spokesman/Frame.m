//
//  Frame.m
//  Spokesman
//
//  Created by Chaitanya VRK on 15/03/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "Frame.h"

@implementation Frame

-(instancetype)init
{
    if (self = [super init]) {
        self.columns = [NSMutableArray array];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.columns = [decoder decodeObjectForKey:@"columns"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.columns forKey:@"columns"];
}

@end
