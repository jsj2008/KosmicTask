//
//  MGSSaveActionSheetController.m
//  Mother
//
//  Created by Jonathan on 26/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSSaveActionSheetController.h"
#import "MGSTaskSpecifier.h"
#import "MGSClientRequestManager.h"
#import "MGSNetRequestPayload.h"
#import "MGSScriptPlist.h"
#import "MGSNetClient.h"
#import "MGSEditWindowController.h"

@implementation MGSSaveActionSheetController

@synthesize action = _action;
@synthesize delegate = _delegate;
@synthesize modalWindowWillCloseOnSave = _modalWindowWillCloseOnSave;
@synthesize saveCompleted = _saveCompleted;

#pragma mark Instance handling
/*
 
 init
 */
- (id)init
{
	self = [super initWithWindowNibName:@"SaveActionSheet"];
	return self;
}


/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	_saveButtonQuits = NO;
	_windowHasQuit = NO;
	_saveCompleted = NO;
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

#pragma mark Accessors
/*
 
 set action
 
 */
- (void)setAction:(MGSTaskSpecifier *)action
{
	_action = action;
	
	NSString *message = NSLocalizedString(@"Do you want to save the changes to task \"%@\" on %@?", @"save task sheet message text");
	NSString *scriptName = [[_action script] name];
	NSString *serviceName = _action.netClient.serviceShortName;

	message = [NSString stringWithFormat:message, scriptName, serviceName];
	[_titleTextField setStringValue:message];
}

/*
 
 set save completed
 
 */
- (void)setSaveCompleted:(BOOL)aBool
{
	_saveCompleted = aBool;
}

#pragma mark Saving
/*
 
 save
 
 */
- (IBAction)save:(id)sender
{
	#pragma unused(sender)
	
	if (_saveButtonQuits) {
		[self closeWindowWithReturnCode:1];
	}
	
	[_cancelButton setEnabled:NO];
	[_saveButton setEnabled:NO];

	// change don't save button text to abort
	[_dontSaveButton setTitle:NSLocalizedString(@"Abort", @"abort save task button text during save")];

	// show the info view
	[_infoView setHidden:NO];
	[_progressIndicator startAnimation:self];
	
	// delegate prepares the save
	if (_delegate && [_delegate respondsToSelector:@selector(prepareForSave)]) {
		[_delegate performSelector:@selector(prepareForSave)];
	}
	
	// after awake from sleep scheduleSave may get reset to false.
	// or if previous save failed
	[[_action script] setScheduleSave];
	
	// save action request
	MGSNetRequest *request = [[MGSClientRequestManager sharedController] requestSaveTask:_action withOwner:self];
	
	// if request not accepted then save failed
	if (!request) {
		[self saveFailed:nil];
	}
}

/*
 
 dont save
 
 */
- (IBAction)dontSave:(id)sender
{
	#pragma unused(sender)
	
	[self closeWindowWithReturnCode:1];
}

/*
 
 cancel
 
 */
- (IBAction)cancel:(id)sender
{
	#pragma unused(sender)
	
	[self closeWindowWithReturnCode:0];
}


/* 
 
 save failed
 
 */
- (void)saveFailed:(MGSError *)error
{
	self.saveCompleted = NO; 
	
	NSString *message = NSLocalizedString(@"Failed to save the changes to task \"%@\" on %@.", @"save task failure sheet message text");
	if (error) {
		switch (error.code) {
			case MGSErrorCodeAuthenticationFailure:
				message = NSLocalizedString(@"Authentication failure. Please switch to configuration mode to save.", @"save task authentication failure");
				break;
				
			default:
				break;
		}
	}
	
	NSString *scriptName = [[_action script] name];
	NSString *serviceName = _action.netClient.serviceShortName;
	message = [NSString stringWithFormat:message, scriptName, serviceName];
	[_titleTextField setStringValue:message];
	
	[_infoView setHidden:YES];
	
	// enable form closing
	[_saveButton setTitle:NSLocalizedString(@"Close", @"save task button text following failed save")];
	//[_saveButton setEnabled:YES];
	//_saveButtonQuits = YES;	
	[_cancelButton setEnabled:YES];
	
	// save failed so schedule again
	[[_action script] setScheduleSave];
	
}

#pragma mark MGSNetRequest handling
/*
 
 reply to save edits request
 
 */
-(void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
#pragma unused(netRequest)
	
	if (_windowHasQuit) {
		return;
	}
	
	NSDictionary *dict = [payload dictionary];
	BOOL success = [[dict objectForKey:MGSScriptKeyBoolResult] boolValue];
	
	// display save request status
	if (success) {
		self.saveCompleted = YES;
		[self closeWindowWithReturnCode:1];
		return;
	} 
	
	// save failed
	[self saveFailed:netRequest.error];	
}

@end
