//
//  TileAnimationProperties.h
//  Spokesman
//
//  Created by Chaitanya VRK on 15/03/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TileAnimationProperties : NSObject<NSCopying>

@property BOOL hidden;
@property float x;
@property float y;
@property float x_percent;
@property float y_percent;
@property float opacity;
@property float scale;

@end
