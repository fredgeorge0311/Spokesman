//
//  SearchProductsController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 11/03/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol AddProductsDelegate;


@interface SearchProductsController : NSViewController<NSTableViewDelegate, NSTableViewDataSource>
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

- (IBAction)btnSearchCategoryClick:(id)sender;

@property (nonatomic) BOOL isShopify;


@property (strong) IBOutlet NSButton *btnSearchShopify;

-(void)reloadData;
@property (strong) IBOutlet NSButton *btnSearchBON2;

@property (nonatomic,weak) id<AddProductsDelegate> delegate;
@end

@protocol AddProductsDelegate <NSObject>

-(void)searchProductsController:(SearchProductsController*)viewController didSelectedProducts:(NSMutableArray*)products;

@end

