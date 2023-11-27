//
//  SeachUserWindowController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 05/03/17.
//  Copyright © 2017 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SearchUserWindowController : NSWindowController<NSSearchFieldDelegate, NSTableViewDelegate, NSTableViewDataSource>
@property (weak) IBOutlet NSSearchField *txtSearchUser;
@property (weak) IBOutlet NSTableView *tableView;
@property BOOL isForArtist;
@end
