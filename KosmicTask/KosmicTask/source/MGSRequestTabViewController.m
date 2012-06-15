//
//  MGSRequestTabViewController.m
//  Mother
//
//  Created by Jonathan on 15/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
// Largely modelled on the PSMTabBarContol demo app
// as obtained from maccode
//
#import "MGSRequestTabViewController.h"
#import "FakeModel.h"
#import <PSMTabBarControl/PSMTabBarControl.h>
#import <PSMTabBarControl/PSMTabStyle.h>
#import "MGSRequestViewController.h"
#import "MGSInputRequestViewController.h"
#import "MGSActionViewController.h"
#import "MGSTaskSpecifier.h"
#import "MGSNetClient.h"
#import "MGSMother.h"
#import "MGSAppController.h"
#import "NSWindow_Mugginsoft.h"
#import "MGSRequestViewManager.h"
#import "MGSRequestTabScrollView.h"
#import "MGSMemoryManagement.h"
#import "MGSPreferences.h"
#import "MGSNotifications.h"
#import "MGSMotherWindowController.h"

NSString *MGSDefaultTabStyle = @"PSMTabBarControl.Style";
NSString *MGSDefaultTabOrientation =  @"PSMTabBarControl.Orientation";
NSString *MGSDefaultTabTearOff =  @"PSMTabBarControl.Tear-Off";
NSString *MGSDefaultTabMinWidth =  @"PSMTabBarControl.TabMinWidth";
NSString *MGSDefaultTabMaxWidth =  @"PSMTabBarControl.TabMaxWidth";
NSString *MGSDefaultTabOptimalWidth =  @"PSMTabBarControl.TabOptimalWidth";
NSString *MGSDefaultTabUseOverflowMenu =  @"PSMTabBarControl.UseOverflowMenu";
NSString *MGSDefaultTabAllowScrubbing =  @"PSMTabBarControl.AllowScrubbing";
NSString *MGSDefaultTabCanCloseOnlyTab =  @"PSMTabBarControl.CanCloseOnlyTab";
NSString *MGSDefaultTabDisableTabClosing =  @"PSMTabBarControl.DisableTabClosing";
NSString *MGSDefaultTabHideForSingleTab =  @"PSMTabBarControl.HideForSingleTab";
NSString *MGSDefaultTabShowAddTabButton =  @"PSMTabBarControl.ShowAddTabButton";
NSString *MGSDefaultTabSizeToFit =  @"PSMTabBarControl.SizeToFit";
NSString *MGSDefaultTabAutomaticallyAnimates =  @"PSMTabBarControl.AutomaticallyAnimates";

// class extension
@interface MGSRequestTabViewController()
- (void)showTaskTabContextMenu:(NSNotification *)note;
@end

@interface MGSRequestTabViewController (PRIVATE)
- (void)configureTabBarInitially;
- (void)setActionSpecifier:(MGSTaskSpecifier *)action forTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)informDelegateTabSelected;
- (void)triggerTabViewItemSelected;
- (void)freeTabViewItemResources:(NSTabViewItem *)tabViewItem;
- (void)removeRequestViewActionObservers:(MGSRequestViewController *)requestViewController;
- (void)addRequestViewActionObservers:(MGSRequestViewController *)requestViewController;
- (void)closeTabViewItem:(NSTabViewItem *)tabViewItem;
- (MGSRequestViewController *)newRequestViewController;
- (void)createRequestViewWithinTabView:(NSTabViewItem *)tabViewItem;
@end

@implementation MGSRequestTabViewController

@synthesize delegate = _delegate;
@synthesize minViewHeight = _minViewHeight;

- (void)awakeFromNib
{
	// add items to use defaults dict
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  @"Unified", MGSDefaultTabStyle,		//@"Aqua", @"Unified" @"Metal", @"Adium"
	  @"Horizontal", MGSDefaultTabOrientation,
	  @"Alpha Window", MGSDefaultTabTearOff,
	  @"200", MGSDefaultTabMinWidth,
	  @"480", MGSDefaultTabMaxWidth,
	  @"400", MGSDefaultTabOptimalWidth,
	  [NSNumber numberWithBool:YES], MGSDefaultTabUseOverflowMenu,
	  [NSNumber numberWithBool:YES], MGSDefaultTabAllowScrubbing,
		[NSNumber numberWithBool:NO], MGSDefaultTabCanCloseOnlyTab,
		[NSNumber numberWithBool:NO], MGSDefaultTabDisableTabClosing,
		[NSNumber numberWithBool:NO], MGSDefaultTabHideForSingleTab,
		[NSNumber numberWithBool:YES], MGSDefaultTabShowAddTabButton,
		[NSNumber numberWithBool:YES], MGSDefaultTabSizeToFit,
		[NSNumber numberWithBool:NO], MGSDefaultTabAutomaticallyAnimates,
	  nil]];

	
    // hook up add tab button
    [[tabBar addTabButton] setTarget:self];
    [[tabBar addTabButton] setAction:@selector(addCopyOfSelectedTab:)];
    
    // remove any tabs present in the nib
 	int i;
	for (i=[tabView numberOfTabViewItems]-1; i >=0; i--) {
		NSTabViewItem *item = [[tabView tabViewItems] objectAtIndex:i];
		[tabView removeTabViewItem:item];
	}
	
	[self configureTabBarInitially];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showTaskTabContextMenu:) name:MGSShowTaskTabContextMenu object:nil];
	
	
	self.minViewHeight = 350;
}

/*
 
 - showTaskTabContextMenu:
 
 */
