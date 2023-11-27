//
//  CSVSettingViewController.m
//  Spokesman
//
//  Created by Admin on 04.08.2020.
//  Copyright © 2020 troomobile. All rights reserved.
//

#import "CSVSettingViewController.h"

@interface CSVSettingViewController ()

@end

@implementation CSVSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.textCurrentThreshold setStringValue:self.thresholdStepper.stringValue];
}

- (IBAction)onPathBtnClicked:(id)sender {
    NSSavePanel* saveDlg = [NSSavePanel savePanel];

    [saveDlg setCanCreateDirectories:true];
    [saveDlg setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];

    if ( [saveDlg runModal] == NSModalResponseOK )
    {
        NSURL *url = [saveDlg URL];
        [self.textPath setStringValue:url.path];
    }
}

- (IBAction)onCancelBtnClicked:(id)sender {
    [self dismissController:nil];
}

- (IBAction)onOkBtnClicked:(id)sender {
    if ([self.textPath.stringValue length] == 0) {
        [self showAlert:@"Warning" message:@"Please set save path"];
        return;
    }

    [self.delegate onSave:self.textPath.stringValue forThreshold:self.thresholdStepper.doubleValue / 100];
    [self dismissController:nil];
}

- (IBAction)onChangedStepper:(id)sender {
    [self.textCurrentThreshold setStringValue:self.thresholdStepper.stringValue];
}

-(void)showAlert:(NSString*)title message:(NSString*)message{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        [alert setAlertStyle:NSWarningAlertStyle];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked, delete the record
        }
    });
}
@end
