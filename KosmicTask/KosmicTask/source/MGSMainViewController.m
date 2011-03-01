//
//  MGSMainViewController.m
//  Mother
//
//  Created by Jonathan on 08/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSMainViewController.h"
#import "MGSClientRequestManager.h"
#import "MGSWaitViewController.h"
#import "MGSHistoryViewController.h"
#import "NSSplitView_Mugginsoft.h"
#import "MGSMainSplitview.h"
#import "MGSWaitView.h"
#import "MGSRequestTabViewController.h"
#import "MGSTaskSpecifier.h"
#import "NSSplitView_Mugginsoft.h"
#import "NSView_Mugginsoft.h"
#import "MGSNotifications.h"
#import "MGSScriptViewController.h"
#import "MGSNetClient.h"
#import "MGSAppController.h"
#import "MGSConnectingWindowController.h"
#import "NSViewController_Mugginsoft.h"
#import "MGSPrefsWindowController.h"
#import "MGSInternetSharing.h"
#import "MGSInternetSharingClient.h"
#import "MGSTaskSearchViewController.h"
#import "MGSBrowserViewControlStrip.h"
#import "MGSScript.h"
#import "MGSClientScriptManager.h"
#import "MGSClientTaskController.h"
#import "MGSRequestViewController.h"
#import "MGSOutputRequestViewController.h"
#import "MGSResultViewController.h"
#import "MGSPreferences.h"

const char MGSNetClientRunModeContext;

// browser tab
#define TAB_TASKS 0
#define TAB_SEARCH 1
#define TAB_SHARING 2

// detail tab
#define TAB_HISTORY 0
#define TAB_SCRIPT 1

static char MGSSeletedDetailViewSegmentContext;

// class extension
@interface MGSMainViewController()
- (void)viewConfigDidChange:(NSNotification *)notification;
- (void)viewConfigChangeRequest:(NSNotification *)notification;
- (void)netClientSelected:(NSNotification *)notification;
- (void)executeSelectedAction:(NSNotification *)notification;
- (void)terminateSelectedAction:(NSNotification *)notification;
- (void)suspendSelectedAction:(NSNotification *)notification;
- (void)resumeSelectedAction:(NSNotification *)notification;
- (void)selectDetailSegment:(NSInteger)idx;
- (void)saveUserDefaults;
@end

@interface MGSMainViewController(private)
- (void)historyViewChanged:(MGSHistoryViewController *)aHistory;
- (void)selectAction:(MGSTaskSpecifier *)action;
@end


@implementation MGSMainViewController

@synthesize browserViewController = _browserViewController;
@synthesize scriptViewController = _scriptViewController;
@synthesize netClient = _netClient;
@synthesize tabViewController = _requestTabViewController;

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	_scriptVersionID = 0;
	_detailSegmentToSelectWhenNotHidden = TASK_DETAIL_HISTORY_SEGMENT_INDEX;
	_detailViewVisible = YES;
	
	// indent text
	[[statusBarLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];

	// register for notifications
	// note that view -window will be nil so it will be pointless to assign it to object 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewConfigChangeRequest:) name:MGSNoteViewConfigChangeRequest object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewConfigDidChange:) name:MGSNoteViewConfigDidChange object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientSelected:) name:MGSNoteClientSelected object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(executeSelectedAction:) name:MGSNoteExecuteSelectedTask object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSelectedAction:) name:MGSNoteStopSelectedTask object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(suspendSelectedAction:) name:MGSNoteSuspendSelectedTask object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeSelectedAction:) name:MGSNoteResumeSelectedTask object:nil];

	// set the browser tab style
	[browserTabView setTabViewType:NSNoTabsNoBorder];
	
	// set the detail tab style
	[detailTabView setTabViewType:NSNoTabsNoBorder];
	mainBottomView = detailTabView;
	
	//
	// load the main view (3 vertical views)
	//
	// load the browser view controller
	_browserViewController = [[MGSBrowserViewController alloc] initWithNibName:@"BrowserView" bundle:nil];
	[_browserViewController setDelegate:self]; 

	// swap browser tab view into splitview
	[browserTabView setFrameSize: [mainBottomView bounds].size];	// make subview same size as middle view
	[mainSplitView replaceTopView:browserTabView];
	mainTopView = browserTabView;
		
	// load search view
	_searchViewController = [[MGSTaskSearchViewController alloc] initWithNibName:@"TaskSearchView" bundle:nil];
	[_searchViewController setDelegate:self];
	
	// load browser tab views
	
	// add browser view to tabview item 0
	NSTabViewItem *tabItem = [browserTabView tabViewItemAtIndex:TAB_TASKS];
	[tabItem setView:[_browserViewController view]];
	[browserTabView selectTabViewItem:tabItem];
			
	// add search browser view to tabview item 1
	tabItem = [browserTabView tabViewItemAtIndex:TAB_SEARCH];
	[tabItem setView:[_searchViewController view]];
	
	// add sharing browser view to tabview item 2
	tabItem = [browserTabView tabViewItemAtIndex:TAB_SHARING];
	[tabItem setView:[_browserViewController sharingView]];
	
	// enable the browser segmented control
	[browserSegmentedControl setEnabled:YES];

	// load the request tabview controller 
	// note that awakeFromNib may not have been called by the time the allocated object 
	// returns - so watch out for this else where.
	// In this instance a call to [_requestTabViewController addDefaultTabs] fails because 
	// the nib initialisation has not completed and the tabView is still nil!
	//
	// note that loading other nibs in awake from nib is not recommended
	//
	_requestTabViewController = [[MGSRequestTabViewController alloc] initWithNibName:@"RequestTabView" bundle:nil];
	[_requestTabViewController setDelegate:self];

	// load the view into request tabview controller
	NSView *newView = [_requestTabViewController view];
	[mainSplitView replaceMiddleView:newView];
	[mainSplitView setDelegate:self];
	mainMiddleView = newView;
	_currentSubview = mainSplitView;
	
	// load the scriptview controller
	_scriptViewController = [[MGSScriptViewController alloc] init];
	[_scriptViewController setDelegate:self];

	// load the history view controller 
	_historyViewController = [[MGSHistoryViewController alloc] initWithNibName:@"HistoryView" bundle:nil];
	[_historyViewController setDelegate:self];
	[_historyViewController view];
	[self historyViewChanged:_historyViewController];	// load the history view
	
	// bind
	[internetSharingButton bind:NSImageBinding toObject:[MGSInternetSharingClient sharedInstance] withKeyPath:@"statusImage" options:nil];

	// load user defaults
	[self loadUserDefaults];
	
	// add observers
	[detailSegmentedControl addObserver:self forKeyPath:@"selectedSegment" options:0 context:&MGSSeletedDetailViewSegmentContext];
	
}


