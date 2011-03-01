//
//  MGSParameterViewHandler.m
//  Mother
//
//  Created by Jonathan on 06/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
//  The handler coordinates the creation and display of
//  the MGSParameterViews needed to display the parameters
//
// This class could really be called MGSParameterSplitViewController
//
#import "MGSParameterViewManager.h"
#import "MGSRoundedView.h"
#import "MGSScriptParameterManager.h"
#import "MGSScriptParameter.h"
#import "NSView_Mugginsoft.h"
#import "NSSplitView_Mugginsoft.h"
#import "MGSParameterSplitView.h"
#import "MGSParameterEndViewController.h"
#import "MGSParameterView.h"
#import "MGSScript.h"
#import "MGSTaskSpecifier.h"
#import "MGSNotifications.h"
#import "MGSMotherWindowController.h"

@interface MGSParameterViewManager(Private)
- (MGSParameterViewController *)createView;
- (void)destroyViews;
- (void)createViews;
- (void)showViewAtIndex:(int)index;
- (void)addSplitViewSubview:(NSView *)view;
- (void)removeSplitViewSubview:(NSView *)view;
- (void)addSplitViewParameterSubview:(NSView *)view;
- (void)updateViewLocations;
- (MGSParameterViewController *)createViewForParameterAtIndex:(NSInteger)index;
- (void)addEndViewToSplitView;
- (void)replaceSplitViewSubview:(NSView *)subView with:(NSView *)newView;
- (void)addSplitViewSubview:(NSView *)view positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView;
@end

@implementation MGSParameterViewManager

@synthesize mode = _mode;
@synthesize delegate = _delegate;
@synthesize actionViewController = _actionViewController;

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		_viewControllers = [NSMutableArray arrayWithCapacity:1];
		self.mode = MGSParameterModeInput;
	}
	return self;
}

/*
 
 set action view controller 
 
 */
- (void)setActionViewController:(MGSActionViewController *)controller
{
	_actionViewController = controller;
	_actionViewController.delegate = self;
	
	MGSScript *script = [_actionViewController.action script];
	[self setScriptParameterHandler: [script parameterHandler]];
	
	// put action view at top of splitview
	[self replaceSplitViewSubview:[[splitView subviews] objectAtIndex:0]  with:[_actionViewController view]];
}

/*
 
 awake from nib
 
 */
- (void) awakeFromNib
{
	// nib's owner also gets called.
	// only want this to be processed once
	if (_nibLoaded) {
		return;
	}
	_nibLoaded = YES;
	
	// this view will be replaced by parameter view
	NSAssert(([[splitView subviews] count] == 2), @"splitview subviews count should be 2");
	_splitSubView2 = [[splitView subviews] objectAtIndex:1];
}

/*
 
 commit all pending edits
 
 */
- (BOOL)commitPendingEdits
{
	for (MGSParameterViewController *controller in _viewControllers) {
		if (![controller commitEditing]) {
			return NO;
		}
	}
	return YES;
}

/*
 
 validate the parameters
 
 */
- (BOOL)validateParameters:(MGSParameterViewController **)parameterViewController
{
	NSInteger idx = 0;
	for (MGSParameterViewController *controller in _viewControllers) {
		if (![controller isValid]) {
			*parameterViewController = controller;
			return NO;
		}
		idx++;
	}
	
	return YES;
}
#pragma mark MGSParameterViewController delegate methods


/*
 
 set script parameter handler
 
 */
-(void)setScriptParameterHandler:(MGSScriptParameterManager *)aScriptParameterHandler
{
	NSAssert(aScriptParameterHandler, @"script parameter handler is null");
	_scriptParameterHandler = aScriptParameterHandler;
	
	// destroy current parameter views
	[self destroyViews];
	
	// create new views for parameters
	[self createViews];
}

/*
 
 close parameter view
 
 */
- (void)closeParameterView:(MGSParameterViewController *)viewController
{	
	NSInteger idx = -1;
	
	if (!viewController) return;
	
	// get index of controller to remove
	for (NSUInteger i = 0; i < [_viewControllers count]; i++) {
		if ([[_viewControllers objectAtIndex:i] isEqual:viewController]) {
			idx = (NSInteger)i;
			break;
		}
	}
	if (-1 == idx) return;
	
	// remove the script parameter and view controller
	[_scriptParameterHandler removeItemAtIndex:idx];
	[_viewControllers  removeObject:viewController];
	
	// remove the subview
	[self removeSplitViewSubview:[viewController view]];
	
	// update view banners
	[self updateViewLocations];
	
	// inform delegate that view closed
	if (_delegate && [_delegate respondsToSelector:@selector(parameterViewDidClose:)]) {
		[_delegate parameterViewDidClose:viewController];
	}
}

/*
 
 reset to default value
 
 */
