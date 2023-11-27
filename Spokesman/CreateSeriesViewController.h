//
//  CreateSeriesViewController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 18/06/19.
//  Copyright © 2019 troomobile. All rights reserved.
//

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CreateSeriesViewController : NSViewController<NSTableViewDelegate, NSTableViewDataSource>
@property (strong) IBOutlet NSTextField *txtSeriesName;
@property (strong) IBOutlet NSTextField *txtDirector;
@property (strong) IBOutlet NSTextField *txtProducer;
@property (strong) IBOutlet NSTextField *txtSeriesDescription;
@property (strong) IBOutlet NSTextField *txtGenre;
@property (strong) IBOutlet NSTextField *txtCast;

@property (strong) IBOutlet NSButton *btnCreateSeries;
- (IBAction)btnCreateSeriesClicked:(id)sender;
@property (strong) IBOutlet NSButton *btnCloseDialog;
- (IBAction)btnCloseDialogClicked:(id)sender;
@property (strong) IBOutlet NSButton *btnEditSeries;
@property (strong) IBOutlet NSTableView *seriesTableView;
@property (strong) IBOutlet NSProgressIndicator *loading;
@property (strong) IBOutlet NSButton *chkIsFeatured;
@property (strong) IBOutlet NSButton *btnCreateNewSeries;
- (IBAction)resetFieldsForNewSeries:(id)sender;
@property (strong) IBOutlet NSButton *btnDeleteSeries;
- (IBAction)btnDeleteSetiesClicked:(id)sender;

@property (strong) IBOutlet NSImageView *imgSeriesThumbnail;
@property (strong) IBOutlet NSImageView *imgSeriesIcon;
@property (strong) IBOutlet NSImageView *imgSeriesBackground;
@end

NS_ASSUME_NONNULL_END
