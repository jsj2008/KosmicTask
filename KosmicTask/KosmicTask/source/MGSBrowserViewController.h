//
//  MGSBrowseViewController.h
//  Mother
//
//  Created by Jonathan on 24/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetRequest.h"
#import "MGSNetClientManager.h"

@class MGSNetClientManager;
@class MGSNetClient;
@class MGSRequestViewController;
@class MGSBrowserViewController;
@class MGSTaskSpecifier;
@class AMProgressIndicatorTableColumnController;
@class MGSBrowserSplitView;
@class MGSSaveConfigurationWindowController;
@class MGSActionDeleteWindowController;
@class MGSImageCollectionWindowController;

@protocol MGSBrowserViewControllerDelegate
@required
- (void)browserStartupTimerExpired:(MGSBrowserViewController *)browser;
- (void)browserViewChanged:(MGSBrowserViewController *)browser;
- (void)browser:(MGSBrowserViewController *)browser userSelectedAction:(MGSTaskSpecifier *)action;
- (void)browserExecuteSelectedAction:(MGSBrowserViewController *)browser;
- (void)browser:(MGSBrowserViewController *)browser clientAvailable:(MGSNetClient *)netClient;
- (void)browser:(MGSBrowserViewController *)browser clientUnvailable:(MGSNetClient *)netClient;
- (void)browser:(MGSBrowserViewController *)browser groupStatus:(NSString *)status;
@end

@interface MGSBrowserViewController : NSViewController 
	<MGSNetRequestOwner, MGSNetClientManagerDelegate, NSSplitViewDelegate>  {
	MGSNetClientManager *_netClientHandler;
	IBOutlet NSTableView *machineTable;
	IBOutlet NSTableView *groupTable;
	IBOutlet NSTableView *actionTable;
	//IBOutlet NSTextField *machineTableCaption;
	//IBOutlet NSTextField *groupTableCaption;
	//IBOutlet NSTextField *actionTableCaption;
	IBOutlet MGSBrowserSplitView *splitView;
	IBOutlet NSView *groupEditBar;
	IBOutlet NSView *actionEditBar;
	IBOutlet NSScrollView *actionScrollView;
	IBOutlet NSScrollView *groupScrollView;
		
	NSView *_browserView;
	IBOutlet NSView *_sharingView;
	id _delegate;
	NSInteger _viewEffect;		   // effect to use when showing views
	BOOL _showActionInNewTab;
	AMProgressIndicatorTableColumnController *_progressColumnController;
	BOOL _allowActionDispatch;
	//NSInteger _runMode;
	BOOL _nibLoaded;
	NSTimer *_startupTimer;
	NSTimer *_LMTimer;
	NSMutableDictionary *_clientStore;
	IBOutlet MGSImageCollectionWindowController *_imageCollectionWindowController;
	NSView *_computerListView;
	BOOL _postNetClientSelectionNotifications;
}

- (IBAction)handleTableCheckClick: (id)sender;
- (IBAction)selectGroupIcon:(id)sender;
- (IBAction)changeTaskLabelColour:(id)sender;
- (IBAction)changeTaskRatingIndex:(id)sender;
- (IBAction)openTaskInNewTab:(id)sender;
- (IBAction)openTaskInNewWindow:(id)sender;
//
- (void)showPathToAction:(MGSTaskSpecifier *)action;	// show path to the action
- (CGFloat)minViewHeight;

// accessors
- (MGSNetClient *)selectedClient;										// currently selected client
- (MGSTaskSpecifier *)selectedAction;									// currently selected action
- (id <MGSBrowserViewControllerDelegate>)delegate;						// delegate
- (void)setDelegate:(id <MGSBrowserViewControllerDelegate>)delegate;	// delegate

- (void)savePreferences;
- (void)retrievePreferences;

- (void)deleteSelectedAction;
- (void)startupTimerExpired:(NSTimer*)theTimer;
- (void)setSelectedActionSchedulePublished:(BOOL)aBool;

@property NSTableView *machineTable;
@property (readonly) NSInteger viewEffect;
@property (readonly) NSView *sharingView;
@end

@interface MGSBrowserViewController (NetControllerDelegate)

-(void)netControllerServiceFound:(MGSNetClient *)sender;
-(void)netControllerServiceRemoved:(MGSNetClientManager *)sender;

@end