/*
 
 script view controller delegate
 
 */
- (void)scriptViewLoaded:(MGSScriptViewController *)scriptViewController
{
	#pragma unused(scriptViewController)
	
	[_scriptViewController setEditable:NO];
}

/*
 
 action specifier for selected tab
 
 */
- (MGSTaskSpecifier *)selectedTabMotherAction
{
	return [_requestTabViewController actionSpecifierForSelectedTab];
}

/*
 
 selected result view controller
 
 */
- (MGSResultViewController *)selectedTabResultViewController
{
	
	return [_requestTabViewController selectedRequestViewController].outputViewController.resultViewController; 
}

#pragma mark -
#pragma mark Detail segment handling
/*
 
 - selectDetailSegment:
 
 select segment and send action to target
 
 */
- (void)selectDetailSegment:(NSInteger)idx
{
	NSAssert(idx >= DETAIL_MIN_SEGMENT_INDEX && idx <= DETAIL_MAX_SEGMENT_INDEX, @"invalid index");
	
	[detailSegmentedControl setSelectedSegment:idx];
	[NSApp sendAction:[detailSegmentedControl action] to:[detailSegmentedControl target] from:detailSegmentedControl];
}

/*
 
 detail segment control clicked
 
 */
- (IBAction)detailSegControlClicked:(id)sender
{
	eMGSViewState viewState = NSNotFound;
	
	int clickedSegment = [sender selectedSegment];
	
	// ensure that the detail view is hidden or visible as required
	switch (clickedSegment) {
			
			// hide detail view
		case TASK_DETAIL_CLOSE_SEGMENT_INDEX:
			if (_detailViewVisible == NO) return;
			viewState = kMGSViewStateHide;
			break;
			
			
			// any other segment
		default:
			if (_detailViewVisible == NO) {
				viewState = kMGSViewStateShow;
			} 
			_detailSegmentToSelectWhenNotHidden = clickedSegment;
			break;
			
	}

	// save default
	[[NSUserDefaults standardUserDefaults] setInteger:clickedSegment forKey:MGSTaskDetailMode];

	// process selection click
	NSInteger idx = TAB_HISTORY; 
	if (clickedSegment != TASK_DETAIL_CLOSE_SEGMENT_INDEX) {
		
		switch (clickedSegment) {
				
			case TASK_DETAIL_HISTORY_SEGMENT_INDEX:
				idx = TAB_HISTORY;
				break;
				
			case TASK_DETAIL_SCRIPT_SEGMENT_INDEX:
				idx = TAB_SCRIPT;
				break;
				
			default:
				NSAssert(NO, @"bad segment");
				break;
				
		}
		[detailTabView selectTabViewItemAtIndex:idx];
	}
	
	// post view mode changed notification
	if (viewState != NSNotFound) {
		
		_detailViewVisible = viewState == kMGSViewStateShow ? YES : NO;
		
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInteger:kMGSMotherViewConfigDetail], MGSNoteViewConfigKey ,
							  [NSNumber numberWithInteger:viewState], MGSNoteViewStateKey ,
							  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:self userInfo:dict];
	}
}

