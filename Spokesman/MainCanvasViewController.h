//
//  MainCanvasViewController.h
//  Spokesman
//
//  Created by chaitanya venneti on 24/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreImage/CoreImage.h>
@import AVFoundation;
@import AVKit;
#import "AFNetworking.h"
#import "ColorPanelViewController.h"
#import "PopUpController.h"
#import "CSVSettingViewController.h"

typedef void (^ImageGenerationCompletionHandler)(NSMutableArray *, NSMutableArray *, NSMutableArray* actualTimes);

@protocol AAPLMovieViewControllerDelegate

- (void)movieViewController:(NSUInteger)numberOfImages edlArray:(NSArray<NSValue *> *)edlArray completionHandler:(ImageGenerationCompletionHandler)completionHandler;
- (CMTime)timeAtPercentage:(float)percentage;
- (BOOL)cutMovieTimeRange:(CMTimeRange)timeRange error:(NSError *)error;
- (BOOL)copyMovieTimeRange:(CMTimeRange)timeRange error:(NSError *)error;
- (BOOL)pasteMovieAtTime:(CMTime)time error:(NSError *)error;

@end

@class BFPopoverColorWell;

@interface MainCanvasViewController : NSViewController<NSCollectionViewDataSource, NSCollectionViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSPopoverDelegate, ImportVideoDelegate, CSVSettingDelegate>

@property NSString* username;
- (IBAction)menuInviteUsersClick:(id)sender;
@property (weak) IBOutlet NSTextField *txtCurrentFrame;

@property (strong) AVPlayerItemVideoOutput *output;

@property (strong) IBOutlet NSView *mainView;
@property (weak) IBOutlet NSComboBox *tileCategoryComboBox;
- (IBAction)tileCategoryChanged:(id)sender;

@property (weak) IBOutlet NSButton *btnBrowse;
@property (weak) IBOutlet NSButton *btnConform;
@property (weak) IBOutlet NSButton *btnEmbed;   
@property (weak) IBOutlet NSButton *btnExport;
@property (weak) IBOutlet NSImageView *imgBrowseIndicator;
@property (weak) IBOutlet NSImageView *imgConformIndicator;
@property (weak) IBOutlet NSImageView *imgEmbedIndicator;
@property (weak) IBOutlet NSImageView *imgMyProjectsIndicator;
@property (weak) IBOutlet NSImageView *imgAssetsIndicator;
@property (weak) IBOutlet NSButton *btnSceneDetect;

@property (weak) IBOutlet NSButton *btnMyProjects;

@property (weak) IBOutlet NSBox *boxBrowseMenuItems;
@property (weak) IBOutlet NSBox *boxProjectAssets;
@property (weak) IBOutlet NSBox *boxAssetFiles;

- (IBAction)btnBrowseClick:(id)sender;
- (IBAction)btnConformClick:(id)sender;
- (IBAction)btnEmbedClick:(id)sender;
- (IBAction)btnExportClick:(id)sender;
- (IBAction)btnNewProjectClick:(id)sender;
- (IBAction)btnUploadClick:(id)sender;
- (IBAction)btnMyProjectsClick:(id)sender;
- (IBAction)btnSceneDetectClick:(id)sender;

- (IBAction)btnCloseDialogClick:(id)sender;
- (IBAction)createNewProjectClick:(id)sender;

- (IBAction)handleToolBox:(id)sender;
@property (weak) IBOutlet NSButton *toolBtn;
@property (weak) IBOutlet NSButton *btnPlayAudioTransition;
- (IBAction)btnPlayAudioTransitionClick:(id)sender;
@property (weak) IBOutlet NSImageView *imgAudioGif;

@property (weak) IBOutlet NSButton *btnTileEditLinkFb;

@property (weak) IBOutlet NSButton *btnTileEditLinkInsta;
@property (weak) IBOutlet NSButton *btnTileEditLinkPinterest;
@property (weak) IBOutlet NSButton *btnTileEditLinkTwitter;
@property (weak) IBOutlet NSTextField *btnTileEditLinkWeb;

-(void)splitFrame;
-(void)joinFrames;

-(void)goToNextFrame;
-(void)goToPreviousFrame;

-(void)playPause;
@property (weak) IBOutlet NSView *playerViewParent;
- (IBAction)tileTransparencySliderChanged:(id)sender;

