//
//  MGSSaveConfigurationWindowController.h
//  Mother
//
//  Created by Jonathan on 26/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSClientNetRequest.h"
@class MGSNetClient;

@interface MGSSaveConfigurationWindowController : NSWindowController <MGSNetRequestOwner>{
	IBOutlet NSTextField *mainLabel;
	IBOutlet NSButton *saveButton;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *dontSaveButton;
	IBOutlet NSTableView *changesTableView;
	IBOutlet NSView *infoView;
	IBOutlet NSProgressIndicator *progressView;
	IBOutlet NSTextField *changeCountLabel;

	NSTimer *_cancellationTimer;
	NSArrayController *_changesArrayController;
	NSWindow *_modalForWindow;
	MGSNetClient *_netClient;
	BOOL _doCallBack;
}

@property NSWindow *modalForWindow;
@property BOOL doCallBack;

- (id)initWithNetClient:(MGSNetClient*)netClient;
- (IBAction)closeWindow:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)dontSave:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)undoConfigurationChanges;
- (BOOL)showSaveSheet;
- (void)callBack:(BOOL)value;
@end
