//
//  MGSErrorWindowController.h
//  Mother
//
//  Created by Jonathan on 17/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSError;

@interface MGSErrorWindowController : NSWindowController <NSWindowDelegate> {
	IBOutlet NSTableView *tableview;
	IBOutlet NSTabView *tabView;
	IBOutlet NSTextView *textView;
	IBOutlet NSSegmentedControl *modeSegment;
	IBOutlet NSTextField *logSizeTextField;
	IBOutlet NSScroller *textViewScroller;
	
	NSArrayController *_errorController;
	BOOL _logRetrieved;
}

- (IBAction)segControlClick:(id)sender;
- (IBAction)clearLog:(id)sender;

- (void)addError:(MGSError *)error;
- (void)updateLogDisplay;
- (void)retrieveLog;
- (void)updateLogSizeDisplay;

@end