@property (weak) IBOutlet NSTextField *lblMessage;
@property (weak) IBOutlet NSButton *btnCloseDialog;
@property (weak) IBOutlet NSTextField *lblUsername;
@property (weak) IBOutlet NSButton *btnNewProject;
@property (weak) IBOutlet NSBox *dialogView;
@property (weak) IBOutlet NSButton *btnCreateProject;
@property (weak) IBOutlet NSButton *btnUpload;
//
@property (weak) IBOutlet NSBox *projectDialog;
@property (weak) IBOutlet NSBox *projectCreatedDialog;
@property (weak) IBOutlet NSTextField *txtProjectName;

@property (weak) IBOutlet NSBox *ADTileView;
@property (strong) IBOutlet NSImageView *ADTileImage;
@property (weak) IBOutlet NSTextField *ADTileHeading;
@property (weak) IBOutlet NSTextField *ADTileDesc;
@property (unsafe_unretained) IBOutlet NSTextView *ADTileDescView;
@property (weak) IBOutlet NSScrollView *ADTileDescScrollView;
@property (weak) IBOutlet NSStackView *ADTileBtnsStackView;
@property (weak) IBOutlet NSButton *btnDeleteTransition;
- (IBAction)btnDeleteTransitionClick:(id)sender;
@property (weak) IBOutlet NSButton *btnTransitionAudio;
@property (weak) IBOutlet NSButton *btnTransitionImage;
- (IBAction)btnTransitionImageClick:(id)sender;
- (IBAction)btnTransitionAudioClick:(id)sender;
@property (weak) IBOutlet NSView *transitionPreviewView;

@property (weak) IBOutlet NSTextField *lblFrameTime;

@property (weak) IBOutlet NSButton *ADTileFBBtn;
- (IBAction)btnFbLinkClicked:(id)sender;

@property (weak) IBOutlet NSButton *ADTileInstaBtn;
- (IBAction)btnInstaLinkClicked:(id)sender;

@property (weak) IBOutlet NSButton *ADTilePinterestBtn;
- (IBAction)btnPinterestLinkClicked:(id)sender;

@property (weak) IBOutlet NSButton *ADTileTwitterBtn;
- (IBAction)btnTwitterLinkClicked:(id)sender;


@property (weak) IBOutlet NSButton *ADTileURLBtn;
- (IBAction)ADTileURLBtnClicked:(id)sender;

@property (weak) IBOutlet NSButton *ADTileThumb;
- (IBAction)ADTileThumbClicked:(id)sender;

@property (weak) IBOutlet NSBox *playerbox;

@property (weak) IBOutlet AVPlayerView *playerView;
@property id<AAPLMovieViewControllerDelegate> delegate;
- (void)updateMovieTimeline;
@property (weak) IBOutlet NSCollectionView *timelineCollection;
@property (weak) IBOutlet NSButton *btnImportVideoAsset;
@property (weak) IBOutlet NSScrollView *timelineScrollView;

- (IBAction)btnImportVideoAssetClicked:(id)sender;
//@property (weak) IBOutlet NSButton *radioCurrentFile;
@property (weak) IBOutlet NSProgressIndicator *uploadProgress;
@property (weak) IBOutlet NSView *embedView;
@property (strong) IBOutlet NSButton *chkShowTileInSidebox;
@property (weak) IBOutlet NSCollectionView *embedImagesCollectionView;
@property (weak) IBOutlet NSCollectionView *libraryCollectionView;
@property (weak) IBOutlet NSButton *btnAssemble;

- (IBAction)menuSearchProductsClick:(id)sender;

@property (weak) IBOutlet NSTextField *txtUploadStatus;
@property (weak) IBOutlet NSTableView *tblProjectsList;
@property (weak) IBOutlet NSTableView *tblImportAssets;

@property (weak) IBOutlet NSButton *chkVideos;
@property (weak) IBOutlet NSButton *chkEDLs;
@property (weak) IBOutlet NSButton *chkPictures;
@property (weak) IBOutlet NSButton *chkAudio;
@property (weak) IBOutlet NSButton *chkSelectAllAssets;

