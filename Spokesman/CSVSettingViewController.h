//
//  CSVSettingViewController.h
//  Spokesman
//
//  Created by Admin on 04.08.2020.
//  Copyright © 2020 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CSVSettingDelegate <NSObject>
-(void)onSave: (NSString*) savePath forThreshold:(double) threshold;
@end

@interface CSVSettingViewController : NSViewController
@property (weak) IBOutlet NSTextField *textPath;
@property (weak) IBOutlet NSTextField *textCurrentThreshold;
@property (weak) IBOutlet NSStepper *thresholdStepper;
- (IBAction)onOkBtnClicked:(id)sender;
- (IBAction)onCancelBtnClicked:(id)sender;

@property (nonatomic,weak) id<CSVSettingDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
