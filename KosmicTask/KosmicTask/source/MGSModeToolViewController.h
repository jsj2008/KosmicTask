//
//  MGSModeToolViewController.h
//  Mother
//
//  Created by Jonathan on 07/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSMotherModes.h"
#import "MGSToolViewController.h"

@protocol MGSToolbarDelegate;

@class MGSNetClient;

@interface MGSModeToolViewController : MGSToolViewController {
	IBOutlet NSSegmentedControl *segmentedButtons;
	IBOutlet NSTextField *label;
    IBOutlet NSProgressIndicator *progress;
    
	//IBOutlet NSButton *loginButton;
	eMGSMotherRunMode _segmentMode;
	eMGSMotherRunMode _prevSegmentMode;
	eMGSMotherRunMode _pendingSegmentMode;
	MGSNetClient *_netClient;
}

- (IBAction)segControlClicked:(id)sender;
- (void)initialiseForWindow:(NSWindow *)window;
- (IBAction)logIn:(id)sender;
- (void)updateSegmentModeText:(id)sender;
- (void)updateSegmentStatus;
- (void)setRunMode:(NSInteger)mode;

@end