- (void)showTaskTabContextMenu:(NSNotification *)note
{
	NSEvent *event = note.object;
	if (![event isKindOfClass:[NSEvent class]]) {
		return;
	}
	
	if ([event window] != [self.view window]) {
		return;
	}
	
	//NSPoint *localPoint = [self.view convertPoint:[event locationInWindow] fromView:nil];
	[NSMenu popUpContextMenu:tabContextMenu withEvent:event forView:self.view]; 
}

/*
 
 add default tabs
 
 */
- (void)addDefaultTabs
{
	[self addNewTab:self];
}

/*
 
 tab count
 
 */
- (NSInteger)tabCount
{
	return [tabView numberOfTabViewItems];
}

/*
 
 select next tab
 
 */
- (void)selectNextTab
{
	if ([tabView indexOfTabViewItem:[tabView selectedTabViewItem]] >= [self tabCount] -1) {
		[tabView selectFirstTabViewItem:self];
	} else {
		[tabView selectNextTabViewItem:self];
	}
}

/*
 
 select next tab
 
 */
- (void)selectPreviousTab
{
	if ([tabView indexOfTabViewItem:[tabView selectedTabViewItem]]<= 0) {
		[tabView selectLastTabViewItem:self];
	} else {
		[tabView selectPreviousTabViewItem:self];
	}
	
}

/*
 
 add a copy of the currently selected tab
 
 */
- (IBAction)addCopyOfSelectedTab:(id)sender
{
	#pragma unused(sender)
	
	NSTabViewItem *tabViewItem = [tabView selectedTabViewItem];
	NSAssert(tabViewItem, @"selected tab view item is nil");
	
	MGSRequestViewController *requestViewController = [tabViewItem identifier];
	
	// actionSpecifier may be nil if there are no published scripts
	if (!requestViewController.actionSpecifier) {
		return;
	}

	// commit any pending edits.
    // if the commit fails we probably have validation issues.
	if (![[[self view] window] endEditing:NO]) {
        return;
    }
    
	// create mutable copy of action
	MGSTaskSpecifier *action = [requestViewController.actionSpecifier mutableDeepCopyAsNewInstance];

	// add new tab and set action
	[self addNewTab:self];
	[self setActionSpecifierForSelectedTab:action];
}

/*
 
 add a new tab
 
 */
- (IBAction)addNewTab:(id)sender
{
	#pragma unused(sender)
	
	// create the tab view item and add to tab view
    //NSTabViewItem *newItem = [[NSTabViewItem alloc] initWithIdentifier:requestViewController];
	NSTabViewItem *tabViewItem = [[NSTabViewItem alloc] init];

	// create request view within tab view
	[self createRequestViewWithinTabView:tabViewItem];	
	
	[tabViewItem setLabel:NSLocalizedString(@"Task", @"New task tab title")];
    [tabView addTabViewItem:tabViewItem];
    [tabView selectTabViewItem:tabViewItem]; // this is optional, but expected behavior
	
}

/*
 
 set the MGSTaskSpecifier for a new tab
 
 */
- (void)addTabWithActionSpecifier:(MGSTaskSpecifier *)action
{
	// add a new tab.
	// note that this tab will be selected and that tabView:didSelectTabViewItem will be sent.
	// the tabview at this stage though does not reference an action
	[self addNewTab:self];
	
	// set action specifier for the newly selected tab
	[self setActionSpecifierForSelectedTab:action];
}

/*
 
 set the MGSTaskSpecifier for the currently selected tab
 
 */
- (void)setActionSpecifierForSelectedTab:(MGSTaskSpecifier *)action
{
	NSTabViewItem *tabViewItem = [tabView selectedTabViewItem];
	[self setActionSpecifier:action forTabViewItem:tabViewItem];
	
	// as we have changed the action for the currently selected tab
	// we need to retrigger the tab view selection process
	[self triggerTabViewItemSelected];
}

//===============================================================
//
// select a suitable tab for the action specifier
//
//===============================================================
- (MGSActionTabSelected)selectTabForActionSpecifier:(MGSTaskSpecifier *)action
{
	NSTabViewItem *tabViewItem;
	
	// get controller for selected tab
	MGSRequestViewController *requestViewController = [self selectedRequestViewController];
	MGSTaskSpecifier *tabAction = requestViewController.actionSpecifier;	
	MGSAppController *appController = [NSApp delegate];
	
	// if the selected tab has no action then set action for that tab.
	// this will be the case on startup when one tab pre-exists.
	// also only want one tab to be visible on startup so awlays
	// update the first tab during startup
	if (nil == tabAction || NO == [appController startupComplete]) {
		[self setActionSpecifierForSelectedTab:action];
		return kMGSActionTabSelectedStartup;
	}

	// search for tabview matching the action client and UUID.
	// if find a match then select it.
	tabViewItem = [self tabViewItemForActionUUID:action];
	if (tabViewItem) {
		// found tab matching client and UUID.
		// note that this does not actually change the specifier for the tab
		[tabView selectTabViewItem:tabViewItem];
		return kMGSActionTabSelectedUUIDMatch;
	}
	
	// if the selected tab matches the net client and it is available
	// then update the action for this tab
	if ([[[tabAction netClient] serviceName] isEqualToString: [[action netClient] serviceName]] &&
		[requestViewController permitSetActionSpecifier]) {			
		[self setActionSpecifierForSelectedTab:action];
		
		return kMGSActionTabSelectedNetClientMatch;
	}
	
	// search for tabview matching action client.
	// note that this will return the most recent matching item.
	tabViewItem = [self tabViewItemForActionClient:action];
	if (tabViewItem) {

		// set action for tab if permitted
		requestViewController = [tabViewItem identifier];
		if ([requestViewController permitSetActionSpecifier]) {
			[self setActionSpecifier:action forTabViewItem:tabViewItem];
			[tabView selectTabViewItem:tabViewItem];
			return kMGSActionTabSelectedNetClientMatch;
		}
	}


	// cannot find a matching tab for this action so create one
	[self addTabWithActionSpecifier:action];
	
	return kMGSActionTabSelectedNewTabCreated;
}

