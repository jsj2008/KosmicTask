//
//  MGSMotherWindowController.h
//  Mother
//
//  Created by Jonathan on 24/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSEditWindowController.h"
#import "MGSActionWindowController.h"
#import "MGSResultWindowController.h"
#import "MGSToolbarController.h"
#import "MGSNetRequest.h"
#import "MGSActionExecuteWindowController.h"
#import "MGSMotherModes.h"
#import "MGSActionDeleteWindowController.h"

@class MGSSidebarViewController;
@class MGSToolbarController;
@class MGSMainViewController;
@class MGSNetClient;
@class MGSActionDeleteWindowController;
@class MGSWaitViewController;

@interface MGSMotherWindowController : MGSActionExecuteWindowController <MGSEditWindowDelegate, 
															MGSActionWindowDelegate, 
															MGSResultWindow, 
															MGSToolbarDelegate, 
															MGSNetRequestOwner,
															NSSplitViewDelegate,
															MGSActionDeleteWindowControllerDelegate
															>  {
	IBOutlet NSSplitView *windowSplitView;	// top level splitview
	IBOutlet NSView *windowLeftView;
	IBOutlet NSView *windowMainView;
	NSView *_contentSubview;
	
	IBOutlet MGSMainViewController *mainViewController;
	
	IBOutlet NSView *leftView;	// the left sidebar splitview
	IBOutlet NSSplitView *leftSplitView;	// the left sidebar splitview
	IBOutlet NSView *leftTopView;
	IBOutlet NSView *leftBottomView;

	IBOutlet MGSToolbarController *_toolbarController;
	IBOutlet NSButton *_feedbackButton;
																
	MGSSidebarViewController *_sidebarViewController;
	MGSWaitViewController *_waitViewController;

	
	NSView *current;
	eMGSMotherRunMode _runMode;
	NSMutableArray *_editWindowControllers;
	NSMutableArray *_actionWindowControllers;
	NSMutableArray *_resultWindowControllers;
	NSMutableDictionary *_actionsPendingEdit;
	BOOL _suppressApplicationTaskEditAlertSheet;
	MGSActionDeleteWindowController *_deleteController;
	NSView *_dummyView;															
}


@property eMGSMotherRunMode runMode;

- (IBAction)addServer:(id)sender;
- (IBAction)removeServer:(id)sender;
- (NSArray *)editWindowControllers;
- (NSArray *)editWindowControllersForNetClient:(MGSNetClient *)netClient;
- (IBAction)deleteDocument:(id)sender;
- (IBAction)duplicateDocument:(id)sender;
- (IBAction)publishDocument:(id)sender;
- (IBAction)unpublishDocument:(id)sender;
- (void)closeEditWindowsSilentlyForNetClient:(MGSNetClient *)netClient;
- (BOOL)sidebarViewIsHidden;
- (NSInteger )taskTabCount;

// task actions
- (IBAction)addNewTaskTab:(id)sender;
- (IBAction)closeTaskTab:(id)sender;
- (IBAction)findTask:(id)sender;
- (IBAction)selectNextTaskTab:(id)sender;
- (IBAction)selectPrevTaskTab:(id)sender;

// menu actions
- (IBAction)viewMenuShowSelected:(id)sender;

@end
