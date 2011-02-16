//
//  MGSEditModeToolViewController.h
//  Mother
//
//  Created by Jonathan on 29/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSToolViewController.h"

@class MGSTaskSpecifier;

@protocol MGSToolbarDelegate;

@interface MGSEditModeToolViewController : MGSToolViewController {
	IBOutlet NSSegmentedControl *segmentedButtons;
	IBOutlet NSTextField *label;
	NSInteger _lastSegmentedClicked;
	NSWindow *_window;
	MGSTaskSpecifier *_actionSpecifier;
}

- (IBAction)segControlClicked:(id)sender;
- (void)initialiseForWindow:(NSWindow *)window;
-(void)setActionSpecifier:(MGSTaskSpecifier *)action;

@end
