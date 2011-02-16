//
//  MGSTaskExecuteWindowController.m
//  Mother
//
//  Created by Jonathan on 20/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSTaskExecuteWindowController.h"
#import "MGSNotifications.h"
#import "MGSToolbarController.h"
#import "MGSRequestViewManager.h"
#import "MGSRequestViewController.h"
#import "MGSOutputRequestViewController.h"
#import "MGSNetClient.h"
#import "MGSNetClientContext.h"

static int toolbarID = 0;

const char MGSContextTaskProcessing;

// class extension
@interface MGSTaskExecuteWindowController()
- (void)terminateAlertSheetDidEnd:(NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
@end

@implementation MGSTaskExecuteWindowController 

@synthesize requestViewController;
@synthesize toolbarController = _toolbarController;
@synthesize toolbarStyle = _toolbarStyle;

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	[[self window] setDelegate:self];
	
	// load the toolbar nib
	_toolbarController = [[MGSToolbarController alloc] init];
	_toolbarController.window = [self window];
	_toolbarController.style = self.toolbarStyle;
	_toolbarController.identifier = [NSString stringWithFormat:@"action %i", toolbarID++];	// must be unique otherwise toolbars become synchronised!
	[_toolbarController loadNib];
	[_toolbarController setDelegate:self];
	
	// note that when these were defined as objects within the nib
	// it caused horrible intermittent crashes.
	// so having a controller in a nib which loads its own nib seems
	// to be a recipe for disaster.
	requestViewController = [[MGSRequestViewManager sharedInstance] newController];
	requestViewController.delegate = self;
	[requestViewController view]; // load the view
	
	// establish observers
	[requestViewController addObserver:self forKeyPath:@"isProcessing" options:0 context:(void *)&MGSContextTaskProcessing];
	
	// notifications
	// these could probably been have issued via the responder chain
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(executeSelectedTask:) name:MGSNoteExecuteSelectedTask object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSelectedTask:) name:MGSNoteStopSelectedTask object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(suspendSelectedTask:) name:MGSNoteSuspendSelectedTask object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeSelectedTask:) name:MGSNoteResumeSelectedTask object:[self window]];

	_terminateSheetDisplayed = NO;
	_closeWhenTaskFinishes = NO;
	
}

#pragma mark View handling

/*
 
 active result view controller
 
 subclasses must override to return currently active result view controller
 
 */
- (MGSResultViewController *)activeResultViewController
{
	return self.requestViewController.outputViewController.resultViewController;; 
}

/*
 
 active request view controller
 
 subclasses must override to return currently active request view controller
 
 */
- (MGSRequestViewController *)activeRequestViewController
{
	return self.requestViewController;
}

/*
 
selected action specifier
 
 */
- (MGSTaskSpecifier *)selectedActionSpecifier
{
	return self.requestViewController.actionSpecifier;
}


#pragma mark notifications
/*
 
 execute selected action
 
 */
- (void)executeSelectedTask:(NSNotification *)notification
{	
	if (![self notificationObjectIsWindow:notification]) return;
	[self.requestViewController executeScript:self];
}

/*
 
 terminate execution of selected action
 
 */
- (void)terminateSelectedTask:(NSNotification *)notification
{	
	if (![self notificationObjectIsWindow:notification]) return;
	[self.requestViewController terminateScript:self];
}

/*
 
 suspend execution of selected action
 
 */
- (void)suspendSelectedTask:(NSNotification *)notification
{
	if (![self notificationObjectIsWindow:notification]) return;
	[self.requestViewController suspendScript:self];
}

/*
 
 suspend execution of selected action
 
 */
- (void)resumeSelectedTask:(NSNotification *)notification
{	
	if (![self notificationObjectIsWindow:notification]) return;
	[self.requestViewController resumeScript:self];
}

#pragma mark MGSRequestViewController delegate messages
/*
 
 request view action changed
 
 delegate message
 
 */
- (void)requestViewActionDidChange:(MGSRequestViewController *)requestController
{
	// post action change notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteActionSelectionChanged object:[self window]  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:requestController.actionSpecifier, MGSActionKey, nil]];
	
}

/*
 
 request view action will change
 

 */
- (void)requestViewActionWillChange:(MGSRequestViewController *)requestViewController
{
	#pragma unused(requestViewController)
}
/*
 
 notification object is window
 
 */
- (BOOL)notificationObjectIsWindow:(NSNotification *)notification
{
	id object = [notification object];
	return object == [self window] ? YES : NO;
}

#pragma mark NSWindow delegate messages

/*

 window should close
 
 */
- (BOOL)windowShouldClose:(id)window
{
	#pragma unused(window)
	
	// check if task executing
	if ([requestViewController isProcessing]) {
		_terminateSheetDisplayed = YES;
		NSBeginAlertSheet(
						  NSLocalizedString(@"Task is running.", @"Alert sheet text"),	// sheet message
						  NSLocalizedString(@"Stop", @"Alert sheet button text"),              //  default button label
						  nil,             //  alternate button label
						  NSLocalizedString(@"Cancel", @"Alert sheet button text"),              //  other button label
						  [self window],	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  @selector(terminateAlertSheetDidEnd:returnCode:contextInfo:),					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  NULL,       // context info
						  NSLocalizedString(@"The task must be stopped before the window can close.\n\nIf you do not stop the task the window will close when the task terminates.", @"Alert sheet text"),	// additional text
						  nil);
		return NO;
	}
	
	return YES;
}

/*
 
 terminate alert sheet ended
 
 */
- (void)terminateAlertSheetDidEnd:(NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	#pragma unused(contextInfo)
	
	[sheet orderOut:self];
	_terminateSheetDisplayed = NO;
	
	switch (returnCode) {
			
			// continue
		case NSAlertDefaultReturn:
			if ([requestViewController isProcessing]) {
				_closeWhenTaskFinishes = YES;
				[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAppToggleExecuteTerminateTask object:[self window] userInfo:nil];
			}
			break;
			
			// cancel stop
		case NSAlertOtherReturn:
			break;
	}
}

#pragma mark KVO
/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &MGSContextTaskProcessing) {
		
		// processing stopped while alert sheet displayed
		if (![requestViewController isProcessing] ) {
			
			if (_terminateSheetDisplayed) {
				// cannot just order the attached sheet out as this prevents other sheets from being displayed.
				[NSApp endSheet:[[self window] attachedSheet]];
				[[self window] performSelector:@selector(performClose:) withObject:self afterDelay:0.0];
			} else if (_closeWhenTaskFinishes) {
				_closeWhenTaskFinishes = NO;
				[[self window] performClose:self];
			}

		}
		
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Menu Handling

/*
 
 validate menu item
 
 */

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (![super validateMenuItem:menuItem]) {
		return NO;
	}
	
	MGSTaskSpecifier *actionSpecifier = [self selectedActionSpecifier];
	if (!actionSpecifier) return NO;
	
	NSAssert(actionSpecifier, @"action specifier is nil");
	
	// get net client context for this window
	MGSNetClientContext *context = [[actionSpecifier netClient] contextForWindow:[self window]];
	NSAssert(context, @"window net client context is nil");
	
	// enable menu if run mode is not configure
	//BOOL enableMenu = context.runMode == kMGSMotherRunModeConfigure ? NO : YES;
	
	// menu selector
	SEL theAction = [menuItem action];
	
	if (theAction == @selector(newDocument:)) {
		return NO;
	} else if (theAction == @selector(openFile:)) {
		return NO;
	}
	
	return YES;
}

@end