#pragma mark -
#pragma mark Tab handling
/*
 
 create new task tab
 
 */
- (IBAction)addNewTaskTab:(id)sender
{
	[_requestTabViewController addCopyOfSelectedTab:sender];
}

/*
 
 close task tab
 
 */
- (IBAction)closeTaskTab:(id)sender
{
	[_requestTabViewController closeSelectedTab:sender];
}
#pragma mark -
#pragma mark View handling

/*
 
 browser view is hidden
 
 */
- (BOOL)browserViewIsHidden
{
	// browser view is visible if it is part of splitview and splitview is displayed
	return !(_currentSubview == mainSplitView && [browserTabView isDescendantOf:mainSplitView]);
}

/*
 
 detail view is hidden
 
 */
- (BOOL)detailViewIsHidden
{
	// detail view is visible if it is part of splitview and splitview is displayed
	return !(_currentSubview == mainSplitView && [detailTabView isDescendantOf:mainSplitView]);
}
#pragma mark -
#pragma mark Search handling

/*
 
 show search view
 
 */
- (void)showSearchView 
{
	[_browserViewControlStrip selectSegment:BROWSER_SEARCH_SEGMENT_INDEX];
}
#pragma mark -
#pragma mark - notifications

/*
 
 execute selected action
 
 */
- (void)executeSelectedAction:(NSNotification *)notification
{	
	if (![self notificationObjectIsWindow:notification]) return;
	
	[_requestTabViewController executeSelectedAction];
}

/*
 
 terminate execution of selected action
 
 */
- (void)terminateSelectedAction:(NSNotification *)notification
{		
	if (![self notificationObjectIsWindow:notification]) return;
	
	[_requestTabViewController terminateSelectedAction];
}

/*
 
 suspend execution of selected action
 
 */
- (void)suspendSelectedAction:(NSNotification *)notification
{		
	if (![self notificationObjectIsWindow:notification]) return;
	
	[_requestTabViewController suspendSelectedAction];
}

/*
 
 suspend execution of selected action
 
 */
- (void)resumeSelectedAction:(NSNotification *)notification
{		
	if (![self notificationObjectIsWindow:notification]) return;
	
	[_requestTabViewController resumeSelectedAction];
}

/*
 
 net client selected in browser
 
 */
- (void)netClientSelected:(NSNotification *)notification
{	
	MGSNetClient *netClient = [[notification userInfo] objectForKey:MGSNoteNetClientKey];
	self.netClient = netClient;
}

/*
 
 set net client
 
 */
