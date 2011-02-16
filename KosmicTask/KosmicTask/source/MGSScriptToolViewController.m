//
//  MGSScriptToolViewController.m
//  Mother
//
//  Created by Jonathan on 01/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSActionExecuteWindowController.h"
#import "MGSScriptToolViewController.h"
#import "MGSNotifications.h"


// class extension
@interface MGSScriptToolViewController()
- (void)scriptCompilationStateDidChange:(NSNotification *)notification;
- (void)scriptCanExecuteStateDidChange:(NSNotification *)notification;
@end

@implementation MGSScriptToolViewController

/*
 
 run script
 
 */
- (IBAction)runScript:(id)sender
{
#pragma unused(sender)
	
	// send the execute task request up the responder chain
	[NSApp sendAction:@selector(requestExecuteTask:) to:nil from:self];

}

/*
 
 compile script
 
 */
- (IBAction)compileScript:(id)sender
{
	#pragma unused(sender)
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteBuildScript object:_window userInfo:nil];
}

/*
 
 show dictionary
 
 */
- (IBAction)showDictionary:(id)sender
{
	#pragma unused(sender)
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteShowDictionary object:_window userInfo:nil];
}

/*
 
 initialise for window
 
 */
- (void)initialiseForWindow:(NSWindow *)window
{
	NSAssert(window, @"window is nil");
	
	_window = window;
	[compileButton setEnabled:NO];
	
	// register for notifications
	// listen for script compilation state change notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptCompilationStateDidChange:) name:MGSNoteWindowScriptCompilationStateDidChange object:window];

	// listen for script execute without build notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptCanExecuteStateDidChange:) name:MGSNoteWindowCanExecuteScriptStateDidChange object:window];
}

#pragma mark notifications

/*
 
 script compilation state did change
 
 */
- (void)scriptCompilationStateDidChange:(NSNotification *)notification
{
	
	if ([notification object] != _window) return;
	
	// get compilation state
	BOOL isCompiled = [[[notification userInfo] objectForKey:MGSNoteBoolStateKey] boolValue];
	
	// set build button enabled state
	[compileButton setEnabled:!isCompiled];
}

/*
 
 - scriptCanExecuteStateDidChange:
 
 */
- (void)scriptCanExecuteStateDidChange:(NSNotification *)notification
{
	
	if ([notification object] != _window) return;
	
	// build state
	BOOL canExecute = [[[notification userInfo] objectForKey:MGSNoteBoolStateKey] boolValue];
	
	// set run button state
	[runButton setEnabled:canExecute];
}

/*
 
 set action
 
 */
-(void)setActionSpecifier:(MGSTaskSpecifier *)action
{
	if (!action) {
		return;
	}
	
	// cleanup previous action
	if (_actionSpecifier) {
		
		// unbind previous action
			
		// remove observers
		@try {
		} 
		@catch (NSException *e)
		{
			MLog(RELEASELOG, @"%@", [e reason]);
		}		
	}
	
	_actionSpecifier = action;
	
}
@end
