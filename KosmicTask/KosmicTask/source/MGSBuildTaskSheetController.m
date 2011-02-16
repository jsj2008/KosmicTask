//
//  MGSBuildTaskSheetController.m
//  Mother
//
//  Created by Jonathan on 15/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#define TIMER_INTERVAL 2.0

#import "MGSBuildTaskSheetController.h"
#import "MGSTaskSpecifier.h"
#import "MGSClientRequestManager.h"
#import "MGSNetRequestPayload.h"
#import "MGSScriptPlist.h"
#import "MGSNetClient.h"
#import "MGSScriptEditViewController.h"
#import "MGSScript.h"
#import "MGSLanguagePlugin.h"

static NSInteger MGS_ignoreBuildWarningsCheckboxState = NSOffState;

// class extension
@interface MGSBuildTaskSheetController()
- (void)buildTimerExpired:(NSTimer*)theTimer;
@end

@implementation MGSBuildTaskSheetController

@synthesize taskSpecifier = _taskSpec;
@synthesize delegate = _delegate;
@synthesize modalWindowWillCloseOnSave = _modalWindowWillCloseOnSave;

/*
 
 + buildWarningsCheckBoxState
 
 */
+ (NSInteger)buildWarningsCheckBoxState
{
	return MGS_ignoreBuildWarningsCheckboxState;
}

/*
 
 init
 
 */
- (id)init
{
	self = [super initWithWindowNibName:@"CompileActionSheet"];
	return self;
}


/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	_windowHasQuit = NO;
	_responseReceived = NO;
	
	NSFont *resultFont = [NSFont fontWithName:@"Menlo" size: 10];
	[_resultTextField setFont:resultFont];
	[_resultTextField setTextColor:[NSColor blackColor]];
}

/*
 
 - setTaskSpecifier:
 
 */
- (void)setTaskSpecifier:(MGSTaskSpecifier *)task
{
	_taskSpec = task;
	
	NSString *message = NSLocalizedString(@"Build task \"%@\" on %@.", @"build task sheet message text");
	NSString *scriptName = [[_taskSpec script] name];
	NSString *serviceName = _taskSpec.netClient.serviceShortName;
	
	message = [NSString stringWithFormat:message, scriptName, serviceName];
	[_titleTextField setStringValue:message];
	
	message = NSLocalizedString(@"Please wait.", @"build task sheet message text");
	[_resultTextField setAlignment:NSCenterTextAlignment];
	[_resultTextField setStringValue:message];
	
	MGSLanguagePlugin *langPlugin = [[_taskSpec script] languagePlugin];
	if (![langPlugin canIgnoreBuildWarnings]) {
		MGS_ignoreBuildWarningsCheckboxState = NSOffState;
	} 
}

/*
 
 build:
 
 */
- (IBAction)build:(id)sender
{
	#pragma unused(sender)
	
	[_cancelButton setEnabled:NO];

	// start the build timer
	_buildTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(buildTimerExpired:) userInfo:nil repeats:NO];
	
	// show the info view
	[_infoView setHidden:NO];
	[_progressIndicator startAnimation:self];
	
	// determine if we can build without executing
	MGSLanguageProperty *langProp = [[[_taskSpec script] languagePropertyManager] propertyForKey:MGS_LP_CanBuild];
	BOOL canBuild = [[langProp value] boolValue];
	
	if (canBuild) {
		// build task
		[[MGSClientRequestManager sharedController] requestBuildTask:_taskSpec withOwner:self];
	} else {
		
		// execute task
		[[MGSClientRequestManager sharedController] requestExecuteTask:_taskSpec withOwner:self];
	}
}

/*
 
 - buildTimerExpired
 
 */
- (void)buildTimerExpired:(NSTimer*)theTimer
{
	#pragma unused(theTimer)
	
	[_buildTimer invalidate];
	_buildTimer = nil;
	
	if (_windowHasQuit || _responseReceived) {
		return;
	}
	
	[_cancelButton setEnabled:YES];
}

/*
	
 OK to close window
 
 */
- (IBAction)OKToCloseWindow:(id)sender
{
	#pragma unused(sender)
	
	[self closeWindowWithReturnCode:NSOKButton];
}

