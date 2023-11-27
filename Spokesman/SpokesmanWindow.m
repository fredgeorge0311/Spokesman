//
//  SpokesmanWindow.m
//  Spokesman
//
//  Created by Chaitanya VRK on 18/03/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "SpokesmanWindow.h"
#import "MainCanvasViewController.h"

@implementation SpokesmanWindow

-(void)sendEvent:(NSEvent *)anEvent
{
    [super sendEvent:anEvent];
    switch ([anEvent type]) {
        case NSKeyDown:
            if ([self.contentViewController isKindOfClass:[MainCanvasViewController class]]) {
                MainCanvasViewController *controller = (MainCanvasViewController*)self.contentViewController;
                if (!controller.isShowingExportView) {
                    if(![anEvent isARepeat]) {
                        if ([anEvent keyCode] == 49) { //space
                            if([[self firstResponder] isKindOfClass:[NSTextField class]] || [[self firstResponder] isKindOfClass:[NSTextView class]])
                            {
                                break;
                            }
                            else{
                                NSPoint pt; pt.x = pt.y = 0;
                                NSEvent *fakeEvent = [NSEvent keyEventWithType:NSKeyDown
                                                                      location:pt
                                                                 modifierFlags:0
                                                                     timestamp:[[NSProcessInfo processInfo] systemUptime]
                                                                  windowNumber: 0 // self.windowNumber
                                                                       context:[NSGraphicsContext currentContext]
                                                                    characters:@" "
                                                   charactersIgnoringModifiers:@" "
                                                                     isARepeat:NO
                                                                       keyCode:49];
                                [[NSApp mainMenu] performKeyEquivalent:fakeEvent];
                            }
                        }
                        else if ([anEvent keyCode] >= 18 && [anEvent keyCode] <= 29 && [anEvent keyCode] != 24 && [anEvent keyCode] != 27) { //number 0~1
                            int number = 1;
                            switch ([anEvent keyCode]) {
                                case 18:
                                    number = 1;
                                    break;
                                case 19:
                                    number = 2;
                                    break;
                                case 20:
                                    number = 3;
                                    break;
                                case 21:
                                    number = 4;
                                    break;
                                case 22:
                                    number = 6;
                                    break;
                                case 23:
                                    number = 5;
                                    break;
                                case 25:
                                    number = 9;
                                    break;
                                case 26:
                                    number = 7;
                                    break;
                                case 28:
                                    number = 8;
                                    break;

                                default:
                                    number = 10;
                            }

                            NSUInteger flags = [anEvent modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
                            if (flags == NSCommandKeyMask) {
                                [controller removeQuickPlaceSet:number];
                            }
                            else if (flags == NSShiftKeyMask) {
                                [controller addOrPlaceQuickPlaceSet:number + 10 forcePlace:false];
                            }
                            else if (flags == 0) {
                                [controller addOrPlaceQuickPlaceSet:number forcePlace:false];
                            }
                        }
                    }
                }
            }

            break;
            
        default:
            break;
    }
}

@end
