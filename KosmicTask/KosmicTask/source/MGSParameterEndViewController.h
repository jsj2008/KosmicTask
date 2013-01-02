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
    IBOutlet NSSegmentedControl *inputSegmentedControl;
    IBOutlet MGSPopupButton *contextPopupButton;
    IBOutlet id delegate;
    NSColor *_capsuleBackgroundColor;
    NSColor *_capsuleDragBackgroundColor;
}

- (void)setIsDragTarget:(BOOL)isDragTarget;

@property (readonly) NSSegmentedControl *inputSegmentedControl;
@property (readonly) MGSPopupButton *contextPopupButton;
@property id delegate;

@end
