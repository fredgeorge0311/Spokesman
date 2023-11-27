//
//  AAPLMovieTimeline.h
//  Spokesman
//
//  Created by chaitanya venneti on 26/02/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AAPLMovieTimeline;

@protocol AAPLMovieTimelineUpdateDelgate <NSObject>

- (void)movieTimeline:(AAPLMovieTimeline *)timeline didUpdateCursorToPoint:(NSPoint)toPoint;
- (void)didSelectTimelineRangeFromPoint:(NSPoint)fromPoint toPoint:(NSPoint)toPoint;
- (void)didSelectTimelinePoint:(NSPoint)point;

@end

@interface AAPLMovieTimeline : NSView

@property id<AAPLMovieTimelineUpdateDelgate> delegate;

- (void)removeAllPositionalSubviews;
- (NSUInteger)countOfImagesRequiredToFillView;
- (void)addImageView:(NSImage *)image;
- (void)updateTimeLabel:(NSString *)newLabel;

@end
