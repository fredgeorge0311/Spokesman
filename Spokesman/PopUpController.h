//
//  PopUpController.h
//  Spokesman
//
//  Created by Admin on 23.07.2020.
//  Copyright © 2020 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ImportVideoDelegate <NSObject>
-(void)importYoutubeVideo: (NSString*) youtubeUrl;
-(void)openFileDialog;
@end

@interface PopUpController : NSViewController
    @property (nonatomic,weak) id<ImportVideoDelegate> importVideoDelegate;
@end
NS_ASSUME_NONNULL_END