/*
 
 number of actions currently processing
 
 */
- (NSInteger)actionProcessingCount
{
	NSInteger count = 0;
	
	for (int i = [tabView numberOfTabViewItems]-1; i >=0; i--) {
		NSTabViewItem *item = [[tabView tabViewItems] objectAtIndex:i];
		MGSTaskSpecifier *tabAction = [self actionSpecifierForTabViewItem:item];
		if ([tabAction isProcessing]) count++;
	}
		
	return count;
}

/*
 
 selected request view controller
 
 */
- (MGSRequestViewController *)selectedRequestViewController
{
	return [[tabView selectedTabViewItem] identifier];
}

/*
 
 - applyUserDefaultsToSelectedTab
 
 */
- (void)applyUserDefaultsToSelectedTab
{
	MGSRequestViewController *requestViewController = [self selectedRequestViewController];

	// set the pin state of tabs created by the user
	BOOL keepActionDisplayed = [[NSUserDefaults standardUserDefaults] boolForKey:MGSNewTabKeepTaskDisplayed];
	[requestViewController inputViewController].keepActionDisplayed = keepActionDisplayed;
	
}

#pragma mark observations

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(change)
	#pragma unused(context)
	
	if ([object isKindOfClass:[MGSTaskSpecifier class]]) {
		
		// action observed
		MGSTaskSpecifier *action = object;
		
		// host staus changed
		if ([keyPath isEqualToString:MGSKeyPathNetClientHostStatus]) {	
			
			NSTabViewItem *tabViewItem = [self tabViewItemForAction:action];
			MGSRequestViewController *requestViewController = [tabViewItem identifier];
			[requestViewController setIcon:[[action netClient] hostIcon]];
		}
	}
}

/*
 
 get a tabview item matching the action
 
 */
 - (NSTabViewItem *)tabViewItemForAction:(MGSTaskSpecifier *)action
 {
	int i;
	for (i=[tabView numberOfTabViewItems]-1; i >=0; i--) {
		NSTabViewItem *item = [[tabView tabViewItems] objectAtIndex:i];
		if ([[self actionSpecifierForTabViewItem:item] isEqual:action]) {
			return item;
		}
	}
	return nil;
}

/*
 
 get a tabview item matching the action UUID
 
 */
- (NSTabViewItem *)tabViewItemForActionUUID:(MGSTaskSpecifier *)action
{
	int i;
	for (i=[tabView numberOfTabViewItems]-1; i >=0; i--) {
		NSTabViewItem *item = [[tabView tabViewItems] objectAtIndex:i];
		
		MGSTaskSpecifier *tabAction = [self actionSpecifierForTabViewItem:item];
		
		// match netclient and action UUID
		if ([[[tabAction netClient] serviceName] isEqualToString:[[action netClient] serviceName]] &&
			[[tabAction UUID] isEqualToString:[action UUID]]) {
			return item;
		}
	}
	return nil;
}

/*
 
 get a tabview item matching the action client
 
 */
- (NSTabViewItem *)tabViewItemForActionClient:(MGSTaskSpecifier *)action
{
	int i;
	for (i=[tabView numberOfTabViewItems]-1; i >=0; i--) {
		NSTabViewItem *item = [[tabView tabViewItems] objectAtIndex:i];
		
		MGSTaskSpecifier *tabAction = [self actionSpecifierForTabViewItem:item];
		
		// match netclient 
		if ([[[tabAction netClient] serviceName] isEqualToString:[[action netClient] serviceName]]) {
			return item;
		}
	}
	return nil;
}

/*
 
 get the action for the currently selected tab
 
 */
- (MGSTaskSpecifier *)actionSpecifierForSelectedTab
{
	return [self actionSpecifierForTabViewItem:[tabView selectedTabViewItem]];
}

/*
 
 get the action for a tab
 
 */
- (MGSTaskSpecifier *)actionSpecifierForTabViewItem:(NSTabViewItem *)tabViewItem
{
   MGSRequestViewController *requestViewController = [tabViewItem identifier];
  // NSAssert(requestViewController, @"request view controller is nil");
   return [requestViewController actionSpecifier];	 
}

/*
 
 execute the action in the currently selected tab
 
 */
- (void)executeSelectedAction
{
	MGSRequestViewController *requestViewController = [self selectedRequestViewController];
	NSAssert(requestViewController, @"request view controller is nil");
	
	if ([requestViewController actionSpecifier]) {
		[requestViewController executeScript:self];	
	}
}

/*
 
 terminate the action in the currently selected tab
 
 */
- (void)terminateSelectedAction
{
	MGSRequestViewController *requestViewController = [self selectedRequestViewController];
	NSAssert(requestViewController, @"request view controller is nil");
	[requestViewController terminateScript:self];	
}

/*
 
 suspend the action in the currently selected tab
 
 */
- (void)suspendSelectedAction
{
	MGSRequestViewController *requestViewController = [self selectedRequestViewController];
	NSAssert(requestViewController, @"request view controller is nil");
	[requestViewController suspendScript:self];	
}

/*
 
 resume the action in the currently selected tab
 
 */
- (void)resumeSelectedAction
{
	MGSRequestViewController *requestViewController = [self selectedRequestViewController];
	NSAssert(requestViewController, @"request view controller is nil");
	[requestViewController resumeScript:self];	
}

- (IBAction)closeSelectedTab:(id)sender
{
	#pragma unused(sender)
	if ([tabView numberOfTabViewItems] > 1) {
		[self closeTabViewItem:[tabView selectedTabViewItem]];
	}
}


