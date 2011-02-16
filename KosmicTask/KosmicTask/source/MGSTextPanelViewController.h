//
//  MGSTextPanelViewController.h
//  Mother
//
//  Created by Jonathan on 31/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSTaskSpecifier.h"
@class MGSActionActivityView;

@interface MGSTextPanelViewController : NSViewController {
	IBOutlet NSTextField *_textField;
	IBOutlet MGSActionActivityView *_actionActivityView;
	NSTimer *_animationTimer;
	NSArray *_animationColorArray;
	NSUInteger _animationColorIndex;
	BOOL _animationColorIndexIncreasing;
	BOOL _highlighted;
}

@property (getter=isHighlighted) BOOL highlighted;

- (void)setStringValue:(NSString *)aString;
- (void)setActivity:(MGSTaskActivity)activity;
- (IBAction)initialiseAction:(id)sender;
@end
