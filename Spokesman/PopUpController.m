//
//  PopUpController.m
//  Spokesman
//
//  Created by Admin on 23.07.2020.
//  Copyright © 2020 troomobile. All rights reserved.
//

#import "PopUpController.h"

@interface PopUpController ()
    
@end

@implementation PopUpController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)onBtnClickYoutube:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText: @"Please insert youtuve video url"];

    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    [input setMaximumNumberOfLines:1];
    [input setStringValue:@"https://www.youtube.com/watch?v=Dh-ULbQmmF8"];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertFirstButtonReturn) {
        [self.importVideoDelegate importYoutubeVideo:input.stringValue];
    }
}

- (IBAction)onBtnLocal:(id)sender {
    [self.importVideoDelegate openFileDialog];
}

@end