- (void)resetToDefaultValue
{
	for (MGSParameterViewController *viewController in _viewControllers) {
		[viewController resetToDefaultValue]; 
	}	
}

/*
 
 controller view clicked

 this message is sent whenever a click occurs anywhere in a parameter view or
 the top action view
 
 */
- (void)controllerViewClicked:(MGSRoundedPanelViewController *)controller
{
	BOOL showMenu = NO;
	
	NSEvent *event = [NSApp currentEvent];
	switch ([event type]) {
		case NSLeftMouseDown:					
			
			// double clicking triggering max/min tab may interefere with running task on double click 
			if ([event clickCount] == 2 && NO) {
				[NSApp sendAction:@selector(subviewDoubleClick:) to:nil from:controller];
				return;
			}
			
			if (([event modifierFlags] & NSControlKeyMask)) {
				showMenu = YES;
			}

			// controller is already highlighted
			if (controller.isHighlighted) {
				break;
			}
			
			// dehighlight all views
			[self setHighlightForAllViews:NO];
			
			// highlight the view
			[controller setIsHighlighted:YES];
			
			break;
				
		case NSRightMouseDown:
			showMenu = YES;
			break;
	}
	
	if (showMenu) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MGSShowTaskTabContextMenu object:event userInfo:nil];
	}
}

/*
 
 set highlight for all views
 
 */
- (void)setHighlightForAllViews:(BOOL)aBool
{
	// parameter views
	for (MGSParameterViewController *viewController in _viewControllers) {
		if ([viewController isHighlighted] != aBool) {
			[viewController setIsHighlighted:aBool]; 
		}
	}
	
	// view
	if (_actionViewController.isHighlighted != aBool) {
		[_actionViewController setIsHighlighted:aBool]; 
	}
}

/*
 
 highlight the action view
 
 */
- (void)highlightActionView
{
	[self controllerViewClicked:_actionViewController];
}

/*
 
 reset enabled changed
 
 */
- (void)parameterViewController:(MGSParameterViewController *)sender didChangeResetEnabled:(BOOL)resetEnabled
{
	#pragma unused(sender)
	#pragma unused(resetEnabled)
	
	BOOL enabled = NO;
	for (MGSParameterViewController *viewController in _viewControllers) {
		if (viewController.resetEnabled) {
			enabled = YES;
			break;
		}
	}
	[_actionViewController setResetEnabled:enabled];
}

/*
 
 add parameter view
 
 */
- (MGSParameterViewController *)addParameter
{	
	// create script parameter and add to handler array
	MGSScriptParameter *parameter = [MGSScriptParameter new];
	[_scriptParameterHandler addItem:parameter];
	
	// create new view for parameter
	NSInteger idx = [_scriptParameterHandler count] - 1;
	MGSParameterViewController *viewController = [self createViewForParameterAtIndex:idx];

	// update the view locations
	[self updateViewLocations];
	
	return viewController;
}

/*
 
 remove the last parameter
 
 */
- (void)removeLastParameter
{
	[self closeParameterView: [_viewControllers lastObject]];
}

/*
 
 highlight the parameter
 
 */
- (void)highlightParameter:(MGSParameterViewController *)controller
{
	[self controllerViewClicked:controller];
}


/*
 
 highlight the parameter at index
 
 */
- (void)highlightParameterAtIndex:(NSUInteger)idx
{
	if (idx < [_viewControllers count]) {
		[self highlightParameter:[_viewControllers objectAtIndex:idx]];
	}
}
@end

@implementation MGSParameterViewManager(Private)

/*
 
 creat view for parameter at index
 
 */
- (MGSParameterViewController *)createViewForParameterAtIndex:(NSInteger)idx
{
	// create new view
	// we are loading views from a nib here so the outlets
	// will not be available until awakeFromNib returns
	MGSParameterViewController *viewController = [self createView];

	// pass script parameters to the controller
	viewController.scriptParameter = [_scriptParameterHandler itemAtIndex:idx];
	[viewController setDisplayIndex:idx+1];		
	
	// show view
	[_viewControllers insertObject:viewController atIndex:idx];	
	[self showViewAtIndex: idx];
	return viewController;
}

/*
 
 update view locations.
 
 */