- (void)setNetClient:(MGSNetClient *)netClient
{
	// remove observers
	if (self.netClient) {
		@try {
			[self.netClient removeObserver:self forKeyPath:MGSNetClientKeyPathRunMode];		
		} 
		@catch (NSException *e)
		{
			MLog(RELEASELOG, @"%@", [e reason]);
		}
	}
	
	_netClient = netClient;
	
	// add observer
	[self.netClient addObserver:self forKeyPath:MGSNetClientKeyPathRunMode options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:(void *)&MGSNetClientRunModeContext];
}

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &MGSNetClientRunModeContext) {
		
		// run mode changed
		NSInteger runMode = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
		
		// update view state to match client runmode
		[self setRunMode:runMode];

	} else if (context == &MGSSeletedDetailViewSegmentContext) {
	
		/*
		NSSegmentedControl *segControl = object;
		NSString *imageName = @"ToggleViewTemplate";
		if ([segControl selectedSegment] == TASK_DETAIL_CLOSE_SEGMENT_INDEX) {
			imageName = @"ToggleViewTemplateUp";
		} 
		NSImage *image = [NSImage imageNamed:imageName];
		[segControl setImage:image forSegment:TASK_DETAIL_CLOSE_SEGMENT_INDEX];
		 */
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

/*
 
 set run mode
 
 */
- (void)setRunMode:(eMGSMotherRunMode)mode
{
	//int indexTab
	
	switch (mode) {
			
			// show history tab in run mode
		case kMGSMotherRunModePublic:
			//indexTab = TAB_HISTORY;
			//indexDetailSegment = TASK_DETAIL_HISTORY_SEGMENT_INDEX;
			_detailSegmentHidden = YES;
			break; 
			
		case kMGSMotherRunModeAuthenticatedUser:
			//indexTab = TAB_HISTORY;
			//indexDetailSegment = TASK_DETAIL_HISTORY_SEGMENT_INDEX;
			_detailSegmentHidden = NO;
			break; 
			
			// show script tab in edit mode
		case kMGSMotherRunModeConfigure:
			//indexTab = TAB_SCRIPT;
			//indexDetailSegment = TASK_DETAIL_SCRIPT_SEGMENT_INDEX;
			_detailSegmentHidden = YES;
			break;
			
		default:
			NSAssert(NO, @"invalid edit mode");
			break;
	}
	
	//[detailSegmentedControl setSelectedSegment:indexDetailSegment];
	//[detailTabView selectTabViewItemAtIndex:indexTab];
	
	// script view will retrieve scripts in edit mode
	[_scriptViewController setEditMode:mode];
	
	//[self updateDetailSegmentedControlVisibility];
}

/*
 
 application subview change request
 
 */
- (void)viewConfigChangeRequest:(NSNotification *)notification
{ 
	// get view id
    NSNumber *number = [[notification userInfo] objectForKey:MGSNoteViewConfigKey];
	if (!number) return;
	eMGSMotherViewConfig mode = [number integerValue];

	// get view state
	eMGSViewState viewState = kMGSViewStateToggleVisibility;
	number = [[notification userInfo] objectForKey:MGSNoteViewStateKey];
	if (number) {
		viewState = [number integerValue];
	}
	
	int toggleViewPosition;
	int subViewCount = [[mainSplitView subviews] count];
	NSWindowOrderingMode orderMode;
	
	// two of our views can be toggled on and off
	NSView *toggleView = nil;
	NSView *otherToggleView = nil;
	switch (mode) {
			
		// toggle the browser visibility
		case kMGSMotherViewConfigBrowser:
			toggleView = browserTabView;
			otherToggleView = detailTabView;
			toggleViewPosition = 0;
			orderMode = NSWindowBelow;
			break;
			
		// toggle the detail visibility
		case kMGSMotherViewConfigDetail:
			toggleView = detailTabView;
			otherToggleView = browserTabView;
			toggleViewPosition = [[mainSplitView subviews] count] - 1;
			orderMode = NSWindowAbove;
			break;
		
		default:
			return;
	}
	
	BOOL isToggleViewInSplitView = [toggleView isDescendantOf:mainSplitView];
										
	// toggle the subview visibility.
	// all this view siwtching is overly complex.
	// a MUCH simpler approach would have been to use collapsible splitviews
	// (simply set the collapsed pane to a placeholder view with an NSZeroRect frame)
	if (_currentSubview == mainSplitView) {
		
		// if view in splitview then remove it
		if (isToggleViewInSplitView == YES) {
			
			NSView *tabView = [_requestTabViewController view];
			
			// must have at least two views in splitview.
			// if want to display a single view from the splitview
			// then have to replace the splitview
			if (2 == subViewCount) {
				_dummyView = [[NSView alloc] initWithFrame:[tabView frame]];
				
				// swap out the tabview from the splitview and replace the splitview with the tabview
				[mainSplitView replaceSubview:tabView with:_dummyView];
				[tabView setFrame:[mainSplitView frame]];
				[[self view] replaceSubview:mainSplitView with:tabView];
				
				_currentSubview = tabView;
			} else {
				// remove our target toggleView.
				// - (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize will be sent
				// and the subviews resized accordingly
				[toggleView removeFromSuperview];
			}
		} else {
			[mainSplitView addSubview:toggleView positioned:orderMode relativeTo:[[mainSplitView subviews] objectAtIndex:toggleViewPosition]];
		}
	} else {

		// if the current view is not the splitview then swap it in
		if (_currentSubview != mainSplitView) {
			[[self view] replaceSubview:_currentSubview with:mainSplitView];
			[mainSplitView setFrame:[_currentSubview frame]];
			[mainSplitView replaceSubview:_dummyView with:_currentSubview];
			_currentSubview = mainSplitView;
			_dummyView = nil;
		}
		
		// if our toggleview is not in the splitview then add it
		if (!isToggleViewInSplitView) {
			[mainSplitView addSubview:toggleView positioned:orderMode relativeTo:[[mainSplitView subviews] objectAtIndex:toggleViewPosition]];
			
			// the other toggle view must triggered the swapping out of the splitview so remove it
			[otherToggleView removeFromSuperview];
		}
	}
	
	switch (mode) {
			
			// toggle the browser visibility
		case kMGSMotherViewConfigBrowser:
			 
			break;
			
			// toggle the detail visibility
		case kMGSMotherViewConfigDetail:
			break;
			
		default:
			return;
	}
	
	
	// send out completed change notification.
	// this is quite cumbersome: send out a change request note and receive a did change note.
	// seems like the only way to ensure sync endures as the request is allowed to fail.
	// actually, this is over engineered as the controllers observing this notification are available locally.
	// using the responder chain could have achieved all of this much more simply
	//
	// anyhow, as long as this pattern is followed consistently it should prove maintainable
	// even if not optimal
	//
	NSNotification *noteDone = [NSNotification notificationWithName:MGSNoteViewConfigDidChange 
												object:[[self view] window]
												userInfo:[notification userInfo]];
	[[NSNotificationCenter defaultCenter] postNotification:noteDone];
}


/*
 
 view config did change 
 
 */
- (void)viewConfigDidChange:(NSNotification *)notification
{
	// view config
	NSNumber *number = [[notification userInfo] objectForKey:MGSNoteViewConfigKey];
	if (!number) return;
	eMGSMotherViewConfig viewConfig = [number integerValue];

	// view state
	number = [[notification userInfo] objectForKey:MGSNoteViewStateKey];
	if (!number) return;
	eMGSViewState viewState = [number integerValue];

	int idx = -1;

	// we may post a change view notification in which case our segmented button state is okay.
	// if another object posts the notification however we have to sync our button to the requested view state.
	switch (viewConfig) {
			
		case kMGSMotherViewConfigDetail:;
			switch (viewState) {
				case kMGSViewStateShow:
					idx = _detailSegmentToSelectWhenNotHidden;
					_detailViewVisible = YES;
					break;
					
				case kMGSViewStateHide:
					idx = TASK_DETAIL_CLOSE_SEGMENT_INDEX;
					_detailViewVisible = NO;
					break;
					
				default:
					return;
			}
			[detailSegmentedControl setSelectedSegment:idx];
			
			break;
			
		default:
			break;
			
	}
}

#pragma mark -
#pragma mark MGSScopeBarViewController delegate methods


#pragma mark -
#pragma mark NSSplitView delegate methods

//
// size splitview subviews as required
//
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize
{	
	MGSSplitviewBehaviour behaviour = MGSSplitviewBehaviourNone;
	NSArray  *minHeightArray = nil;
	
	// note that a view does not provide a -setTag method only -tag
	// so views cannot be easily tagged without subclassing.
	// NSControl implements -setTag;
	//
	if ([sender isEqual:mainSplitView]) {
		switch ([[sender subviews] count]) {
			case 2:
				// NSSplitView subviews contain the views we are interested in
				if ([browserTabView isDescendantOf:[[sender subviews] objectAtIndex:0]]) {
					// subview 0 contains browser
					// subview 1 contains request view
					minHeightArray = [NSArray arrayWithObjects: [NSNumber numberWithDouble:[_browserViewController minViewHeight]], [NSNumber numberWithDouble:[_requestTabViewController minViewHeight]], nil];
					behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;

				} else {
					
					// subview 0 contains request view
					// subview 1 contains history
					behaviour = MGSSplitviewBehaviourOf2ViewsSecondFixed;
					minHeightArray = [NSArray arrayWithObjects: [NSNumber numberWithDouble:[_requestTabViewController minViewHeight]], [NSNumber numberWithDouble:[_historyViewController minViewHeight]], nil];
				}
				break;
				
			case 3:;
				
				// subview 0 is browser
				// subview 1 is request view
				// subview 2 is history
				behaviour = MGSSplitviewBehaviourOf3ViewsFirstAndThirdFixed;
				minHeightArray = [NSArray arrayWithObjects:[NSNumber numberWithDouble:[_browserViewController minViewHeight]], [NSNumber numberWithDouble:[_requestTabViewController minViewHeight]], [NSNumber numberWithDouble:[_historyViewController minViewHeight]], nil];
				break;
				
			default:
				NSAssert(NO, @"invalid splitview count");
		}
	}  else {
		NSAssert(NO, @"invalid splitview");
	}
	
	// see the NSSplitView_Mugginsoft category
	if (behaviour != MGSSplitviewBehaviourNone) {
		[sender resizeSubviewsWithOldSize:oldSize withBehaviour:behaviour minSizes:minHeightArray];
	}
}
/*
 
 splitview constrain max position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{	
	if ([sender isEqual:mainSplitView]) {
		switch ([[sender subviews] count]) {
			case 2:
				if ([browserTabView isDescendantOf:[[sender subviews] objectAtIndex:offset]]) {
					proposedMax = [sender frame].size.height - [_requestTabViewController minViewHeight] - [sender dividerThickness];
				} else {
					proposedMax = [sender frame].size.height - [_historyViewController minViewHeight] - [sender dividerThickness];
				}
				break;
				
				// browser above, request view below
			case 3:
				switch  (offset) {
						
					case 0:
						proposedMax = [sender frame].size.height - [[_historyViewController view] frame].size.height - [sender dividerThickness] - [_requestTabViewController minViewHeight];
						break;
					case 1:
						proposedMax = [sender frame].size.height - [_historyViewController minViewHeight] - [sender dividerThickness] ;
						break;
					default:
						NSAssert(NO, @"invalid offset");
						break;
						
				}
				break;
				
			default:
				NSAssert(NO, @"invalid splitview count");
				break;
		}
	}  else {
		NSAssert(NO, @"invalid splitview");
	}
	
	return proposedMax;
}
/*
 
 splitview constrain min position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	if ([sender isEqual:mainSplitView]) {
		switch ([[sender subviews] count]) {
			case 2:
				if ([browserTabView isDescendantOf:[[sender subviews] objectAtIndex:offset]]) {
					proposedMin = [_browserViewController minViewHeight];
				} else {
					proposedMin = [_requestTabViewController minViewHeight];
				}
				break;
				
				// browser above, request view below
			case 3:
				switch  (offset) {
						
					case 0:
						proposedMin = [_browserViewController minViewHeight];
						break;
					case 1:
						proposedMin = [browserTabView frame].size.height + [sender dividerThickness]  + [_requestTabViewController minViewHeight];
						break;
					default:
						NSAssert(NO, @"invalid offset");
						break;
						
				}
				break;
				
			default:
				NSAssert(NO, @"invalid splitview count");
				break;
		}
	}  else {
		NSAssert(NO, @"invalid splitview");
	}
	
	return proposedMin;
}
/*
 
 splitview constrain split position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset
{
	#pragma unused(sender)
	#pragma unused(offset)
	
	return proposedPosition;
}

#pragma mark -
#pragma mark browser view delegate methods

/*
 
 browser client available
 
 */
- (void)browser:(MGSBrowserViewController *)browser clientAvailable:(MGSNetClient *)netClient
{
	#pragma unused(browser)
	// post client available notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteClientAvailable object:netClient];
}

/*
 
 browser client unavailable
 
 */
- (void)browser:(MGSBrowserViewController *)browser clientUnvailable:(MGSNetClient *)netClient
{
	#pragma unused(browser)
	
	// post client unavailable notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteClientUnavailable object:netClient];
}

/*
 
 browser view changed
 
 sent when browser content view changes.
 
 1. initially browser view is a wait view as we wait to connect.
 2. once we connect the wait view is replaced with browser view content proper
 
 */
- (void)browserViewChanged:(MGSBrowserViewController *)aBrowser
{	
	// add browser view to tabview item 0
	NSView *browserView = [aBrowser view];
	NSAssert(browserView,  @"adding nil browser view to browser NSTabView");
	NSTabViewItem *tabItem = [browserTabView tabViewItemAtIndex:TAB_TASKS];
	[tabItem setView:browserView];
	[browserTabView selectTabViewItem:tabItem];
	
	// if not showing the wait view then initialise the tabview subviews
	if (![browserView isKindOfClass:[MGSWaitView class]]) {
		
		// add search browser view to tabview item 1
		NSView *newView = [_searchViewController view];
		NSAssert(newView,  @"adding nil search view to browser NSTabView");
		tabItem = [browserTabView tabViewItemAtIndex:TAB_SEARCH];
		[tabItem setView:newView];
		
		// add sharing browser view to tabview item 2
		newView = [aBrowser sharingView];
		NSAssert(newView,  @"adding nil sharing view to browser NSTabView");
		tabItem = [browserTabView tabViewItemAtIndex:TAB_SHARING];
		[tabItem setView:newView];
		
		// enable the browser segmented control
		[browserSegmentedControl setEnabled:YES];
	}
}


/*
 
 browser startup timer has expired
 
 */
- (void)browserStartupTimerExpired:(MGSBrowserViewController *)browser
{
	#pragma unused(browser)
	
	MGSAppController *appController = [NSApp delegate];
	appController.startupComplete = YES;
}

/*
 
 user selected action in browser
 
 browser view delegate method.
 
 Note that the browser always generates a new MGSTaskSpecifier object for each selection.
 Thus the action parameter object itself will NOT already exist within an existing tab
 of the tabview controller. The tabview controller will use the action parameter to select
 the first acceptable tabview that matches the action parameters properties.
 
 this message is sent whenever a user selects an action spec in the browser
 or whenever a user selection needs to be simulated
 
 */
- (void)browser:(MGSBrowserViewController *)browser userSelectedAction:(MGSTaskSpecifier *)action
{
	#pragma unused(browser)
	
	NSAssert(action, @"action is nil");
	
	// display action accordingly
	switch ([action displayType]) {
			
		// display action in new tab
		case MGSTaskDisplayInNewTab:
			
			// create new tab with action spec
			[_requestTabViewController addTabWithActionSpecifier:action];
			
			[_requestTabViewController applyUserDefaultsToSelectedTab];
			
			break;
			
		// display action in new window
		case MGSTaskDisplayInNewWindow:
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteOpenTaskInWindow object:action];
			return;
			break;
			
		// try and find matching tab for action
		default:
			[_requestTabViewController selectTabForActionSpecifier:action];
			break;
	}
	
}

