//
//  MouseDownTextField.h
//  Spokesman
//
//  Created by chaitanya venneti on 24/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Appkit/Appkit.h>
@class MouseDownTextField;

@protocol MouseDownTextFieldDelegate <NSTextFieldDelegate>
-(void) mouseDownTextFieldClicked:(MouseDownTextField *)textField;
@end

@interface MouseDownTextField: NSTextField {
}
@property(assign) id<MouseDownTextFieldDelegate> delegate;
@end