- (IBAction)chkVideoClicked:(id)sender;
- (IBAction)chkEDLClicked:(id)sender;
- (IBAction)chkPicturesClicked:(id)sender;
- (IBAction)chkAudioClicked:(id)sender;
- (IBAction)chkSelectAllClicked:(id)sender;

- (IBAction)projectsSelectionChanged:(id)sender;
- (IBAction)assetsSelectionChanged:(id)sender;
- (IBAction)conformVideosSelectionChanged:(id)sender;
- (IBAction)conformEDLsSelectionChanged:(id)sender;
- (IBAction)EDLSelectionChanged:(id)sender;

@property (weak) IBOutlet NSButton *btnEmbedSelected;

@property (weak) IBOutlet NSButton *btnConformSelected;
@property (weak) IBOutlet NSBox *boxBinView;
@property (weak) IBOutlet NSTableView *tblBinFiles;
- (IBAction)btnEmbedSelectedClick:(id)sender;
- (IBAction)btnConformSelectedClick:(id)sender;

- (IBAction)btnAddFilesClick:(id)sender;
@property (weak) IBOutlet NSButton *btnAddFiles;

@property (weak) IBOutlet NSTableView *tblConformVideos;

@property (weak) IBOutlet NSTableView *tblConformEDLs;
@property (weak) IBOutlet NSView *activityBoxView;
@property (weak) IBOutlet NSView *browseView;
@property (weak) IBOutlet NSView *conformView;
- (IBAction)btnAssembleClicked:(id)sender;
- (IBAction)videoSelectedForConform:(id)sender;
- (IBAction)EDLSelectedForConform:(id)sender;

@property (weak) IBOutlet NSTableView *tblEDLs;
@property (weak) IBOutlet NSScrollView *projectsScrollView;
@property (weak) IBOutlet NSImageView *previewThumbImageView;

//Embed View
@property (weak) IBOutlet NSImageView *imgSelectedAssetImage;
@property (weak) IBOutlet NSButton *btnSaveTile;
@property (weak) IBOutlet NSButton *btnEditTile;
@property (weak) IBOutlet NSButton *btnApplyTile;
@property (weak) IBOutlet NSButton *btnDeleteTile;
- (IBAction)btnAddNewTransitionClick:(id)sender;
- (IBAction)btnAddNewSoundClick:(id)sender;
@property (weak) IBOutlet NSButton *btnAddNewSound;
@property (weak) IBOutlet NSButton *btnAddNewTransition;
@property (weak) IBOutlet NSButton *btnDeleteSound;
- (IBAction)btnDeleteSoundClick:(id)sender;
@property (weak) IBOutlet NSComboBox *soundsComboBox;

@property (weak) IBOutlet NSView *plateview;
@property (weak) IBOutlet NSView *transitionView;
@property (weak) IBOutlet NSView *tileTextView;
@property (weak) IBOutlet NSView *tileLinkView;

@property (strong) IBOutlet NSTextField *txtCTASize;

- (IBAction)btnAddCtaClick:(id)sender;

@property (strong) IBOutlet NSView *ctaDialog;

@property (weak) IBOutlet NSButton *btnPlateColor;
@property (weak) IBOutlet NSButton *btnTileTransition;
@property (weak) IBOutlet NSButton *btnTileText;
@property (weak) IBOutlet NSButton *btnTileLink;
@property (weak) IBOutlet NSBox *btnPlateColorBorder;
@property (weak) IBOutlet NSBox *btnTileTransitionBorder;
@property (weak) IBOutlet NSBox *btnTileTextBorder;
@property (weak) IBOutlet NSBox *btnTileLinkBorder;

@property (weak) IBOutlet NSButton *btnEmbedProducts;
@property (weak) IBOutlet NSButton *btnEmbedPeople;
@property (weak) IBOutlet NSBox *btnEmbedProductsBorder;
@property (weak) IBOutlet NSBox *btnEmbedPeopleBorder;

@property (weak) IBOutlet NSButton *btnAddMorePeople;
- (IBAction)btnAddPeopleClick:(id)sender;


- (IBAction)btnEmbedProductsClick:(id)sender;
- (IBAction)btnEmbedPeopleClick:(id)sender;


- (IBAction)btnPlateColorClick:(id)sender;
- (IBAction)btnTileTransitionClick:(id)sender;
- (IBAction)btnTileTextClick:(id)sender;
- (IBAction)btnTileLinkClick:(id)sender;