// get tab view item for requestview
- (NSTabViewItem *)tabViewItemForRequestView:(MGSRequestViewController *)requestView
{
	int i;
	for (i=[tabView numberOfTabViewItems]-1; i >=0; i--) {
		NSTabViewItem *item = [[tabView tabViewItems] objectAtIndex:i];
		if ([item identifier] == requestView) {
			return item;
		}
	}
	return nil;
}

- (void)stopProcessing:(id)sender
{
	#pragma unused(sender)
	
    [[self selectedRequestViewController] setValue:[NSNumber numberWithBool:NO] forKeyPath:@"isProcessing"];
}

- (void)setIconNamed:(id)sender
{
    NSString *iconName = [sender titleOfSelectedItem];
    if ([iconName isEqualToString:@"None"]) {
        [[self selectedRequestViewController] setValue:nil forKeyPath:@"icon"];
        [[self selectedRequestViewController] setValue:@"None" forKeyPath:@"iconName"];
    } else {
        NSImage *newIcon = [NSImage imageNamed:iconName];
        [[self selectedRequestViewController] setValue:newIcon forKeyPath:@"icon"];
        [[self selectedRequestViewController] setValue:iconName forKeyPath:@"iconName"];
    }
}

- (void)setObjectCount:(id)sender
{
    [[self selectedRequestViewController] setValue:[NSNumber numberWithInt:[sender intValue]] forKeyPath:@"objectCount"];
}

- (IBAction)isProcessingAction:(id)sender
{
    [[self selectedRequestViewController] setValue:[NSNumber numberWithBool:[sender state]] forKeyPath:@"isProcessing"];
}

- (IBAction)isEditedAction:(id)sender
{
    [[self selectedRequestViewController] setValue:[NSNumber numberWithBool:[sender state]] forKeyPath:@"isEdited"];
}

- (IBAction)setTabLabel:(id)sender
{
    [[tabView selectedTabViewItem] setLabel:[sender stringValue]];
}

/*
 
 validate mennu item
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	#pragma unused(menuItem)
	/*
    if ([menuItem action] == @selector(closeTab:)) {
        if (![tabBar canCloseOnlyTab] && ([tabView numberOfTabViewItems] <= 1)) {
            return NO;
        }
    }
	 */
    return YES;
}

- (PSMTabBarControl *)tabBar
{
	return tabBar;
}
/*
- (void)windowWillClose:(NSNotification *)note
{
	[self autorelease];
}
*/
#pragma mark -
#pragma mark ---- tab bar config ----

- (void)configStyle:(id)sender
{
    [tabBar setStyleNamed:[sender titleOfSelectedItem]];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[sender titleOfSelectedItem]
	//										  forKey:MGSDefaultTabStyle];
}

- (void)configOrientation:(id)sender
{
	PSMTabBarOrientation orientation = ([sender indexOfSelectedItem] == 0) ? PSMTabBarHorizontalOrientation : PSMTabBarVerticalOrientation;
	
	if (orientation == [tabBar orientation]) {
		return;
	}
	
	//change the frame of the tab bar according to the orientation	
	NSRect tabBarFrame = [tabBar frame], tabViewFrame = [tabView frame];
	NSRect totalFrame = NSUnionRect(tabBarFrame, tabViewFrame);
	
	if (orientation == PSMTabBarHorizontalOrientation) {
		tabBarFrame.size.height = [tabBar isTabBarHidden] ? 1 : 22;
		tabBarFrame.size.width = totalFrame.size.width;
		tabBarFrame.origin.y = totalFrame.origin.y + totalFrame.size.height - tabBarFrame.size.height;
		tabViewFrame.origin.x = 13;
		tabViewFrame.size.width = totalFrame.size.width - 23;
		tabViewFrame.size.height = totalFrame.size.height - tabBarFrame.size.height - 2;
		[tabBar setAutoresizingMask:NSViewMinYMargin | NSViewWidthSizable];
	} else {
		tabBarFrame.size.height = totalFrame.size.height;
		tabBarFrame.size.width = [tabBar isTabBarHidden] ? 1 : 120;
		tabBarFrame.origin.y = totalFrame.origin.y;
		tabViewFrame.origin.x = tabBarFrame.origin.x + tabBarFrame.size.width;
		tabViewFrame.size.width = totalFrame.size.width - tabBarFrame.size.width;
		tabViewFrame.size.height = totalFrame.size.height;
		[tabBar setAutoresizingMask:NSViewHeightSizable];
	}
	
	tabBarFrame.origin.x = totalFrame.origin.x;
	tabViewFrame.origin.y = totalFrame.origin.y;
	
	[tabView setFrame:tabViewFrame];
	[tabBar setFrame:tabBarFrame];
	
	[tabBar setOrientation:orientation];
	// JM [[self window] display];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[sender title]
	//										  forKey:MGSDefaultTabOrientation];
}

- (void)configCanCloseOnlyTab:(id)sender
{
    [tabBar setCanCloseOnlyTab:[sender state]];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]]
	//										  forKey:MGSDefaultTabCanCloseOnlyTab];	
}

- (void)configDisableTabClose:(id)sender
{
	[tabBar setDisableTabClose:[sender state]];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]]
	//										  forKey:MGSDefaultTabDisableTabClosing];	
}

- (void)configHideForSingleTab:(id)sender
{
    [tabBar setHideForSingleTab:[sender state]];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]]
	//										  forKey:MGSDefaultTabHideForSingleTab];
}

- (void)configAddTabButton:(id)sender
{
    [tabBar setShowAddTabButton:[sender state]];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]]
	//										  forKey:MGSDefaultTabShowAddTabButton];
}