/*
 
 cancel
 
 */
- (IBAction)cancel:(id)sender
{
	#pragma unused(sender)
	
	// request cancel build action
	// at present it is fairly futile to request a cancellation as the compilation
	// occurs within the OSA component and apart from terminating the thread there is little that can be done to influence it.
	// probably better to let it run to completion.
	//
	// there could be an argument for cancelling very large scripts being sent/received over a network
	//[[MGSClientRequestManager sharedController] requestScriptCompilationForAction:_action withOwner:self];
	
	[self closeWindowWithReturnCode:NSCancelButton];
}


/*
 
 reply to save edits request
 
 */
-(void)netRequestResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	NSString *title = nil;

	/*
	 
	 if window has already quit we are done
	 
	 */
	if (_windowHasQuit) {
		return;
	}
	
	_responseReceived = YES;
		
	
	/*
	 
	 send payload to the delegate for initial processing
	 
	 */
	MGSScriptEditViewController *controller = _delegate;	// hack
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: 
							 [NSNumber numberWithBool:[self buildWarningsCheckBoxState]], MGSIgnoreBuildError, nil];
	[controller netRequestResponse:netRequest payload:payload options:options];
	NSString *buildMessage = controller.buildSheetMessage;
	
	/*
	 
	 determine if script can be executed
	 
	 this does not mean that the script will execute successfuly merely
	 that it did not generate a fatal error
	 
	 */
	if ([controller scriptBuilt]) {
		
		// script did build but an error was generated
		if (controller.buildStatusFlags != MGS_BUILD_NO_WARNINGS) {

			// if ignoring errors then discard the build message
			if ([self buildWarningsCheckBoxState] == NSOnState) {
				buildMessage =  NSLocalizedString(@"Completed with warnings (ignored).", @"build task success sheet message text");
				buildMessage = [NSString stringWithFormat:@"%@\n\n%@", buildMessage, controller.buildSheetMessage];
			} 
		}	
	} else {		
		
		// NO
		
		[_resultTextField setTextColor:[NSColor redColor]];
		
		NSString *scriptName = [[_taskSpec script] name];
		NSString *serviceName = _taskSpec.netClient.serviceShortName;

		title = NSLocalizedString(@"Failed to build task \"%@\" on %@.", @"build task failure sheet message text");
		title = [NSString stringWithFormat:title, scriptName, serviceName];
	}
		
	// update the sheet title
	if (title) {
		[_titleTextField setStringValue:title];
	}
	
	// update the sheet result
	[_resultTextField setAlignment:NSJustifiedTextAlignment];
	if (buildMessage) {
		[_resultTextField setStringValue:buildMessage];
	}
	
	// update button statuses
	[_OKButton setEnabled:YES];
	[_cancelButton setEnabled:NO];
	[_infoView setHidden:YES];
	
	/*
	 
	 set visibility of the ignore build warnings check box.
	 
	 we can ignore warnings if allowed by the language plugin and the build
	 did not result in a fatal error.
	 
	 */
#ifdef MGS_ALLOW_IGNORE_BUILD_WARNINGS
	MGSLanguagePlugin *langPlugin = [[_taskSpec script] languagePlugin];
	if ([langPlugin canIgnoreBuildWarnings] && !(controller.buildStatusFlags & MGS_BUILD_FLAG_FATAL_ERROR)) {
		[_ignoreBuildWarningsCheckbox setHidden:NO];
	} 
#else
	[_ignoreBuildWarningsCheckbox setHidden:YES];
#endif
}


/*
 
 close window
 
 */
- (void)closeWindowWithReturnCode:(NSInteger)returnCode
{
	_windowHasQuit = YES;
	[_progressIndicator stopAnimation:self];
	
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:returnCode];
}

/*
 
 - buildWarningsCheckBoxState
 
 */
 
- (NSInteger)buildWarningsCheckBoxState
{
	return MGS_ignoreBuildWarningsCheckboxState;
}

/*
 
 - setBuildWarningsCheckBoxState:
 
 */
- (void)setBuildWarningsCheckBoxState:(NSInteger)state
{
	MGS_ignoreBuildWarningsCheckboxState = state; 
}
@end

