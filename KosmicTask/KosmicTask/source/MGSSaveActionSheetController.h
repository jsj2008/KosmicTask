//
//  MGSSaveActionSheetController.h
//  Mother
//
//  Created by Jonathan on 26/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSClientNetRequest.h"

@class MGSTaskSpecifier;

@interface MGSSaveActionSheetController : NSWindowController <MGSNetRequestOwner> {
	IBOutlet NSTextField *_titleTextField;
	IBOutlet NSButton *_cancelButton;
	IBOutlet NSButton *_saveButton;
	IBOutlet NSButton *_dontSaveButton;
	IBOutlet NSProgressIndicator *_progressIndicator;
	IBOutlet NSView *_infoView;
	MGSTaskSpecifier *_action;
	BOOL _saveButtonQuits;
	BOOL _windowHasQuit;
	id _delegate;
	BOOL _modalWindowWillCloseOnSave;
	BOOL _saveCompleted;
}

@property (assign) MGSTaskSpecifier *action;
@property id delegate;
@property BOOL modalWindowWillCloseOnSave;
@property BOOL saveCompleted;


- (IBAction)save:(id)sender;
- (IBAction)dontSave:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)closeWindowWithReturnCode:(NSInteger)returnCode;
- (void)saveFailed:(MGSError *)error;

@end
