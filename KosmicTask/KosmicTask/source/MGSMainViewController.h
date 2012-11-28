//
//  MGSMainViewController.h
//  Mother
//
//  Created by Jonathan on 08/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSBrowserViewController.h"
#import "MGSMotherModes.h"

#define TASK_DETAIL_CLOSE_SEGMENT_INDEX 0
#define TASK_DETAIL_HISTORY_SEGMENT_INDEX 1
#define TASK_DETAIL_SCRIPT_SEGMENT_INDEX 2
#define DETAIL_MIN_SEGMENT_INDEX TASK_DETAIL_CLOSE_SEGMENT_INDEX
#define DETAIL_MAX_SEGMENT_INDEX TASK_DETAIL_SCRIPT_SEGMENT_INDEX

@class MGSRequestViewController;
@class MGSWaitViewController;
@class MGSMainSplitview;
@class MGSHistoryViewController;
@class MGSRequestTabViewController;
@class MGSScriptViewController;
@class MGSTaskSearchViewController;
@class MGSTaskSharingViewController;
@class MGSBrowserViewControlStrip;
@class MGSNetClient;
@class MGSResultViewController;

@interface MGSMainViewController : NSViewController <MGSBrowserViewControllerDelegate, NSSplitViewDelegate> {
	
	IBOutlet MGSMainSplitview *mainSplitView;	// 3 panel subview where all the action occurs
	IBOutlet NSView *mainTopView;
	IBOutlet NSView *mainMiddleView;
	IBOutlet NSView *mainBottomView;	
	IBOutlet NSTextField *statusBarLabel;		// status label below splitview
	IBOutlet NSTabView *detailTabView;			// detail tabview shows history, script etc depending on context
	IBOutlet NSTabView *browserTabView;			// browser tabview shows tasks, search and sharing
	IBOutlet NSButton *internetSharingButton;
	IBOutlet NSButton *localSharingButton;
    IBOutlet NSImageView *portStatusImageView;
	IBOutlet MGSBrowserViewControlStrip *_browserViewControlStrip;
	IBOutlet NSSegmentedControl *detailSegmentedControl;
	IBOutlet NSSegmentedControl *browserSegmentedControl;
	
	MGSBrowserViewController *_browserViewController;
	MGSTaskSearchViewController *_searchViewController;
	MGSHistoryViewController *_historyViewController;
	MGSRequestTabViewController *_requestTabViewController;	
	MGSScriptViewController *_scriptViewController;
	
	NSView *_currentSubview;
	BOOL _detailSegmentHidden;
	MGSNetClient *_netClient;
	NSInteger _detailSegmentToSelectWhenNotHidden;
	//NSInteger _detailPrevClickedSegment;
	bool _detailViewVisible;
	
	MGSTaskSpecifier *_selectedTabViewAction;
	NSInteger _scriptVersionID;
	NSView *_dummyView;
    BOOL netClientIsChanging;
}

@property (readonly) MGSBrowserViewController *browserViewController;
@property (readonly) MGSScriptViewController *scriptViewController;
@property MGSNetClient *netClient;
@property (readonly) MGSRequestTabViewController *tabViewController;
@property (readonly) BOOL netClientIsChanging;

- (void)windowClosing;
- (IBAction)detailSegControlClicked:(id)sender;
- (void)setRunMode:(eMGSMotherRunMode)mode;
- (MGSTaskSpecifier *)selectedTabMotherAction;
- (MGSResultViewController *)selectedTabResultViewController;
- (IBAction)addNewTaskTab:(id)sender;
- (IBAction)closeTaskTab:(id)sender;
- (void)showSearchView;

- (BOOL)browserViewIsHidden;
- (BOOL)detailViewIsHidden;

- (void)loadUserDefaults;
- (void)saveUserDefaults;
- (void)configureView;

@end
