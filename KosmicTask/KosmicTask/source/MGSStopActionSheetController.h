//
//  MGSStopActionSheetController.h
//  Mother
//
//  Created by Jonathan on 24/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetRequest.h"

@interface MGSStopActionSheetController : NSWindowController <MGSNetRequestOwner> {
	NSInteger _processingCount;
	IBOutlet NSTextField *titleTextField;
	IBOutlet NSTextField *messageTextField;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *acceptButton;
	IBOutlet NSView *infoView;
	IBOutlet NSProgressIndicator *progressIndicator;
	
	NSInteger _stoppedActionCount;
	NSInteger _responseCount;
	NSTimer *_responseTimer;
	NSTimer *_actionMonitorTimer;
	float _waitTime;
	
	BOOL _acceptButtonQuits;
}

@property NSInteger processingCount;

- (void)closeWindowWithReturnCode:(NSInteger)returnCode;
- (IBAction)cancel:(id)sender;
- (IBAction)accept:(id)sender;
- (void)quitNow:(id)sender;

@end