/*
 
 browser execute selected action
 
 */
- (void)browserExecuteSelectedAction:(MGSBrowserViewController *)browser
{
	#pragma unused(browser)
	
	[_requestTabViewController executeSelectedAction];
}

/*
 
 browser group status
 
 */
- (void)browser:(MGSBrowserViewController *)browser groupStatus:(NSString *)status
{
	#pragma unused(browser)
	
	[statusBarLabel setStringValue:status];
}

#pragma mark -
#pragma mark browser view control strip delegate methods
/*
 
 browser segment control clicked
 
 */
- (void)browserSegControlClicked:(id)sender
{
	int selectedSegment = [sender selectedSegment];
	int idx = TAB_TASKS;
	NSInteger viewMode = kMGSMainBrowseModeHidden;
	
	switch (selectedSegment) {
		case BROWSER_CLOSE_SEGMENT_INDEX:
			return;
			break;
			
		case BROWSER_TASK_SEGMENT_INDEX:
			idx = TAB_TASKS;
			viewMode = kMGSMainBrowseModeTasks;
			break;
			
		case BROWSER_SEARCH_SEGMENT_INDEX:
			idx = TAB_SEARCH;
			viewMode = kMGSMainBrowseModeSearch;
			break;
			
		case BROWSER_SHARING_SEGMENT_INDEX:
			idx = TAB_SHARING;
			viewMode = kMGSMainBrowseModeSharing;
			break;
			
		default:
			NSAssert(NO, @"bad segment");
			return;
			
	}
	
	// show selected view
	[browserTabView selectTabViewItemAtIndex:idx];
	
	// post browser mode changed notification
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:MGSNoteMainBrowserModeChanged 
			object:self
			userInfo: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInteger:viewMode], MGSNoteViewConfigKey, nil]];
	
}

