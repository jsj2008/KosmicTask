//
//  MGSSaveConfigurationWindowController.m
//  Mother
//
//  Created by Jonathan on 26/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSSaveConfigurationWindowController.h"
#import "MGSClientRequestManager.h"
#import "MGSNetClient.h"
#import "MGSScriptPlist.h"
#import "MGSNetRequestPayload.h"
#import "MGSError.h"
#import "MGSClientTaskController.h"
#import "MGSClientScriptManager.h"
#import "MGSScript.h"
#import "MGSNetClientManager.h"
#import "MGSNotifications.h"

// class extension
@interface MGSSaveConfigurationWindowController()
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)errorAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)timerFire:(NSTimer*)theTimer;
@end

@implementation MGSSaveConfigurationWindowController
@synthesize modalForWindow = _modalForWindow;
@synthesize doCallBack = _doCallBack;

/*
 
 init
 
 */
- (id)init
{
	return [self initWithNetClient:nil];
}
/*
 
 init with net client
 
 designated initialiser
 
 */
- (id)initWithNetClient:(MGSNetClient*)netClient
{
	if (!netClient) return nil;
	
	if ((self = [super initWithWindowNibName:@"SaveConfigurationWindow"])) {
		_changesArrayController = [NSArrayController new];
		_netClient = netClient;
		

	}
	return self;
}

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	;
}

/*
 
 save configuration for net client
 
 */
- (BOOL)showSaveSheet
{
	// array of changed script dictionaries.
	// these are raw dictionaries not MGSScript instances.
	NSMutableArray *scriptArray = [[_netClient.taskController scriptManager] changeArrayCopy];
	NSInteger changeCount = [scriptArray count];
	
	// if no changed scripts found then quit
	if (changeCount == 0) {
		return NO;
	}
	
	// add ChangeText key to the script dict
	for (NSMutableDictionary *scriptDict in scriptArray) {
		NSString *changeText = NSLocalizedString(@"Unknown", @"Unknown reason for change in save configuration sheet");
		
		// wrap dictionary in an MGSScript instance
		MGSScript *script = [MGSScript scriptWithDictionary:scriptDict];
		if (script) {
			
			if ([script scheduleDelete]) {
				changeText = NSLocalizedString(@"delete task", @"Save configuration sheet - task will be deleted");
			} else if  ([script schedulePublished]) {
				if ([script published]) {
					changeText = NSLocalizedString(@"publish task", @"Save configuration sheet - task will be published");
				} else {
					changeText = NSLocalizedString(@"unpublish task", @"Save configuration sheet - task will be unpublished");
				}
			}
		}
		
		// add non standard key to the script dict.
		// this dict is ephemeral and will not get propagated.
		[scriptDict setObject:[changeText copy] forKey:@"_ChangeText_"];
	}
	
	// bind change array  to tableview
	[_changesArrayController setContent:scriptArray];
	
	// as each of items in array is a dictionary we can simply access them by their key path.
	// NSDictionary overrides valueForKey: to invoke object for key.
	[[changesTableView tableColumnWithIdentifier:@"Task"] bind:NSValueBinding toObject:_changesArrayController withKeyPath:@"arrangedObjects.Name" options:nil];
	[[changesTableView tableColumnWithIdentifier:@"Change"] bind:NSValueBinding toObject:_changesArrayController withKeyPath:@"arrangedObjects._ChangeText_" options:nil];
	
	[changesTableView setAllowsEmptySelection:YES];
	[changesTableView deselectAll:self];
	
	
	// set sheet text
	NSString *message = NSLocalizedString(@"Do you want to save the configuration changes to %@.", @"save configuration sheet");
	message = [NSString stringWithFormat:message, [_netClient serviceShortName]];
	[mainLabel setStringValue:message];
	
	// set change count
	NSString *countString = nil;
	if (changeCount == 1) {
		countString = NSLocalizedString(@"%i configuration change", @"save configuration sheet change count format");
	} else {
		countString = NSLocalizedString(@"%i configuration changes", @"save configuration sheet change count format");
	}
	[changeCountLabel setStringValue:[NSString stringWithFormat:countString, changeCount]];
	
	// hide the info view
	[infoView setHidden:YES];
	
	// enable the cancel button
	[cancelButton setEnabled:YES];
	
	// show the save sheet
	[NSApp beginSheet:[self window] modalForWindow:_modalForWindow 
		modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
	
	return YES;
}


/*
 
 modal sheet did end
 
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	#pragma unused(sheet)
	#pragma unused(returnCode)
	#pragma unused(contextInfo)
}

/*
 
 net request response
 
 */
-(void)netRequestResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	#pragma unused(netRequest)
	
	NSString *errorString = NSLocalizedString(@"Unknown reason for error", @"Unknown reason for error.");
	
	// if the window is not still on screen then quit
	if (![[self window] isVisible]) {
		return;
	}
	
	// keep a ref to netClient as it is cleared by -closeWindow:
	MGSNetClient *netClient = _netClient;
	
	[self closeWindow:self];
	BOOL success = NO;
	
	NSString *requestCommand = netRequest.kosmicTaskCommand;
	
	// validate response
	if (NSOrderedSame != [requestCommand caseInsensitiveCompare:MGSScriptCommandSaveChangesAndPublish]) {
		MGSError *error = [MGSError clientCode:MGSErrorCodeInvalidCommandReply];
		errorString = [error localizedDescription];
	} else {
		NSDictionary *dict = [payload dictionary];
		success = [[dict objectForKey:MGSScriptKeyBoolResult] boolValue];
	}
	
	// display save request error status
	if (!success) {
		
		// ensure that the task script schedules are cleared.
		// this may or may not have an effect depending on the nature of the error
		[self undoConfigurationChanges];
		
		// get payload error if present
		if (payload.requestError) {
			errorString = [payload.requestError localizedDescription];
		}
		
		NSString *message = NSLocalizedString(@"Error saving configuration changes to %@", @"save configuration sheet - error saving changes to client");
		message = [NSString stringWithFormat:message, [netClient serviceShortName]];
		
		NSBeginAlertSheet(
						  message,	// sheet message
						  nil,              //  default button label - will default to OK
						  nil,             //  alternate button label
						  nil,              //  other button label
						  self.modalForWindow,	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  @selector(errorAlertSheetDidEnd:returnCode:contextInfo:),					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  nil,                 // context info
						  [NSString stringWithFormat: NSLocalizedString(@"The changes could not be saved. %@.", @"Alert sheet text"), errorString],	// additional text
						  nil);				
	}
	
	if (self.doCallBack) {
		[self callBack:YES];
	}
		
}
/*
 
 error alert sheet did end
 
 */
