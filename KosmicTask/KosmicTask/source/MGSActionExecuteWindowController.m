//
//  MGSActionExecuteWindowController.m
//  Mother
//
//  Created by Jonathan on 02/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSActionExecuteWindowController.h"
#import "MGSNetClient.h"
#import "MGSNetClientContext.h"
#import "MGSTaskSpecifier.h"
#import "MGSRequestViewController.h"
#import "MGSInputRequestViewController.h"
#import "MGSOutputRequestViewController.h"
#import "MGSApplicationMenu.h"
#import "MGSNotifications.h"
#import "NSWindow_Mugginsoft.h"

static NSString *MGSContextNetClientUseSSL = @"MGSContextNetClientUseSSL";


@implementation MGSActionExecuteWindowController

@synthesize actionExecuteWindow = _actionExecuteWindow;
@synthesize netClient = _netClient;
@synthesize openPanelController = _openPanelController;

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
}
/*
 
 selected action specifier
 
 needs to be overriden
 
 */
- (MGSTaskSpecifier *)selectedActionSpecifier
{
	return nil;
}

/*
 
 set net client
 
 */
- (void)setNetClient:(MGSNetClient *)netClient
{
	if (_netClient) {
		[self removeClientObservers];
	}

	_netClient = netClient;

	// setup window
	NSURL *url = [NSURL fileURLWithPath:@"anything"];
	[[self window] setRepresentedURL:url];
	NSImage *img = [_netClient hostIcon];
	[img setSize:NSMakeSize(16, 16)];  // scale your image if needed (and maybe should use userSpaceScaleFactor)
	[[[self window] standardWindowButton:NSWindowDocumentIconButton] setImage:img];
	
	// add observers
	[_netClient addObserver:self forKeyPath:@"useSSL" options:NSKeyValueObservingOptionInitial context:MGSContextNetClientUseSSL];

	// add context
	[_netClient addContextForWindow:[self window]];
}

/*
 
 observe value for key path 
 
 sub classes will need to call this implementation
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(change)
	
	// net client SSL status change
	if (context == MGSContextNetClientUseSSL) {
		[self showNetClientSecurityStateInTitleBar];
	}
}

/*
 
 show net client security state in title bar
 
 */
- (void)showNetClientSecurityStateInTitleBar
{
	if (!_netClient) return;
	
	// set the security icon
	[self.actionExecuteWindow setTitleBarIcon:[_netClient securityIcon]];

}

/*
 
 remove client observers
 
 */
- (void)removeClientObservers
{
	@try{
		[_netClient removeObserver:self forKeyPath:@"useSSL"];
	} 
	@catch (NSException *e) {
		MLog(RELEASELOG, @"%@", [e reason]);
	}
}


/*
 
 window will close
 
 */
- (void)windowWillClose:(NSNotification *)note
{
	#pragma unused(note)
	
	[self removeClientObservers];
	
	// add context
	[_netClient removeContextForWindow:[self window]];
}

#pragma mark Actions 
/*
 
 mother execute action
 
 in general this message will be sent up the responder chain
 
 */
- (IBAction)requestExecuteTask:(id)sender
{
#pragma unused(sender)
		
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAppToggleExecutePauseTask object:[self window] userInfo:nil];
}

/*
 
 mother suspend action
 
 in general this message will be sent up the responder chain
 
 */
- (IBAction)requestSuspendTask:(id)sender
{
#pragma unused(sender)
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAppToggleExecutePauseTask object:[self window] userInfo:nil];
}

/*
 
 mother resume action
 
 in general this message will be sent up the responder chain
 
 */
- (IBAction)requestResumeTask:(id)sender
{
#pragma unused(sender)
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAppToggleExecutePauseTask object:[self window] userInfo:nil];
}


/*
 
 terminate mother action
 
 in general this message will be sent up the responder chain
 
 */
- (IBAction)requestTerminateTask:(id)sender
{
#pragma unused(sender)
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAppTerminateTask object:[self window] userInfo:nil];
}