- (IBAction)btnSaveTileClick:(id)sender;
- (IBAction)btnEditTileClick:(id)sender;
- (IBAction)btnApplyTileClick:(id)sender;
- (IBAction)btnDeleteTileClick:(id)sender;
@property (weak) IBOutlet NSSlider *eldTimeSlider;
- (IBAction)edlTimeSliderChanged:(id)sender;

- (IBAction)createArtistClick:(id)sender;
- (IBAction)searchArtistsClick:(id)sender;
- (IBAction)createProductClick:(id)sender;
- (IBAction)createNewBrandClick:(id)sender;
- (IBAction)createNewLocationClick:(id)sender;

//tile text
@property (weak) IBOutlet NSTextField *txtTileHeading;
@property (weak) IBOutlet NSTextField *txtTileDescription;
@property (weak) IBOutlet NSTextField *txtTileLink; //holds facebook url
@property (weak) IBOutlet NSTextField *txtTwitterLink;
@property (weak) IBOutlet NSTextField *txtInstaLink;
@property (weak) IBOutlet NSTextField *txtPinterestLink;
@property (weak) IBOutlet NSTextField *txtWebsiteLink;

@property (weak) IBOutlet NSButton *btnTextColorSelect;
@property (weak) IBOutlet NSButton *btnSetTextBold;
@property (weak) IBOutlet NSButton *btnSetTextItalic;
@property (weak) IBOutlet NSButton *btnSetTextUnderline;
@property (weak) IBOutlet NSButton *btnSetTextAlignLeft;
@property (weak) IBOutlet NSButton *btnSetTextAlignCenter;
@property (weak) IBOutlet NSButton *btnSetTextAlignRight;
- (IBAction)btnSetTextColorClick:(id)sender;
- (IBAction)btnSetTextBoldClick:(id)sender;
- (IBAction)btnSetTextItalicClick:(id)sender;
- (IBAction)btnSetTextUnderlineClick:(id)sender;
- (IBAction)btnSetTextLeftAlignClick:(id)sender;
- (IBAction)btnSetTextCenterAlignClick:(id)sender;
- (IBAction)btnSetTextRightAlignClick:(id)sender;
- (IBAction)colorSelected:(id)sender;
@property (weak) IBOutlet NSColorWell *cgColorWell;

- (IBAction)plateColorSelected:(id)sender;
@property (weak) IBOutlet NSColorWell *plateColorWell;

- (IBAction)headingSelected:(id)sender;
- (IBAction)descriptionSelected:(id)sender;
@property (weak) IBOutlet NSTextField *lblSelectProjectTitleBar;
- (IBAction)selectTransitionOption:(id)sender;

@property (weak) IBOutlet NSButton *btnRadioWipe;
@property (weak) IBOutlet NSButton *btnRadioZoom;
@property (weak) IBOutlet NSButton *btnRadioDissolve;

//player controls
@property (weak) IBOutlet NSButton *btnPrevious;
@property (weak) IBOutlet NSButton *btnNext;
@property (weak) IBOutlet NSButton *btnLoop;
@property (weak) IBOutlet NSButton *btnPlayPause;
@property (weak) IBOutlet NSTextField *lblCurrentFrameTime;

- (IBAction)btnPreviouClick:(id)sender;
- (IBAction)btnNextClick:(id)sender;
- (IBAction)btnLoopClick:(id)sender;
- (IBAction)btnPlayPauseClick:(id)sender;

//export dialog scrollbars

@property (weak) IBOutlet NSButton *btnRemoveTileFromEdit;

- (IBAction)btnRemoveTileFromFrameClick:(id)sender;
//busy
@property (weak) IBOutlet NSVisualEffectView *progressView;
@property (weak) IBOutlet NSProgressIndicator *progressWheel;

//selected tile details and animation sliders
@property (weak) IBOutlet NSView *tileDetailsView;
@property (weak) IBOutlet NSImageView *selectedTileImage;
@property (weak) IBOutlet NSView *quickPlaceView;

