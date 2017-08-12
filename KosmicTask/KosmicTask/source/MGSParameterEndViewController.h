//
//  MGSParameterEndView.h
//  Mother
//
//  Created by Jonathan on 12/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSPopupButton;

@interface MGSParameterEndViewController : NSViewController {
	IBOutlet NSTextField *_textField;
    IBOutlet NSSegmentedControl *__weak inputSegmentedControl;
    IBOutlet MGSPopupButton *__unsafe_unretained contextPopupButton;
    IBOutlet id __unsafe_unretained delegate;
    NSColor *_capsuleBackgroundColor;
    NSColor *_capsuleDragBackgroundColor;
}

- (void)setIsDragTarget:(BOOL)isDragTarget;

@property (weak, readonly) NSSegmentedControl *inputSegmentedControl;
@property (unsafe_unretained, readonly) MGSPopupButton *contextPopupButton;
@property (unsafe_unretained) id delegate;

@end
