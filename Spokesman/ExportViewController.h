//
//  ExportViewController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 20/09/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import AVFoundation;
@import AVKit;

#import "AAPLMovieMutator.h"
#import "AAPLMovieTimeline.h"
#import "TimelineCollectionViewItem.h"

#import "AWSCore/AWSCore.h"
#import "AWSS3/AWSS3.h"
#import "AppConstant.h"
#import "AFNetworking.h"
//@import AFNetworking;
#import "Project.h"
#import "Asset.h"
#import "EDL.h"
#import "AssetItem.h"
#import "ADTile.h"
#import "LibraryItem.h"

#import "ProjectsCellView.h"
#import "ItemSelectionCellView.h"
#import "NSColor+Hex.h"
#import "GenrePopoverViewController.h"

@protocol AAPLMovieViewControllerDelegateExp

- (void)movieViewController:(NSUInteger)numberOfImages edlArray:(NSArray<NSValue *> *)edlArray completionHandler:(ImageGenerationCompletionHandler)completionHandler;
- (CMTime)timeAtPercentage:(float)percentage;
- (BOOL)cutMovieTimeRange:(CMTimeRange)timeRange error:(NSError *)error;
- (BOOL)copyMovieTimeRange:(CMTimeRange)timeRange error:(NSError *)error;
- (BOOL)pasteMovieAtTime:(CMTime)time error:(NSError *)error;

@end

@interface ExportViewController : NSViewController<NSCollectionViewDataSource, NSCollectionViewDelegate>


@property (strong) NSPopover *myPopover;
@property (strong) /*ExportViewController*/GenrePopoverViewController *popoverViewController;

@property (weak) IBOutlet NSVisualEffectView *progressView;
@property (weak) IBOutlet NSProgressIndicator *uploadProgressIndicator;
@property (weak) IBOutlet NSTextField *uploadStatusText;

@property NSString* username;
@property NSString* projectName;
@property AAPLMovieMutator *movieMutator;
@property NSMutableArray* images;
@property NSMutableArray* timeFrames;
@property NSMutableArray* actualTimes;

@property NSMutableArray* mvidFiles;

@property double playDuration;

@property double playerWidth;
@property double playerHeight;

@property double originalVideoWidth;
@property double originalVideoHeight;

@property NSURL* currentAssetFileUrl;
@property NSImage* selectedThumbnail;
@property (weak) IBOutlet NSScrollView *exportDialog;
@property (weak) IBOutlet NSScroller *expDialogVScroll;

@property (strong) NSMutableDictionary* exportedProject;

@property (weak) IBOutlet NSTextField *txtExportTitle;
@property (weak) IBOutlet NSTextField *txtExportArtist;
@property (weak) IBOutlet AVPlayerView *playerExport;

@property (weak) IBOutlet NSTextField *txtDescription;
@property (weak) IBOutlet NSTextField *txtTags;
@property (weak) IBOutlet NSButton *chkSkit;
@property (weak) IBOutlet NSButton *chkFeatured;
@property (weak) IBOutlet NSTextField *txtStations;

@property (weak) IBOutlet NSButton *btnPost;
- (IBAction)btnPostClick:(id)sender;

@property (weak) IBOutlet NSButton *btnCancel;
- (IBAction)btnCancelExportClick:(id)sender;

@property (weak) IBOutlet NSButton *chkPrivate;
@property (weak) IBOutlet NSButton *chkFollowers;
@property (weak) IBOutlet NSButton *chkPublic;
- (IBAction)chkPublicClick:(id)sender;
- (IBAction)chkFollowersClick:(id)sender;
- (IBAction)chkPrivateClick:(id)sender;

@property (weak) IBOutlet NSScrollView *exportThumbsScrollView;
@property (weak) IBOutlet NSCollectionView *exportThumbsView;

@property NSMutableArray *EDLs;
@property (strong) IBOutlet NSButton *chkPublish;
@property (strong) IBOutlet NSDatePicker *publishStartTime;
@property (strong) IBOutlet NSDatePicker *publishEndTime;

@property (strong) IBOutlet NSPopUpButton *videoRating;

//station checkbox
@property (strong) IBOutlet NSButton *stationBon2Tv;
@property (strong) IBOutlet NSButton *stationComedy;
@property (strong) IBOutlet NSButton *stationCooking;
@property (strong) IBOutlet NSButton *stationDIY;
@property (strong) IBOutlet NSButton *stationDance;
@property (strong) IBOutlet NSButton *stationFamily;
@property (strong) IBOutlet NSButton *stationFashion;
@property (strong) IBOutlet NSButton *stationHealthBeauty;
@property (strong) IBOutlet NSButton *stationJustForPics;
@property (strong) IBOutlet NSButton *stationLifestyle;
@property (strong) IBOutlet NSButton *stationMovieTrailers;
@property (strong) IBOutlet NSButton *stationMusicVideos;
@property (strong) IBOutlet NSButton *stationShortFilms;
@property (strong) IBOutlet NSButton *stationSkit;
@property (strong) IBOutlet NSButton *stationSports;
@property (strong) IBOutlet NSButton *stationTVTeaser; // Used as BON2 News temporarily
@property (strong) IBOutlet NSButton *stationTravel;
@property (strong) IBOutlet NSButton *stationBuyNow;

@property (strong) IBOutlet NSButton *stationPrometheus;
@property (strong) IBOutlet NSButton *stationTravelNinja;
@property (strong) IBOutlet NSButton *stationNowThis;
@property (strong) IBOutlet NSButton *stationWatchMojo;
@property (strong) IBOutlet NSButton *stationShandy;
@property (strong) IBOutlet NSButton *stationRecipe305;

@property (weak) IBOutlet NSPopUpButton *SourceRating;
@property (weak) IBOutlet NSDatePicker *startTimeMarker;
@property (weak) IBOutlet NSDatePicker *endTimeMarker;
@property (weak) IBOutlet NSPopUpButton *tierSelectors;
@property (weak) IBOutlet NSTextField *textLocation;
@property (weak) IBOutlet NSDatePicker *addSkitPicker;
@property (weak) IBOutlet NSTextField *textSkit;

@property (weak) IBOutlet NSButton *monday;
@property (weak) IBOutlet NSButton *tuesday;
@property (weak) IBOutlet NSButton *wendesday;
@property (weak) IBOutlet NSButton *thursday;
@property (weak) IBOutlet NSButton *friday;
@property (weak) IBOutlet NSButton *sunday;
@property (weak) IBOutlet NSButton *saturday;

- (IBAction)onAddSkitMarker:(id)sender;

- (IBAction)familyStationSelected:(id)sender;
- (IBAction)videoRatingSelected:(id)sender;
- (IBAction)btnSelectTagsClick:(id)sender;

@property Boolean IsUploadInProgress;


//tele fields
@property (strong) IBOutlet NSImageView *imgCustomThumbnail;
@property (strong) IBOutlet NSPopUpButton *seriesDropdown;
@property (strong) IBOutlet NSTextField *txtEpisodeNumber;

@end