#pragma mark -
#pragma mark task search view delegate methods
/*
 
 task search action selected
 
 */
- (void)taskSearchView:(MGSTaskSearchViewController *)sender actionSelected:(MGSTaskSpecifier *)action
{
	#pragma unused(sender)
	
	[self selectAction:action];
}

#pragma mark -
#pragma mark history view delegate methods
/*
 
 history action selected
 
 */
- (void)history:(MGSHistoryViewController *)history actionSelected:(MGSTaskSpecifier *)action
{
	#pragma unused(history)
	
	[self selectAction:action];
}

/*
 
 history execute selected action
 
 history view delegate
 
 */
- (void)historyExecuteSelectedAction:(MGSHistoryViewController *)history
{
	#pragma unused(history)
	
	[_requestTabViewController executeSelectedAction];
}

#pragma mark -
#pragma mark tabview view delegate methods

/*
 
 tab view action selected
 
 note that this message is sent whenever the selected tab changes
 regardless of whether the change occurred as the result of
 user interaction or a programmatic change
 
 */
- (void)tabViewActionSelected:(MGSTaskSpecifier *)aTaskSpec
{
	// detect action instance change
	BOOL actionInstanceChanged = !(_selectedTabViewAction && _selectedTabViewAction == aTaskSpec);
	
	//
	// detect action path change.
	//
	// indicates that a distinct action has been selected.
	//
	// note that actionInstanceChanged == YES and actionPathChanged == NO 
	// is a valid combination if tabbing between two instances of the same task
	//
	// path will change either if the UUID changes or the net client changes
	//
	BOOL actionPathChanged = !(_selectedTabViewAction && [_selectedTabViewAction isEqualUUID:aTaskSpec]);
	if ([_selectedTabViewAction netClient] != [aTaskSpec netClient]) {
		actionPathChanged = true;
	}
	
	//
	// detect script version ID change
	//
	// version ID changes whenever script is saved.
	//
	BOOL scriptVersionIDChanged = !(_scriptVersionID == [[aTaskSpec script] versionID]);

	// need to sync browser with selected action
	if (actionPathChanged) {
		[_browserViewController showPathToAction:aTaskSpec];
	}
	
	// check if action instance changed 
	// as we may get multiple notifications
	if (actionInstanceChanged) {
	
		_selectedTabViewAction = aTaskSpec;
		_scriptVersionID = [[aTaskSpec script] versionID];		
		
		//
		// post action change notification
		//
		// this notification is crucial to informing the app of the active task.
		//
		[[NSNotificationCenter defaultCenter] 
						postNotificationName:MGSNoteActionSelectionChanged 
						object:[[self view] window]  
						userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aTaskSpec, MGSActionKey, nil]];

	}
	
	//
	// tell the script view that the action has changed
	//
	// we need to detect a change in the action and a change in the script version.
	// if the script is edited then the action can remain while the script version id changes.
	//
	if (actionPathChanged || scriptVersionIDChanged) {
		[_scriptViewController setTaskSpec:aTaskSpec];
	}
}

