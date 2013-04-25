//
//  MGSScriptEditViewController.h
//  Mother
//
//  Created by Jonathan on 08/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAKit.h>
#import "MGSClientNetRequest.h"

/* build initiated */	
#define MGS_BUILD_FLAG_INITIATED (1 << 0)

/* build confirmed */	
#define MGS_BUILD_FLAG_COMPLETED (1 << 1)

/* warnings and/or errors were generated during the build.
 the warning may indicate a non fatal condition, we have no real way of knowing.
 anyhow, we will allow the user the opportunity to exeute the script.
 */
#define MGS_BUILD_FLAG_WARNING (1 << 2)

/* a build error was found in the pay load */
#define MGS_BUILD_FLAG_ERROR_PAYLOAD (1 << 3)

/* if a compiled response is expected and not received then the error is fatal.
 the user will not be allowed the opportunity to run the script
 */ 
#define MGS_BUILD_FLAG_FATAL_ERROR (1 << 4)

/* a data error was detected in the build result */ 
#define MGS_BUILD_FLAG_DATA_ERROR (1 << 5)

/* build is pending */
#define MGS_BUILD_PENDING 0

/* build initiated */
#define MGS_BUILD_INITIATED MGS_BUILD_FLAG_INITIATED

/* no warnings in build */
#define MGS_BUILD_NO_WARNINGS (MGS_BUILD_FLAG_INITIATED | MGS_BUILD_FLAG_COMPLETED)

#define MGS_BUILD_RESULT_INDEX_CONSOLE 0
#define MGS_BUILD_RESULT_INDEX_STDERR 1

extern NSString * const MGSIgnoreBuildError;

@class MGSScriptViewController;
@class MGSTaskSpecifier;
@class MGSApplesScriptDictWindowController;
@class MGSBuildTaskSheetController;
@class MGSSettingsOutlineViewController;

@interface MGSScriptEditViewController : NSViewController {
	IBOutlet NSSplitView *splitView;	// points to same view as NSViewController -view
	IBOutlet NSTextView *consoleTextView;
	IBOutlet NSView *buildResultView;
	IBOutlet NSPopUpButton *scriptType;
	IBOutlet NSSegmentedControl *modeSegment;
    IBOutlet NSImageView *splitViewDragImage;
	IBOutlet NSSegmentedControl *buildResultSegment;
	IBOutlet NSTextField *buildStatusTextField;
	IBOutlet NSTextField *onRunBehaviour;
    
	MGSScriptViewController *scriptViewController;
	MGSSettingsOutlineViewController *settingsOutlineViewController;
	NSInteger buildStatusFlags;
	NSInteger buildResultIndex;
	NSString *buildSheetMessage;
	NSString *buildStderrResult;
	NSString *buildResult;
	NSString *buildStatus;
	
	MGSTaskSpecifier *_taskSpec;
	MGSApplesScriptDictWindowController *_applesScriptDictWindowController;	
	BOOL _nibLoaded;
	BOOL scriptBuilt;
	BOOL languageRequiresBuild;
	BOOL canExecuteScript;
	BOOL languageSupportsBuild;
	BOOL canBuildScript;
	BOOL requestExecuteOnSuccessfulBuild;
	
	id _osaDict;
	NSWindow *_pendingWindow;
	MGSBuildTaskSheetController *_buildTaskSheetController;
	NSString *_buildConsoleResult;
	NSDictionary *consoleAttributes;
	
	NSMutableDictionary *consoleErrorOptions;
	NSMutableDictionary *consoleTextOptions;
	NSMutableDictionary *consoleSuccessOptions;
}

- (IBAction)showTemplateEditor:(id)sender;
- (IBAction)scriptTypeAction:(id)sender;
- (IBAction)modeSegmentAction:(id)sender;
- (IBAction)showSettings:(id)sender;

- (BOOL)commitPendingEdits;
- (BOOL)scriptBuilt;
- (void)dispose;
- (void)printDocument:(id)sender;
- (NSView *)initialFirstResponder;
- (void)requestExecute;
- (BOOL)canSaveScript;
- (NSUndoManager *)undoManager;
- (void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload options:(NSDictionary *)options;
- (void)insertText:(NSString *)text;
- (NSTextView *)scriptTextView;

@property(assign) MGSTaskSpecifier *taskSpec;

@property NSWindow *pendingWindow;
@property (copy) NSString *buildConsoleResult;
@property (readonly) MGSScriptViewController *scriptViewController;
@property (readonly) NSInteger buildStatusFlags;
@property NSInteger buildResultIndex;
@property (copy) NSString *buildSheetMessage;
@property (copy) NSString *buildStderrResult;
@property (assign) NSString *buildResult;
@property (copy, readonly) NSString *buildStatus;
@property (readonly) BOOL languageRequiresBuild;
@property (readonly) BOOL languageSupportsBuild;
@property (readonly) BOOL scriptBuilt;
@property (readonly) BOOL canExecuteScript;
@property (readonly) BOOL canBuildScript;
@end
