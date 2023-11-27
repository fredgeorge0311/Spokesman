//
//  ctatileview.h
//  Spokesman
//
//  Created by Chaitanya VRK on 29/09/19.
//  Copyright © 2019 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSView+INSNibLoading.h"

NS_ASSUME_NONNULL_BEGIN

@interface ctatileview : INSNibLoadedView

@property (strong) IBOutlet NSTextView *ctaTileText;
@property (strong) IBOutlet NSBox *ctaTileBox;
@property NSInteger tag;
@end

NS_ASSUME_NONNULL_END