/*
 
 window closing
 
 */
- (void)windowClosing
{
	[self saveUserDefaults]; 
	[_historyViewController saveHistory];	
	[_browserViewController savePreferences];
}

#pragma mark -
#pragma mark User defaults
/*
 
 - loadUserDefaults
 
 */
- (void)loadUserDefaults
{
	// initialise task browser selection
	NSInteger taskBrowserMode = [[NSUserDefaults standardUserDefaults] integerForKey:MGSTaskBrowserMode];
	[_browserViewControlStrip selectSegment:taskBrowserMode];
	
	// initialise task detail selection
	NSInteger taskDetailMode = [[NSUserDefaults standardUserDefaults] integerForKey:MGSTaskDetailMode];
	[self selectDetailSegment:taskDetailMode];

	
	// initialise browser height
	CGFloat browserHeight = [[NSUserDefaults standardUserDefaults] floatForKey:MGSTaskBrowserHeight];
	if (browserHeight > 0.1) {
		if ([self browserViewIsHidden]) {
			NSRect frame = [mainTopView frame];
			frame.size.height = browserHeight;
			[mainTopView setFrame:frame];
		} else {
			
			// this will apply constrants as imposed by the delegate
			[mainSplitView setPosition:browserHeight ofDividerAtIndex:0];
		}
		
	}
	
	// initialise detail height
	NSInteger taskDetailHeight = [[NSUserDefaults standardUserDefaults] integerForKey:MGSTaskDetailHeight];
	if (taskDetailHeight) {
		if ([self detailViewIsHidden]) {
			NSRect frame = [mainBottomView frame];
			frame.size.height = taskDetailHeight;
			[mainBottomView setFrame:frame];
		} else {
			NSInteger idx = [[mainSplitView subviews] count] - 2;
			if (idx >= 0) {
				CGFloat position = [mainSplitView frame].size.height;
				position -= taskDetailHeight;
				position -= [mainSplitView dividerThickness];
				
				// this will apply constraints as imposed by the delegate
				[mainSplitView setPosition:position ofDividerAtIndex:idx];
			}
		}
	}
	
	// initialise group list display
	BOOL showGroupList = [[NSUserDefaults standardUserDefaults]boolForKey:MGSMainGroupListVisible];
	eMGSViewState viewState = showGroupList ? kMGSViewStateShow : kMGSViewStateHide;
	
	// post view mode change request
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInteger:kMGSMotherViewConfigGroupList], MGSNoteViewConfigKey,
						  [NSNumber numberWithInteger:viewState], MGSNoteViewStateKey,
						  nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:self userInfo:dict];
	
}

