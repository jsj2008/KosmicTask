//
//  MGSDisplayToolViewController.h
//  Mother
//
//  Created by Jonathan on 05/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSToolViewController.h"

@class MGSTaskSpecifier;
@class MGSPlayButton;
@class MGSStopButton;
@class MGSTimeIntervalTransformer;
@class MGSLCDDisplayView;

@interface MGSDisplayToolViewController : MGSToolViewController {
	IBOutlet MGSLCDDisplayView *lcdDisplayView;	// display image
	IBOutlet NSImageView *statusImage;
	IBOutlet NSImageView *hostImage;
	//IBOutlet NSLevelIndicator *levelIndicator;
	IBOutlet NSTextField *elapsedTime;
	IBOutlet NSTextField *remainingTime;
	IBOutlet MGSPlayButton *playButton;
	IBOutlet MGSStopButton *stopButton;
	IBOutlet NSTextField *actionPath;
	IBOutlet NSTextField *actionStatus;
	
	NSObjectController *_objectController; 
	
	MGSTaskSpecifier *_actionSpecifier; // currently active action
	MGSTimeIntervalTransformer *_intervalTransformer;
	NSDictionary *_bindingOptions;
	
	MGSTimeIntervalTransformer *_negIntervalTransformer;
	NSDictionary *_negBindingOptions;
	
	NSWindow *_window;
	NSColor *_textColor;
	BOOL _highlight;
}
- (void)initialiseForWindow:(NSWindow *)window;
- (IBAction)toggleActionExecution:(id)sender;
- (IBAction)terminateAction:(id)sender;

@property (strong, nonatomic) MGSTaskSpecifier *actionSpecifier;
@property (copy) NSColor *textColor;
@property (nonatomic) BOOL highlight;

@end
