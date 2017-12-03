//
//  MGSBuildTaskSheetController.h
//  Mother
//
//  Created by Jonathan on 15/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSClientNetRequest.h"

@class MGSTaskSpecifier;

@interface MGSBuildTaskSheetController : NSWindowController <MGSNetRequestOwner> {
	IBOutlet NSTextField *_titleTextField;
	IBOutlet NSTextField *_resultTextField;
    IBOutlet NSTextView *_resultTextView;
	IBOutlet NSButton *_cancelButton;
	IBOutlet NSButton *_OKButton;
	IBOutlet NSButton *_ignoreBuildWarningsCheckbox;
	IBOutlet NSProgressIndicator *_progressIndicator;
	IBOutlet NSView *_infoView;
	MGSTaskSpecifier *_taskSpec;
	BOOL _windowHasQuit;
	id __unsafe_unretained _delegate;
	BOOL _modalWindowWillCloseOnSave;
	BOOL _responseReceived;
	
	NSTimer *_buildTimer;
    NSSize _minFrameSize;
}

@property (strong, nonatomic) MGSTaskSpecifier *taskSpecifier;
@property (unsafe_unretained) id delegate;
@property BOOL modalWindowWillCloseOnSave;

+ (NSInteger)buildWarningsCheckBoxState;

- (IBAction)build:(id)sender;
- (IBAction)OKToCloseWindow:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)closeWindowWithReturnCode:(NSInteger)returnCode;
- (NSInteger)buildWarningsCheckBoxState;
- (void)setBuildWarningsCheckBoxState:(NSInteger)state;
@end
