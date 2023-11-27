//
//  EDL.h
//  Spokesman
//
//  Created by chaitanya venneti on 11/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADTile.h"
#import "Frame.h"
@import CoreMedia;

@interface EDL : NSObject<NSCoding>

@property NSString* editNumber;
@property NSString* reelName;
@property NSString* channel;
@property NSString* operation;

@property NSString* sourceIn;
@property NSString* sourceOut;
@property NSString* destIn;
@property NSString* destOut;

@property CMTime time;

//@property ADTile* tile;
@property NSMutableArray* tiles;

@property NSMutableArray* frames;

@end
