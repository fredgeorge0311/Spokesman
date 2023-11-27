//
//  MainWindowController.h
//  Spokesman
//
//  Created by chaitanya venneti on 23/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpokesmanWindow.h"

@interface MainWindowController : NSWindowController <NSWindowDelegate>
@property (weak) IBOutlet SpokesmanWindow *mainWindow;

@end
