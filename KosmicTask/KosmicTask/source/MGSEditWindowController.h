//
//  MGSEditWindowController.h
//  Mother
//
//  Created by Jonathan on 14/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSToolbarController.h"
#import "MGSNetRequest.h"
#import "MGSTaskExecuteWindowController.h"
#import "MGSMotherModes.h"
#import "MGSEditWindow.h"
#import "MGSResourceBrowserSheetController.h"

enum eMGSScriptHelper {
    kMGSScriptHelperNone = 0,
    kMGSScriptHelperTemplateBrowser = 1,
    kMGSScriptHelperCodeAssistant = 2,
};
typedef NSInteger MGSScriptHelper;

@class MGSEditWindowController;
@class MGSTaskSpecifier;
@class MGSToolbarController;
@class MGSActionEditViewController;
@class MGSScriptEditViewController;
@class MGSRequestViewController;
@class MGSSaveActionSheetController;
@class MGSError;
@class MGSRequestTabScrollView;
@class MGSCodeAssistantSheetController;

@protocol MGSEditWindowDelegate
@required
- (void)editWindowWillClose:(MGSEditWindowController *)editWindowController;
@optional
- (void)shiftLeftAction:(id)sender;
@end

@interface MGSEditWindowController : MGSTaskExecuteWindowController <MGSToolbarDelegate, NSWindowDelegate, MGSEditNSWindowDelegate> {
	IBOutlet NSTabView *tabView;					// main tab view
	IBOutlet NSImageView *scriptStatusImageView;	// script compilation status image
	IBOutlet NSTextField *statusTextField;			// status text field
	IBOutlet NSTextField *actionUUIDTextField;		// action UUID text field
	
	MGSActionEditViewController *actionEditViewController;
	MGSScriptEditViewController *scriptEditViewController;
	MGSResourceBrowserSheetController *resourceSheetController;
	IBOutlet    MGSRequestTabScrollView *requestTabScrollView;

	MGSTaskSpecifier *_taskSpec;
	MGSSaveActionSheetController *_saveActionSheetController;
    MGSCodeAssistantSheetController *codeAssistantSheetController;
    NSTextCheckingResult *taskInputsPatternMatch;
    NSRegularExpression *taskInputsPatternRegex;
    
	BOOL _closeWindowAfterSave;
	BOOL _silentClose;
	eMGSMotherEditMode _editMode;
}

@property (assign) MGSTaskSpecifier *taskSpec;

- (IBAction)viewMenuEditModeSelected:(id)sender;
- (IBAction)showTemplateBrowserSheet:(id)sender;
- (IBAction)showCodeAssistantSheet:(id)sender;

- (void)setDelegate:(id <MGSEditWindowDelegate>) object;
- (BOOL)commitPendingEdits;
- (void)askToSave:(SEL)callback;
- (void)prepareForSave;
- (void)updateWindowTitle;
- (IBAction)compileDocumentScript:(id)sender;
- (IBAction)buildAndRunDocumentScript:(id)sender;
- (void)closeWindowSilently;
@end
