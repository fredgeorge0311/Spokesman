//
//  SearchArtistsController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 03/01/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol AddArtistsDelegate;

@interface SearchArtistsController : NSViewController<NSTableViewDelegate, NSTableViewDataSource>
@property (weak) IBOutlet NSTableView *artistsTableView;
- (IBAction)btnCloseClick:(id)sender;
@property (weak) IBOutlet NSProgressIndicator *loading;
- (IBAction)btnEditArtistClick:(id)sender;
@property (weak) IBOutlet NSTextField *txtSearch;
- (IBAction)btnSearchClick:(id)sender;
- (IBAction)btnReloadAllClick:(id)sender;
- (IBAction)txtSearchEnter:(id)sender;
- (IBAction)btnDeleteArtistClick:(id)sender;
@property (weak) IBOutlet NSButton *btnAddArtists;
@property (weak) IBOutlet NSButton *btnClose;
- (IBAction)btnAddArtistsClick:(id)sender;
- (IBAction)radioSearchTypeSet:(id)sender;
@property (weak) IBOutlet NSButton *radioAlbums;
@property (weak) IBOutlet NSButton *radioName;

-(void)reloadData;

@property (nonatomic,weak) id<AddArtistsDelegate> delegate;
@end

@protocol AddArtistsDelegate <NSObject>

-(void)searchArtistsController:(SearchArtistsController*)viewController didSelectedArtists:(NSMutableArray*)artists;

@end