@property (weak) IBOutlet NSSlider *selectedTileFramesSlider;
@property (weak) IBOutlet NSButton *btnCreateCategoryTile;
- (IBAction)btnCreateCategoryTileClick:(id)sender;
@property (strong) IBOutlet NSButton *btnCreateCTATile;
- (IBAction)btnCreateCTATileClick:(id)sender;
@property (strong) IBOutlet NSSlider *ctaDurationSlider;
@property (strong) IBOutlet NSTextField *lblCTAduration;

- (IBAction)ctaDurationChanged:(id)sender;


@property (weak) IBOutlet NSButton *btnSelectedTilePlate;
- (IBAction)btnSelectedTilePlateClick:(id)sender;
@property (weak) IBOutlet NSButton *btnSelectedTileTransition;
- (IBAction)btnSelectedTileTransitionClick:(id)sender;
@property (weak) IBOutlet NSButton *btnSelectedTileText;
- (IBAction)btnSelectedTileTextClick:(id)sender;
@property (weak) IBOutlet NSButton *btnSelectedTileLinks;
- (IBAction)btnSelectedTileLinksClick:(id)sender;
@property (weak) IBOutlet NSButton *btnShowTileIcon;
@property (weak) IBOutlet NSButton *btnHideTileIcon;
- (IBAction)btnShowTileIconClick:(id)sender;
- (IBAction)btnHideTileIconClick:(id)sender;

- (IBAction)soundsComboBoxChanged:(id)sender;
@property (weak) IBOutlet NSButton *chkIsTileDefault;
@property (weak) IBOutlet NSButton *chkUseProfilePicAsIcon;

- (IBAction)selectedTilesFrameSliderChanged:(id)sender;
@property (weak) IBOutlet NSComboBox *transitionComboBox;
- (IBAction)transitionComboBoxChanged:(id)sender;
@property (weak) IBOutlet NSView *transitionPlayView;
- (IBAction)btnCloseOpenTileClick:(id)sender;
@property (weak) IBOutlet NSButton *btnCloseOpenTile;
@property (weak) IBOutlet NSTextField *txtTileTransparency;
@property (weak) IBOutlet NSSlider *tileTransparencySlider;
@property (weak) IBOutlet NSImageView *imgExpertViewIndicator;

- (IBAction)btnSaveEdlClick:(id)sender;
- (IBAction)btnCreateSeriesClicked:(id)sender;

@property (weak) IBOutlet NSPopUpButton *quickPlaceSet;
- (IBAction)onChangePlaceSet:(id)sender;
@property (weak) IBOutlet NSButton *quickPlaceBtn1;
- (IBAction)onQuickPlaceBtn1Clicked:(id)sender;
@property (weak) IBOutlet NSButton *quickPlaceBtn2;
- (IBAction)onQuickPlaceBtn2Clicked:(id)sender;
@property (weak) IBOutlet NSButton *quickPlaceBtn3;
- (IBAction)onQuickPlaceBtn3Clicked:(id)sender;
@property (weak) IBOutlet NSButton *quickPlaceBtn4;
- (IBAction)onQuickPlaceBtn4Clicked:(id)sender;
@property (weak) IBOutlet NSButton *quickPlaceBtn5;
- (IBAction)onQuickPlaceBtn5Clicked:(id)sender;
@property (weak) IBOutlet NSButton *quickPlaceBtn6;
- (IBAction)onQuickPlaceBtn6Clicked:(id)sender;
@property (weak) IBOutlet NSButton *quickPlaceBtn7;
- (IBAction)onQuickPlaceBtn7Clicked:(id)sender;
@property (weak) IBOutlet NSButton *quickPlaceBtn8;
- (IBAction)onQuickPlaceBtn8Clicked:(id)sender;
@property (weak) IBOutlet NSButton *quickPlaceBtn9;
- (IBAction)onQuickPlaceBtn9Clicked:(id)sender;
@property (weak) IBOutlet NSButton *quickPlaceBtn10;
- (IBAction)onQuickPlaceBtn10Clicked:(id)sender;

@property BOOL isShowingExportView;
- (void)addOrPlaceQuickPlaceSet:(int ) number forcePlace: (BOOL) forcePlace;
- (void)removeQuickPlaceSet:(int ) number;

@property NSMutableArray* quickPlaceSetTiles;

@property (weak) IBOutlet NSButton *btnRemoveProject;
- (IBAction)btnRemoveProjectClicked:(id)sender;

@end