/*
 
 - requestEditTask:
 
 */
- (IBAction)requestEditTask:(id)sender
{
#pragma unused(sender)
	
}

#pragma mark View handling

/*
 
 active result view controller
 
 subclasses must override to return currently active result view controller
 
 */
- (MGSResultViewController *)activeResultViewController
{
	return nil; 
}

/*
 
 active request view controller
 
 subclasses must override to return currently active request view controller
 
 */
- (MGSRequestViewController *)activeRequestViewController
{
	return nil;
}

#pragma mark Menu Handling

/*
 
 validate menu item
 
 */

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	MGSTaskSpecifier *actionSpecifier = [self selectedActionSpecifier];
	if (!actionSpecifier) return NO;
	
	NSAssert(actionSpecifier, @"action specifier is nil");

	// get net client context for this window
	MGSNetClientContext *context = [[actionSpecifier netClient] contextForWindow:[self window]];
	NSAssert(context, @"window net client context is nil");
	
	// enable menu if run mode is not configure
	BOOL enableMenu = context.runMode == kMGSMotherRunModeConfigure ? NO : YES;
	
	// menu selector
	SEL menuActionSelector = [menuItem action];
		
	// open task in new window
	if (menuActionSelector == @selector(openTaskInNewWindow:)) {
		return [self activeRequestViewController].inputViewController.canDetachActionAsWindow;
	}
	
	// open result in new window
	else if (menuActionSelector == @selector(openResultInNewWindow:)) {
		return [self activeRequestViewController].outputViewController.canDetachResultAsWindow;
	} 
	
	else if (menuActionSelector == @selector(requestExecuteTask:)) {
		return ([actionSpecifier canExecute] && enableMenu);
	}
	else if (menuActionSelector == @selector(requestSuspendTask:)) {
		return ([actionSpecifier canSuspend] && enableMenu);
	}
	else if (menuActionSelector == @selector(requestResumeTask:)) {
		return ([actionSpecifier canResume] && enableMenu);
	}
	else if (menuActionSelector == @selector(requestTerminateTask:)) {
		return ([actionSpecifier canTerminate] && enableMenu);
	}
	else if (menuActionSelector == @selector(requestEditTask:)) {
			return NO;
	} else if (menuActionSelector == @selector(openFile:)) {
		[menuItem setTitle:NSLocalizedString(@"Open File as New Task...", @"Menu string")];
	}
	
	
	return YES;
}

/*
 
 open task in new window
 
 */
- (IBAction)openTaskInNewWindow:(id)sender
{
	#pragma unused(sender)
	
	[[self activeRequestViewController].inputViewController detachActionAsWindow: self];
}

/*
 
 open result in new window
 
 */
- (IBAction)openResultInNewWindow:(id)sender
{
	#pragma unused(sender)
	
	[[self activeRequestViewController].outputViewController detachResultAsWindow: self];
	
}

#pragma mark -
#pragma mark Document handling
/*
 
 - newDocument:
 
 */
- (IBAction)newDocument:(id)sender
{
#pragma unused(sender)
	
}

/*
 
 - openFile:
 
 */
- (IBAction)openFile:(id)sender
{
#pragma unused(sender)
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [self window], @"window",
							 [NSNumber numberWithInteger:MGS_AV_REPLACE_TEXT], @"textHandling",
							 [NSNumber numberWithBool:NO], @"textHandlingEnabled",
							 nil];
	[[self openPanelController] openSourceFile:self options:options];
	
}

#pragma mark -
#pragma mark MGSOpenPanelController notifications

/*
 
 - openPanelControllerDidClose:
 
 */
- (void)openPanelControllerDidClose:(NSNotification *)notification
{
	#pragma unused(notification)
}

#pragma mark -
#pragma mark Panel controllers

/*
 
 - openPanelController
 
 */
- (MGSOpenPanelController *)openPanelController
{
	if (!_openPanelController) {
		_openPanelController = [[MGSOpenPanelController alloc] init];
	}
	return _openPanelController;
}

@end