- (void)updateViewLocations
{
	// loop through views
	for (NSUInteger i = 0; i < [_viewControllers count]; i++) {
		MGSParameterViewController *viewController = [_viewControllers objectAtIndex:i];
		MGSParameterView *parameterView = [viewController parameterView];
		NSString *format;
		
		// set view left banner
		if (MGSParameterModeInput == _mode) {
			//viewController.parameterName = @"Name";	// this will be bound later
		} else if (MGSParameterModeEdit == _mode) {
			//format = NSLocalizedString(@"Input %i", @"Parameter left banner edit mode");
			//viewController.parameterName = [NSString stringWithFormat:format, i + 1];
		} else {
			NSAssert(NO, @"invalid mode");
		}
		
		// set view right banner
		//format = NSLocalizedString(@"%i of %i", @"Parameter right banner format string");
		//viewController.bannerRight = [NSString stringWithFormat:format, i + 1, [_scriptParameterHandler count]];
		format = NSLocalizedString(@"%i", @"Parameter right banner format string");
		viewController.bannerRight = [NSString stringWithFormat:format, i + 1];
		
		if (i != [_viewControllers count]-1) {
			[parameterView setHasConnector:YES];
		} else {
			[parameterView setHasConnector:NO];
		}
	}
}

/*
 
 replace splitview subview
 
 new view must have its frame already set
 
 */
- (void) replaceSplitViewSubview:(NSView *)subView with:(NSView *)newView
{
	[splitView replaceSubview:subView with:newView];
	//[splitView autoSizeHeight];
}

/*
 
 add subview to splitview
 
 */
- (void)addSplitViewSubview:(NSView *)view
{
	[splitView addSubview:view];
	//[splitView autoSizeHeight];
}


/*
 
 add parameter subview to splitview
 
 */
- (void)addSplitViewParameterSubview:(NSView *)view
{
	// get last splitview subview
	NSView *lastView = [[splitView subviews] lastObject];
	
	// always want our view at the end of our subview array.
	// if end view exists insert our view before it.
	if (lastView == [_endViewController view]) {
		[self addSplitViewSubview:view positioned:NSWindowAbove relativeTo:lastView];
	} else {
		// add additional subview
		[self addSplitViewSubview:view];
	}	
}

/*
 
 add splitview subview in view hierarchy relative to another view
 
 */
- (void)addSplitViewSubview:(NSView *)view positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView
{
	[splitView addSubview:view positioned:place relativeTo:otherView];
	//[splitView autoSizeHeight];	
}

/* 
 
 add end view to split view
 
 our splitview must always have a specific end view
 
 */
- (void)addEndViewToSplitView
{
	NSInteger parameterCount = [_scriptParameterHandler count];
	
	if (parameterCount > 0) {
		
		// lazy controller creation
		if (!_endViewController) {
			_endViewController = [[MGSParameterEndViewController alloc] init];
		}

		// if our last view is not the end view then add one
		NSView *lastView = [[splitView subviews] lastObject];
		if (lastView != [_endViewController view]) {
			[self addSplitViewSubview:[_endViewController view]];
		}		
	}
	
}
/*
 
 remove subview from splitview
 
 */
- (void)removeSplitViewSubview:(NSView *)view
{
	// maintain two views in out splitview
	if (2 == [[splitView subviews] count]) {
		NSView *emptyView = [[NSView alloc] initWithFrame:[view frame]];
		[self replaceSplitViewSubview:view  with:emptyView];
	} else {
		[view removeFromSuperview];
		//[splitView autoSizeHeight];
	}
}
/*
 
 create new parameter sub view and add to the splitview
 
 */
- (MGSParameterViewController *)createView
{
	// create new view
	MGSParameterViewController *viewController = [[MGSParameterViewController alloc] initWithMode:self.mode];
	[viewController setDelegate:self];
	
	// load the view now.
	// sending the view message will trigger view loading.
	// -awakeFromNib will be called before this message returns.
	// lazy loading can lead to lots of problems if it is not anticipated.
	[viewController view];
	
	// our view controller no references a fully initialised object
	return viewController;
}

/*
 
 show view at index.
 
 */
- (void) showViewAtIndex:(int)idx
{
	MGSParameterViewController *viewController = [_viewControllers objectAtIndex:idx];
	NSView *view = [viewController view];
	
	// determine if first sub view contains action view
	BOOL firstSubviewIsAction = _actionViewController ? YES : NO;
	
	// replace second subview.
	// want to keep at least two subviews in out splitview.
	if ([_viewControllers count] == 1) {
		NSAssert(([[splitView subviews] count] == 2), @"splitview subviews count should be 2");
		NSAssert(_splitSubView2, @"splitview sub view 2 is nil");
		
		// if no action view then make top splitview
		// narrow to provide margin for first parameter view below it
		if (!firstSubviewIsAction) {
			NSView *firstView = [[splitView subviews] objectAtIndex:0];
			NSSize firstViewSize = [firstView frame].size;
			firstViewSize.height = 6;
			[firstView setFrameSize:firstViewSize];
		}
		
		// first view always allocated.
		// either contains action view or is empty to provide top margin for parameter list
		idx = 1;
		
		// replace existing view with new view
		[self replaceSplitViewSubview:[[splitView subviews] objectAtIndex:idx]  with:view];
	} else {
		[self addSplitViewParameterSubview:view];
	}
	
	// make sure that our splitview subviews are terminated
	[self addEndViewToSplitView];
}

