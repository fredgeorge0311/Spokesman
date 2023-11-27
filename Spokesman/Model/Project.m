//
//  Project.m
//  Spokesman
//
//  Created by chaitanya venneti on 04/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "Project.h"

@implementation Project

-(id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.projectId = [decoder decodeIntForKey:@"projectId"];
        
        self.projectName = [decoder decodeObjectForKey:@"projectName"];
        self.assets = [decoder decodeObjectForKey:@"assets"];
        self.people = [decoder decodeObjectForKey:@"people"];
        self.products = [decoder decodeObjectForKey:@"products"];
        self.transitions = [decoder decodeObjectForKey:@"transitions"];
        //self.audiotransitions = [decoder decodeObjectForKey:@"audiotransitions"];
        self.sounds = [decoder decodeObjectForKey:@"sounds"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:self.projectId forKey:@"projectId"];
    
    [coder encodeObject:self.projectName forKey:@"projectName"];
    [coder encodeObject:self.assets forKey:@"assets"];
    [coder encodeObject:self.people forKey:@"people"];
    [coder encodeObject:self.products forKey:@"products"];
    [coder encodeObject:self.transitions forKey:@"transitions"];
    //[coder encodeObject:self.audiotransitions forKey:@"audiotransitions"];
    [coder encodeObject:self.sounds forKey:@"sounds"];
}

@end
