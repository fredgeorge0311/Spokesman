//
//  MainWindowController.m
//  Spokesman
//
//  Created by chaitanya venneti on 23/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "MainWindowController.h"
#import "ViewController.h"
#import "MainCanvasViewController.h"
#import "AppDelegate.h"
@interface MainWindowController ()<NSWindowDelegate>

@end

@implementation MainWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    AppDelegate *appDelegate = [NSApp delegate];
    appDelegate.mainWindowController = self;
    
    ViewController *viewController = [self.storyboard instantiateControllerWithIdentifier:@"LandingPageViewController"];
    //NSRect _mainframe = [[NSScreen mainScreen] visibleFrame];
    //[viewController.bgImageView setFrame:_mainframe];
    //[[viewController view] setFrame:_mainframe];
    [self.window setDelegate:self];
    self.window.contentViewController = viewController;
    //[self.window zoom:NULL];
}

- (void)keyDown:(NSEvent *)theEvent {

    if([self.window.contentViewController isKindOfClass:[MainCanvasViewController class]])
    {
        [(MainCanvasViewController*)self.window.contentViewController keyDown:theEvent];
    }
}

-(void)windowWillLoad{
    [super windowWillLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
   // NSRect _fr = [[NSScreen mainScreen] visibleFrame];
    
   // [_mainWindow setFrame:_fr display:YES];
   // [_mainWindow setContentSize:_fr.size];
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet
       usingRect:(NSRect)rect {
    /*NSRect fieldRect = [[NSScreen mainScreen] visibleFrame];
    
    
    fieldRect.origin.y += 80;//fieldRect.size.height - 100;
    
    fieldRect.size.height = 0;
    return fieldRect;*/
    
    rect.origin.y -= 100;  // or as much as we need
    return rect;
}

@end