/*
 
 - saveUserDefaults
 
 */
- (void)saveUserDefaults
{
	NSRect frame = [mainTopView frame];
	[[NSUserDefaults standardUserDefaults] setFloat:frame.size.height forKey:MGSTaskBrowserHeight];
	
	frame = [mainBottomView frame];
	[[NSUserDefaults standardUserDefaults] setFloat:frame.size.height forKey:MGSTaskDetailHeight];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
}

#pragma mark -
#pragma mark task search view delegate methods

/*
 
 search view controller search filter changed
 
 */
- (void)searchViewController:(MGSTaskSearchViewController *)sender searchFilterChanged:(NSNotification *)note
{
	#pragma unused(sender)
	#pragma unused(note)
	
	[self showSearchView];
}

@end 

#pragma mark -
@implementation MGSMainViewController(private)

// history view delegate
- (void)historyViewChanged:(MGSHistoryViewController *)aHistory
{
	// swap detail view into splitview
	NSView *newView = detailTabView;
	[newView setFrameSize: [mainBottomView bounds].size];	// make subview same size as middle view
	[mainSplitView replaceBottomView:newView];
	mainBottomView = newView;
	
	// add history view to tabview item 0
	newView = [aHistory view];
	NSTabViewItem *tabItem = [detailTabView tabViewItemAtIndex:TAB_HISTORY];
	[tabItem setView:newView];
	[detailTabView selectTabViewItem:tabItem];

	// add script view to tabview item 1
	newView = [_scriptViewController view];
	tabItem = [detailTabView tabViewItemAtIndex:TAB_SCRIPT];
	[tabItem setView:newView];
}

/*
 
 select action
 
 */
- (void)selectAction:(MGSTaskSpecifier *)action
{
	NSAssert(action, @"action is nil");

	// action needs to contain display representation of our script
	if ([[action script] representation] != MGSScriptRepresentationDisplay) {
		
		// get script from client for our UUID
		NSString *UUID = [[action script] UUID];
		MGSScript *script = [[action.netClient.taskController scriptManager] scriptForUUID:UUID];
		if (!script) {
			MLog(RELEASELOG, @"could not find script with UUID: %@ for client: %@", [action.netClient serviceName], UUID);
			return;
		}
		
		action.script = script;
	}
	
	// display action accordingly
	if ([action displayType] == MGSTaskDisplayInNewTab) {
		[_requestTabViewController addTabWithActionSpecifier:action];
	} else {
		// find a tab for this action
		if ([_requestTabViewController selectTabForActionSpecifier:action] == kMGSActionTabSelectedUUIDMatch) {
			// selectTabForActionSpecifier above found a tab matching the UUID of the action.
			// the action for the tab was not actually updated, so parameters etc will not match,
			// so force the tab specifier update
			[_requestTabViewController setActionSpecifierForSelectedTab:action];
		}
	}

	// need to sync browser with selected action
	// not reqd it seems, tab sends this on selection
	//[_browserViewController showPathToAction:action];
}

/*
 
 set detail segmented control hidden
 
 */
/*
- (void)updateDetailSegmentedControlVisibility
{
	BOOL hidden = _detailSegmentHidden;
	
	
	// id detail tabview not in the window then hide
	if (![detailTabView window]) {
		hidden = YES;
	} 
	
	// set hidden status
	[detailSegmentedControl setHidden:hidden];
}
 */
@end