- (void)configTabMinWidth:(id)sender
{
    if ([tabBar cellOptimumWidth] < [sender intValue]) {
        [tabBar setCellMinWidth:[tabBar cellOptimumWidth]];
        [sender setIntValue:[tabBar cellOptimumWidth]];
        return;
    }
    
    [tabBar setCellMinWidth:[sender intValue]];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[sender intValue]]
	//										  forKey:MGSDefaultTabMinWidth];
}

- (void)configTabMaxWidth:(id)sender
{
    if ([tabBar cellOptimumWidth] > [sender intValue]) {
        [tabBar setCellMaxWidth:[tabBar cellOptimumWidth]];
        [sender setIntValue:[tabBar cellOptimumWidth]];
        return;
    }
    
    [tabBar setCellMaxWidth:[sender intValue]];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[sender intValue]]
	//										  forKey:MGSDefaultTabMaxWidth];
}

- (void)configTabOptimumWidth:(id)sender
{
    if ([tabBar cellMaxWidth] < [sender intValue]) {
        [tabBar setCellOptimumWidth:[tabBar cellMaxWidth]];
        [sender setIntValue:[tabBar cellMaxWidth]];
        return;
    }
    
    if ([tabBar cellMinWidth] > [sender intValue]) {
        [tabBar setCellOptimumWidth:[tabBar cellMinWidth]];
        [sender setIntValue:[tabBar cellMinWidth]];
        return;
    }
    
    [tabBar setCellOptimumWidth:[sender intValue]];
	
}

- (void)configTabSizeToFit:(id)sender
{
    [tabBar setSizeCellsToFit:[sender state]];
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender intValue]]
	//										  forKey:MGSDefaultTabSizeToFit];
}

- (void)configTearOffStyle:(id)sender
{
	//[tabBar setTearOffStyle:PSMTabBarTearOffMiniwindow];

	[tabBar setTearOffStyle:([sender indexOfSelectedItem] == 0) ? PSMTabBarTearOffAlphaWindow : PSMTabBarTearOffMiniwindow];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[sender title]
	//										  forKey:MGSDefaultTabTearOff];
}

- (void)configUseOverflowMenu:(id)sender
{
    [tabBar setUseOverflowMenu:[sender state]];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender intValue]]
	//										  forKey:MGSDefaultTabUseOverflowMenu];
}

- (void)configAutomaticallyAnimates:(id)sender
{
	[tabBar setAutomaticallyAnimates:[sender state]];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender intValue]]
	//										  forKey:MGSDefaultTabAutomaticallyAnimates];
}

- (void)configAllowsScrubbing:(id)sender
{
	[tabBar setAllowsScrubbing:[sender state]];
	
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender intValue]]
	//										  forKey:MGSDefaultTabAllowScrubbing];
}


#pragma mark -
#pragma mark ---- delegate ----

- (void)tabView:(NSTabView *)aTabView tabViewItem:(NSTabViewItem *)tabViewItem event:(NSEvent *)event
{
#pragma unused(aTabView)
#pragma unused(tabViewItem)
	
	switch ([event type]) {
		case NSLeftMouseUp:
			if ([event clickCount] == 2) {
				[NSApp sendAction:@selector(subviewDoubleClick:) to:nil from:self];
			}
			break;
			
	}
}

/*
 
 tabview did select tabview item
 
 */
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	#pragma unused(aTabView)
	
	// require that only the current tabviews request view controller
	// observe the input modification notification for this window
	MGSRequestViewController *requestViewController;
	
	// note that requestViewController.action may be nil when a new tabview is added
	// and the action has not yet been set
	
	if (_currentTabViewItem) {
		requestViewController = [_currentTabViewItem identifier];
		requestViewController.observesInputModifications = NO;
		_currentTabViewItem = nil;
	}
	_currentTabViewItem = tabViewItem;
	requestViewController = [_currentTabViewItem identifier];
	requestViewController.observesInputModifications = YES;
	

	// note that the delegate is informed of the tab change regardless of wether the change
	// is incurred by a user click or programmtic change
	[self informDelegateTabSelected];
}

/*
 
 should close tab view item
 
 */
- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
	#pragma unused(aTabView)
	
	// do not close the tab is action processing
	if ([[self selectedRequestViewController] isProcessing]) {
		return NO;
	}
		
	MLog(DEBUGLOG, @"shouldCloseTabViewItem: %@", [tabViewItem label]);
	
	// free resources here as tabView:didCloseTabViewItem: does not seem to be sent
	[self freeTabViewItemResources:tabViewItem];
	
	// trigger memory collection
	if (NO) {
		// might be a source of problems - use with caution
		[MGSMemoryManagement collectExhaustivelyAfterDelay:5];
	}
    return YES;
}

/*
 
 this does not seem to be getting called
 
 */
- (void)tabView:(NSTabView *)aTabView willCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
	#pragma unused(aTabView)
	
    MLog(DEBUGLOG, @"willCloseTabViewItem: %@", [tabViewItem label]);
}


/*
 
 this does not seem to be getting called
 
 */
- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
	#pragma unused(aTabView)
	
    MLog(DEBUGLOG, @"didCloseTabViewItem: %@", [tabViewItem label]);
}

- (NSArray *)allowedDraggedTypesForTabView:(NSTabView *)aTabView
{
	#pragma unused(aTabView)
	
	return [NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil];
}

- (void)tabView:(NSTabView *)aTabView acceptedDraggingInfo:(id <NSDraggingInfo>)draggingInfo onTabViewItem:(NSTabViewItem *)tabViewItem
{
	#pragma unused(aTabView)
	
	MLog(DEBUGLOG, @"acceptedDraggingInfo: %@ onTabViewItem: %@", [[draggingInfo draggingPasteboard] stringForType:[[[draggingInfo draggingPasteboard] types] objectAtIndex:0]], [tabViewItem label]);
}

