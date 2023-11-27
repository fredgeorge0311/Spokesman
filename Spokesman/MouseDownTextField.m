//
//  MouseDownTextField.m
//  Spokesman
//
//  Created by chaitanya venneti on 24/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "MouseDownTextField.h"

@implementation MouseDownTextField

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)mouseDown:(NSEvent *)event {
    [self.delegate mouseDownTextFieldClicked:self];
}

-(void)setDelegate:(id<MouseDownTextFieldDelegate>)delegate {
    [super setDelegate:delegate];
}

-(id)delegate {
    return [super delegate];
}

@end