- (void)errorAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	#pragma unused(returnCode)
	#pragma unused(contextInfo)
	
	[sheet orderOut:self];
	
	if (self.doCallBack) {
		[self callBack:YES];
	}
}

/*
 
 close window
 
 */
- (IBAction)closeWindow:(id)sender
{
	// free cancel timer
	if (_cancellationTimer) {
		[_cancellationTimer invalidate];
		_cancellationTimer = nil;
	}
	
	// clear content
	[_changesArrayController setContent:nil];
	_netClient = nil;

	// hide the info view
	[infoView setHidden:YES];
	[progressView stopAnimation:self];
	
	// end the sheet
	[[self window] orderOut:sender];
	[NSApp endSheet:[self window] returnCode:1];
}
/*
 
 save
 
 */
- (IBAction)save:(id)sender
{
	#pragma unused(sender)
	
	// disable buttons
	[saveButton setEnabled:NO];
	[dontSaveButton setEnabled:NO];
	[cancelButton setEnabled:NO];

	// show the info view
	[infoView setHidden:NO];
	[progressView startAnimation:self];
	
	// start the cancellation timer
	_cancellationTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(timerFire:) userInfo:nil repeats:NO];
	
	// request save changes for client
	[[MGSClientRequestManager sharedController] requestSaveConfigurationChangesForNetClient:_netClient withOwner:self republish:YES];

}

/*
 
 timer fire
 
 */
- (void)timerFire:(NSTimer*)theTimer
{
	#pragma unused(theTimer)
	
	[_cancellationTimer invalidate];
	_cancellationTimer = nil;
	
	[cancelButton setEnabled:YES];
}

/*
 
 don't save
 
 */
- (IBAction)dontSave:(id)sender
{
	#pragma unused(sender)
	
	// we are not saving our changes
	// so reset the reset state of controller scripts
	[self undoConfigurationChanges];
	
	[self closeWindow:self];
	
	if (self.doCallBack) {
		[self callBack:YES];
	}
}

/*
 
 undo configuration changes
 
 */
- (void)undoConfigurationChanges
{
	NSArray *scriptsScheduledForDelete = [[_netClient.taskController scriptManager] changeArrayScheduleForDelete];
	
	[_netClient.taskController undoConfigurationChanges];
	
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:scriptsScheduledForDelete, MGSNoteClientScriptArrayKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteWillUndoConfigurationChanges object:_netClient userInfo:info];	
}

/*
 
 cancel
 
 */
- (IBAction)cancel:(id)sender
{
	#pragma unused(sender)
	
	[self closeWindow:self];
	
	if (self.doCallBack) {
		[self callBack:NO];
	}
}

/*
 
 callback
 
 */
- (void)callBack:(BOOL)value
{
	[[MGSNetClientManager sharedController] reviewSaveConfigurationAndQuitEnumeration:[NSNumber numberWithBool:value]];
}
@end