- (NSMenu *)tabView:(NSTabView *)aTabView menuForTabViewItem:(NSTabViewItem *)tabViewItem
{
#pragma unused(aTabView)
#pragma unused(tabViewItem)
	
	if ([tabView selectedTabViewItem] != tabViewItem) {
		[tabView selectTabViewItem:tabViewItem];
	}
	
	return tabContextMenu;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl
{
	#pragma unused(aTabView)
	#pragma unused(tabViewItem)
	#pragma unused(tabBarControl)
	
	return YES;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl
{
	#pragma unused(aTabView)
	#pragma unused(tabViewItem)
	#pragma unused(tabBarControl)
	
	return YES;
}

- (void)tabView:(NSTabView*)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl
{
	#pragma unused(aTabView)
	#pragma unused(tabViewItem)
	
	MLog(DEBUGLOG, @"didDropTabViewItem: %@ inTabBar: %@", [tabViewItem label], tabBarControl);
}

- (NSImage *)tabView:(NSTabView *)aTabView imageForTabViewItem:(NSTabViewItem *)tabViewItem offset:(NSSize *)offset styleMask:(unsigned int *)styleMask
{
	#pragma unused(aTabView)
	#pragma unused(tabViewItem)
	#pragma unused(offset)
	#pragma unused(styleMask)
	
	/* JM
	// grabs whole window image
	NSImage *viewImage = [[[NSImage alloc] init] autorelease];
	NSRect contentFrame = [[[self window] contentView] frame];
	[[[self window] contentView] lockFocus];
	NSBitmapImageRep *viewRep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:contentFrame] autorelease];
	[viewImage addRepresentation:viewRep];
	[[[self window] contentView] unlockFocus];
	
    // grabs snapshot of dragged tabViewItem's view (represents content being dragged)
	NSView *viewForImage = [tabViewItem view];
	NSRect viewRect = [viewForImage frame];
	NSImage *tabViewImage = [[[NSImage alloc] initWithSize:viewRect.size] autorelease];
	[tabViewImage lockFocus];
	[viewForImage drawRect:[viewForImage bounds]];
	[tabViewImage unlockFocus];
	
	[viewImage lockFocus];
	NSPoint tabOrigin = [tabView frame].origin;
	tabOrigin.x += 10;
	tabOrigin.y += 13;
	[tabViewImage compositeToPoint:tabOrigin operation:NSCompositeSourceOver];
	[viewImage unlockFocus];
	
	//draw over where the tab bar would usually be
	NSRect tabFrame = [tabBar frame];
	[viewImage lockFocus];
	[[NSColor windowBackgroundColor] set];
	NSRectFill(tabFrame);
	//draw the background flipped, which is actually the right way up
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:1.0 yBy:-1.0];
	[transform concat];
	tabFrame.origin.y = -tabFrame.origin.y - tabFrame.size.height;
	[(id <PSMTabStyle>)[[aTabView delegate] style] drawBackgroundInRect:tabFrame];
	[transform invert];
	[transform concat];
	
	[viewImage unlockFocus];
	
	if ([[aTabView delegate] orientation] == PSMTabBarHorizontalOrientation) {
		offset->width = [(id <PSMTabStyle>)[[aTabView delegate] style] leftMarginForTabBarControl];
		offset->height = 22;
	} else {
		offset->width = 0;
		offset->height = 22 + [(id <PSMTabStyle>)[[aTabView delegate] style] leftMarginForTabBarControl];
	}
	
	if (styleMask) {
		*styleMask = NSTitledWindowMask | NSTexturedBackgroundWindowMask;
	}
	
	
	
	return viewImage;
	 */
	
	return nil;
}

- (PSMTabBarControl *)tabView:(NSTabView *)aTabView newTabBarForDraggedTabViewItem:(NSTabViewItem *)tabViewItem atPoint:(NSPoint)point
{
	#pragma unused(aTabView)
	
	MLog(DEBUGLOG, @"newTabBarForDraggedTabViewItem: %@ atPoint: %@", [tabViewItem label], NSStringFromPoint(point));
	
	/*
	//create a new window controller with no tab items
	WindowController *controller = [[WindowController alloc] initWithWindowNibName:@"Window"];
	id <PSMTabStyle> style = (id <PSMTabStyle>)[[aTabView delegate] style];
	
	NSRect windowFrame = [[controller window] frame];
	point.y += windowFrame.size.height - [[[controller window] contentView] frame].size.height;
	point.x -= [style leftMarginForTabBarControl];
	
	[[controller window] setFrameTopLeftPoint:point];
	[[controller tabBar] setStyle:style];
	
	return [controller tabBar];
	 */
	
	return nil;
}

- (void)tabView:(NSTabView *)aTabView closeWindowForLastTabViewItem:(NSTabViewItem *)tabViewItem
{
	#pragma unused(aTabView)
	
	MLog(DEBUGLOG, @"closeWindowForLastTabViewItem: %@", [tabViewItem label]);
	// JM [[self window] close];
}

- (void)tabView:(NSTabView *)aTabView tabBarDidHide:(PSMTabBarControl *)tabBarControl
{
	#pragma unused(aTabView)
	
	MLog(DEBUGLOG, @"tabBarDidHide: %@", tabBarControl);
}

- (void)tabView:(NSTabView *)aTabView tabBarDidUnhide:(PSMTabBarControl *)tabBarControl
{
	#pragma unused(aTabView)
	
	MLog(DEBUGLOG, @"tabBarDidUnhide: %@", tabBarControl);
}

- (NSString *)tabView:(NSTabView *)aTabView toolTipForTabViewItem:(NSTabViewItem *)tabViewItem
{
	#pragma unused(aTabView)
	
	return [tabViewItem label];
}

- (NSString *)accessibilityStringForTabView:(NSTabView *)aTabView objectCount:(int)objectCount
{
	#pragma unused(aTabView)
	
	return (objectCount == 1) ? @"item" : @"items";
}

#pragma mark -
#pragma mark ---- toolbar ----

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag 
{
	#pragma unused(toolbar)
	#pragma unused(flag)
	
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ([itemIdentifier isEqualToString:@"TabField"]) {
        [item setPaletteLabel:@"Tab Label"];
        [item setLabel:@"Tab Label"];
        [item setView:tabField];
        [item setMinSize:NSMakeSize(100, [tabField frame].size.height)];
        [item setMaxSize:NSMakeSize(500, [tabField frame].size.height)];
    } else if ([itemIdentifier isEqualToString:@"DrawerItem"]) {
        [item setPaletteLabel:@"Configuration"];
        [item setLabel:@"Configuration"];
        [item setToolTip:@"Configuration"];
        [item setImage:[NSImage imageNamed:@"32x32_log"]];
        [item setTarget:drawer];
        [item setAction:@selector(toggle:)];
    }
    
    return [item autorelease];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar 
{
	#pragma unused(toolbar)
	
    return [NSArray arrayWithObjects:@"TabField",
			NSToolbarFlexibleSpaceItemIdentifier,
			@"DrawerItem",
			nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar 
{
	#pragma unused(toolbar)
	
    return [NSArray arrayWithObjects:@"TabField",
			NSToolbarFlexibleSpaceItemIdentifier,
			@"DrawerItem",
			nil];
}

- (IBAction)toggleToolbar:(id)sender 
{
	#pragma unused(sender)
	
   // JM [[[self window] toolbar] setVisible:![[[self window] toolbar] isVisible]];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	#pragma unused(theItem)
	
    return YES;
}

#pragma mark MGSRequestViewController delegate messages
/*
 
 close tab for the request view
 
 delegate message
 
 */
- (void)closeTabForRequestView:(MGSRequestViewController *)requestView
{
	// don't want to close last tab
	if ([tabView numberOfTabViewItems] <= 1) {
		return;
	}
	
	NSTabViewItem *tabViewItem = [self tabViewItemForRequestView:requestView];
	if (tabViewItem) {
		[self closeTabViewItem:tabViewItem];
	}
}

/*
 
 request view action will change
 
 delegate message
 
 */
- (void)requestViewActionWillChange:(MGSRequestViewController *)requestViewController
{
	// stop observing the request action
	[self removeRequestViewActionObservers:requestViewController];
}
/*
 
 request view action changed
 
 delegate message
 
 */
- (void)requestViewActionDidChange:(MGSRequestViewController *)requestViewController
{

	NSTabViewItem *tabViewItem = [self tabViewItemForRequestView:requestViewController];
	
	// set tab label
	MGSScript *script = [requestViewController.actionSpecifier script];
	MGSNetClient *netClient = [requestViewController.actionSpecifier netClient];
	NSString *tabName = nil;
	
	// if script is nil then no tasks exist for client
	if (script) {
		tabName = [NSString stringWithFormat:@"%@: %@", [netClient serviceShortName], [script name]];
	} else {
		tabName = [NSString stringWithFormat:@"%@", [netClient serviceShortName]];
	}
	[tabViewItem setLabel:tabName];
	
	// the tab bar observes the identifiers icon property
	[requestViewController setIcon:[netClient hostIcon]];
	
	// observer the request action
	[self addRequestViewActionObservers:requestViewController];
	
	// trigger the tab selection process
	[self triggerTabViewItemSelected];
}

#pragma mark MGSRequestTabScrollView delegate messages
/*
 
 view will resize subviews with old size
 
 its easier for the delegate to compute what's required than it is for the view
 
 */
- (void)view:(NSView *)senderView willResizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{	
	if (senderView == requestTabScrollView) {
		MGSRequestViewController *requestViewController = [self selectedRequestViewController];

		[requestTabScrollView sizeDocumentWidthForRequestViewController:requestViewController withOldSize:oldBoundsSize];
	}
}
/*
 
 view did resize subviews with old size
 
 its easier for the delegate to compute what's required than it is for the view
 
 */
- (void)view:(NSView *)senderView didResizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{	
	if (senderView == requestTabScrollView) {
		MGSRequestViewController *requestViewController = [self selectedRequestViewController];

		[requestTabScrollView resetDocumentWidthForRequestViewController:requestViewController withOldSize:oldBoundsSize];
	}	
}

@end

@implementation MGSRequestTabViewController (PRIVATE)

/*
 
 create request view within tab view item
 
 */
- (void)createRequestViewWithinTabView:(NSTabViewItem *)tabViewItem
{
	// create the request view controller 
	MGSRequestViewController *requestViewController = [self newRequestViewController];
	[tabViewItem setIdentifier:requestViewController];
	
	// size the scrollview document to accomodate the requestView.
	// normally this occurs when we resize the scrollview.
	// but here we need to call it manually as we are adding the new view to the tabview.
	[requestTabScrollView sizeDocumentWidthForRequestViewController:requestViewController withOldSize:[[requestViewController view] bounds].size];
	
	// display the request view
	[tabViewItem setView: [requestViewController view]];
}
/*
 
 new request view controller
 
 */
- (MGSRequestViewController *)newRequestViewController
{
	// create the request view controller 
	MGSRequestViewController *requestViewController = [[MGSRequestViewManager sharedInstance] newController];
	requestViewController.observesInputModifications = NO;
	[requestViewController setDelegate:self];
	[[requestViewController inputViewController] setAllowLock:YES];
	[[requestViewController inputViewController]  setAllowDetach:YES];
	(void)[requestViewController view];
	
	return requestViewController;
}

/*
 
 close tab view item
 
 */
- (void)closeTabViewItem:(NSTabViewItem *)tabViewItem
{
	[self freeTabViewItemResources:tabViewItem];
	
	// close tab if it is not the last
	if ([tabView numberOfTabViewItems] > 1) {
		[tabView removeTabViewItem:tabViewItem];
	}
	
}

/*
 
 free tab view item resources
 
 */
- (void)freeTabViewItemResources:(NSTabViewItem *)tabViewItem
{
	if (!tabViewItem) {
		MLog(DEBUGLOG, @"closing nil tabview");
		return;
	}
	
	// remove our request view controller from singleton handler
	MGSRequestViewController *requestViewController = [tabViewItem identifier];
	[[MGSRequestViewManager sharedInstance] removeObject:requestViewController];
	
	// remove observers
	[self removeRequestViewActionObservers:requestViewController];
	[requestViewController setActionSpecifier:nil];
	
	[tabViewItem setIdentifier:nil];
}



/* 
 
 trigger tab view item selected
 
 */
- (void)triggerTabViewItemSelected
{
	[self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
}

// if action defined tell delegate that tab selected
- (void)informDelegateTabSelected
{
	MGSTaskSpecifier *action = [self actionSpecifierForSelectedTab];
	if (action && _delegate && [_delegate respondsToSelector:@selector(tabViewActionSelected:)]) {
		[_delegate tabViewActionSelected:[self actionSpecifierForSelectedTab]];
	}	
}

/*
 
 set the MGSTaskSpecifier for the tabViewItem
 
 */
- (void)setActionSpecifier:(MGSTaskSpecifier *)action forTabViewItem:(NSTabViewItem *)tabViewItem
{
	// get the request view controller
	MGSRequestViewController *requestViewController = [tabViewItem identifier];
	
	// if none available then create one.
	if (!requestViewController) {
		[self createRequestViewWithinTabView:tabViewItem];
		requestViewController = [tabViewItem identifier];
	}
	
	// time to go...
	if (!requestViewController) {
		return;
	}
	
	// if the selected tab action is currently active then create new tab for action
	if ([requestViewController.actionSpecifier isProcessing]) {
		[self addTabWithActionSpecifier:action];
		return;
	}
	
	// set the new action.
	// the action script may be nil at startup in which case 
	// we leave the requestViewController as is as it objects to the nil script.
	if (action.script) {
		requestViewController.actionSpecifier = action;
	}
}



// configure the tab bar by reading use defaults
// into the configuration control and then  setting
// the control state
//
- (void)configureTabBarInitially
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	
	[popUp_style selectItemWithTitle:[defaults stringForKey:MGSDefaultTabStyle]];
	[popUp_orientation selectItemWithTitle:[defaults stringForKey:MGSDefaultTabOrientation]];
	[popUp_tearOff selectItemWithTitle:[defaults stringForKey:MGSDefaultTabTearOff]];
	[button_canCloseOnlyTab setState:[defaults boolForKey:MGSDefaultTabCanCloseOnlyTab]];
	[button_disableTabClosing setState:[defaults boolForKey:MGSDefaultTabDisableTabClosing]];
	[button_hideForSingleTab setState:[defaults boolForKey:MGSDefaultTabHideForSingleTab]];
	[button_showAddTab setState:[defaults boolForKey:MGSDefaultTabShowAddTabButton]];
	[button_sizeToFit setState:[defaults boolForKey:MGSDefaultTabSizeToFit]];
	[button_useOverflow setState:[defaults boolForKey:MGSDefaultTabUseOverflowMenu]];
	[button_automaticallyAnimate setState:[defaults boolForKey:MGSDefaultTabAutomaticallyAnimates]];
	[button_allowScrubbing setState:[defaults boolForKey:MGSDefaultTabAllowScrubbing]];
	
	
	[self configStyle:popUp_style];
	[self configOrientation:popUp_orientation];
	[self configCanCloseOnlyTab:button_canCloseOnlyTab];
	[self configDisableTabClose:button_disableTabClosing];
	[self configHideForSingleTab:button_hideForSingleTab];
	[self configAddTabButton:button_showAddTab];
	[self configTabMinWidth:textField_minWidth];
	[self configTabMaxWidth:textField_maxWidth];
	
	
	[self configTabOptimumWidth:textField_optimumWidth];
	[self configTabSizeToFit:button_sizeToFit];
	[self configTearOffStyle:popUp_tearOff];
	[self configUseOverflowMenu:button_useOverflow];
	[self configAutomaticallyAnimates:button_automaticallyAnimate];
	[self configAllowsScrubbing:button_allowScrubbing];	
	
	[self addDefaultTabs];
}


/*
 
 add request view action observers
 
 */
- (void)addRequestViewActionObservers:(MGSRequestViewController *)requestViewController
{
	// observe the action's net client availability
	[requestViewController.actionSpecifier addObserver:self forKeyPath:MGSKeyPathNetClientHostStatus options:0 context:nil];
	
}


/*
 
 remove request view action observers
 
 */
-(void)removeRequestViewActionObservers:(MGSRequestViewController *)requestViewController
{ 
	if ([requestViewController actionSpecifier]) {
		
		// remove observers
		@try{
			[[requestViewController actionSpecifier] removeObserver:self forKeyPath:MGSKeyPathNetClientHostStatus];
		}
		@catch (NSException *e) {
			MLog(RELEASELOG, @"%@", [e reason]);
		}
		MLog(DEBUGLOG, @"action observer removed");
	}
}

@end