/*
 
 create views
 
 create a view for each script parameter.
 
 this message is sent for all modes.
 
 */
- (void)createViews
{
	int i;
	
	NSAssert([_viewControllers count] == 0, @"view controllers array not empty");
	
	// show a view for each parameter
	for (i = 0; i < [_scriptParameterHandler count]; i++) {
		[self createViewForParameterAtIndex:i];
	}
	
	// update views with new locations
	[self updateViewLocations];
}

/*
 
 destroy views
 
 */
- (void)destroyViews
{
	MGSParameterViewController *viewController;
	int i;
	
	// remove the end view
	if ([_endViewController view]) {
		[[_endViewController view] removeFromSuperviewWithoutNeedingDisplay];
	}
	
	// remove the existing views from the splitview
	for (i = [_viewControllers count]-1; i >= 0 ; i--) {
		viewController = [_viewControllers objectAtIndex:i];
		viewController.scriptParameter = nil;	// no longer references a parameter
		NSView *view = [viewController view];
		
		// need to keep a minimum of 2 subviews in the splitview
		if (i == 0) {
			NSAssert(([[splitView subviews] count] == 2), @"splitview subviews count should be 2");
			[splitView replaceSubview:view withViewSizedAsOld: _splitSubView2];
		} else {
			[view removeFromSuperviewWithoutNeedingDisplay];
		}
		
		// remove controller
		[_viewControllers removeObjectAtIndex:i];
	}
	NSAssert([_viewControllers count] == 0, @"view controllers array not empty");
}

/*
 
 hide views
 
 */
/*
- (void)hideViews
{
	MGSParameterViewController *viewController;
	int i;
	
	if ([_endViewController view]) {
		[[_endViewController view] removeFromSuperviewWithoutNeedingDisplay];
	}
	
	// remove the existing views from the splitview
	for (i = [_viewControllers count]-1; i >= 0 ; i--) {
		viewController = [_viewControllers objectAtIndex:i];
		viewController.scriptParameter = nil;	// no longer references a parameter
		NSView *view = [viewController view];
		
		// need to keep a minimum of 2 subviews in the splitview
		if (i == 0) {
			NSAssert(([[splitView subviews] count] == 2), @"splitview subviews count should be 2");
			[splitView replaceSubview:view withViewSizedAsOld: _splitSubView2];
		} else {
			[view removeFromSuperviewWithoutNeedingDisplay];
		}
		
		// add view to cache
		[_viewControllers removeObjectAtIndex:i];
		[_viewControllerCache addObject: viewController];
	}
	NSAssert([_viewControllers count] == 0, @"view controllers array not empty");
}
*/
/*
 
 show views
 
 */
/*
- (void)showViews
{
	MGSParameterViewController *viewController;
	int i;
	
	NSAssert([_viewControllers count] == 0, @"view controllers array not empty");
	
	// show a view for each parameter
	for (i = 0; i < [_scriptParameterHandler count]; i++) {
		
		// use cached view if available		
		if ([_viewControllerCache count] > 0) {
			viewController = [_viewControllerCache objectAtIndex:0];
			[_viewControllerCache removeObjectAtIndex:0];			
		} else {
			// create new view
			// we are loading views from a nib here so the outlets
			// will not be available until awakeFromNib returns
			viewController = [self createView];
		}
		
		// pass script parameters to the controller
		viewController.scriptParameter = [_scriptParameterHandler itemAtIndex:i];
		[viewController setDisplayIndex:i+1];		
		
		// show view
		[_viewControllers insertObject:viewController atIndex:i];	
		[self showViewAtIndex: i];
	}
	
	// to enable resizing of last parameter need to add
	// a dummy view to end of splitview
	if (i > 0) {
		if (!_endViewController) {
			_endViewController = [[MGSParameterEndViewController alloc] init];
		}
		[self addSplitViewSubview:[_endViewController view]];
	}
	
	[splitView setNeedsDisplay:YES];
	
	[self updateViewBanners];
}
*/



@end

#pragma mark NSSplitView delegate messages
@implementation MGSParameterViewManager(SplitViewDelegate)

/*
 
 get additional rect to be used to drag splitview
 
 */
- (NSRect)splitView:(NSSplitView *)aSplitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{	
	#pragma unused(aSplitView)
	#pragma unused(dividerIndex)

	
	// the NSSPlitView subclass handles all of this
	return NSZeroRect;
}

/*
 
 splitview has changed size
 
 */
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	#pragma unused(oldSize)
	
	// layout out subviews
	if ([sender isKindOfClass:[MGSParameterSplitView class]]) {
		[(MGSParameterSplitView *)sender adjustSubviews];
	} else {
		[sender adjustSubviews];
	}
}
@end
