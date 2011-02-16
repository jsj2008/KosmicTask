//
//  MGSDisplayToolViewController.m
//  Mother
//
//  Created by Jonathan on 05/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSDisplayToolViewController.h"
#import "MGSTaskSpecifier.h"
#import "MGSTimeIntervalTransformer.h"
#import "MGSScript.h"
#import "MGSNetClient.h"
#import "MGSNotifications.h"
#import "MGSPlayButton.h"
#import "NSWindow_Mugginsoft.h"
#import "MGSLCDDisplayView.h"
#import "MGSRequestProgress.h"
#import "NSEvent_Mugginsoft.h"

#define PLAY_STATE NSOnState
#define PAUSE_STATE NSOffState
#define RESUME_STATE NSMixedState

static NSString *MGSActionRunStatusContext = @"MGSActionRunStatus";
static NSString *MGSActionTimeoutContext = @"MGSActionTimeout";
NSString *MGSActionProgressContext = @"MGSActionProgress";

@interface MGSDisplayToolViewController()
- (void)toggleExecuteTerminateNotification:(NSNotification *)note;
- (void)toggleExecutePauseNotification:(NSNotification *)note;
- (void)terminateNotification:(NSNotification *)note;
- (void)windowKeyStatusChange:(NSNotification *)note;
@end

@implementation MGSDisplayToolViewController

@synthesize actionSpecifier = _actionSpecifier;
@synthesize textColor = _textColor;
@synthesize highlight = _highlight;
/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	_objectController = [[NSObjectController alloc] init];
	self.highlight = NO;
}

/*
 
 initialise for window
 
 */
- (void)initialiseForWindow:(NSWindow *)window
{
	NSAssert(window, @"window is nil");
	
	_window = window;
	
	// use interval transformer to format  time intervals
	// as NSDateFormatter did not seem to provide exactly the correct formats
	_intervalTransformer = [[MGSTimeIntervalTransformer alloc] init];
	_bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:_intervalTransformer, NSValueTransformerBindingOption, nil];
	
	// binding options for remaining time.
	// this requires a negative prefix
	_negIntervalTransformer = [[MGSTimeIntervalTransformer alloc] init];
	_negIntervalTransformer.prefix = @"- ";
	_negBindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:_negIntervalTransformer, NSValueTransformerBindingOption, nil];
	
	[statusImage setImageFrameStyle:NSImageFrameNone];
	[hostImage setImageFrameStyle:NSImageFrameNone];
	
	// listen for window key status notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowKeyStatusChange:) name:NSWindowDidResignKeyNotification object:_window];
	// listen for top level action notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleExecutePauseNotification:) name:MGSNoteAppToggleExecutePauseTask object:_window];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleExecuteTerminateNotification:) name:MGSNoteAppToggleExecuteTerminateTask object:_window];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateNotification:) name:MGSNoteAppTerminateTask object:_window];
	
}


/*
 
 toggle execute/terminate notification
 
 */
- (void)toggleExecuteTerminateNotification:(NSNotification *)note
{
	#pragma unused(note)
	
	if ([_actionSpecifier canTerminate]) {
		[self terminateAction:self];
	} else {
		[self toggleActionExecution:self];
	}

}

/*
 
 toggle execute/pause notification
 
 */
- (void)toggleExecutePauseNotification:(NSNotification *)note
{
	#pragma unused(note)
	
	[self toggleActionExecution:self];
}

/*
 
 toggle terminate notification
 
 */
- (void)terminateNotification:(NSNotification *)note
{
	#pragma unused(note)
	
	[self terminateAction:self];
}

/*
 
 window key status change
 
 */
- (void)windowKeyStatusChange:(NSNotification *)note
{
	#pragma unused(note)
	
	lcdDisplayView.maxIntensity = [_window isKeyWindow];
}
/*
 
 set action
 
 */
-(void)setActionSpecifier:(MGSTaskSpecifier *)action
{
	// if no action then
	if (!action) {
		return;
	}
	
	// cleanup previous action
	if (_actionSpecifier) {
		
		// unbind previous action
		[elapsedTime unbind:NSValueBinding];
		[remainingTime unbind:NSValueBinding];
		[actionStatus unbind:NSValueBinding];
		[statusImage unbind:NSValueBinding];
		[hostImage unbind:NSValueBinding];
		[actionPath unbind:NSValueBinding];
		
		// remove observers
		@try {
			[_actionSpecifier removeObserver:self forKeyPath:@"runStatus"];
			[_actionSpecifier removeObserver:self forKeyPath:@"script.timeout"];
			[_actionSpecifier removeObserver:self forKeyPath:@"requestProgress.value"];
		} 
		@catch (NSException *e)
		{
			MLog(RELEASELOG, @"%@", [e reason]);
		}
		
		_actionSpecifier = nil;
		[_objectController setContent:nil];
	}
	
	//[self remove:self]
	_actionSpecifier = action;	
	[_objectController setContent:_actionSpecifier];

	// set task label
	NSString *displayName = [action displayName];
	BOOL transportHidden = NO;
	
	// if no script defined then action is a placeholder for those situations where no valid tasks exist
	if (![action script]) {
		transportHidden = YES;
	}
	
	//[actionPath setStringValue:actionString];
	if (!action.requestProgress.overviewString) {
		action.requestProgress.overviewString = displayName;
	}
	
	// bind
	[elapsedTime bind:NSValueBinding toObject:_objectController withKeyPath:@"selection.elapsedTime" options:_bindingOptions];
	[remainingTime bind:NSValueBinding toObject:_objectController withKeyPath:@"selection.remainingTime" options:_negBindingOptions];
	[actionStatus bind:NSValueBinding toObject:_objectController withKeyPath:@"selection.requestProgress.name" options:nil];
	[statusImage bind:NSValueBinding toObject:_objectController withKeyPath:@"selection.requestProgress.image" options:nil];
	[hostImage bind:NSValueBinding toObject:_objectController withKeyPath:@"selection.representedNetClient.hostIcon" options:nil];
	if (NO) {
		[actionPath bind:NSValueBinding toObject:_objectController withKeyPath:@"selection.requestProgress.overviewString" options:[NSDictionary dictionaryWithObjectsAndKeys:displayName, NSNullPlaceholderBindingOption,  nil]];
	}
	
	[actionPath setStringValue:displayName];

	[playButton setHidden:transportHidden];
	[stopButton setHidden:transportHidden];
	
	// add observers
	[_actionSpecifier addObserver:self forKeyPath:@"runStatus" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:MGSActionRunStatusContext];
	[_actionSpecifier addObserver:self forKeyPath:@"script.timeout" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:MGSActionTimeoutContext];
	[_actionSpecifier addObserver:self forKeyPath:@"requestProgress.value" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:MGSActionProgressContext];
}


/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(change)
	
	// action run status changed
	if (context == MGSActionRunStatusContext) {
		
		BOOL hightlightDisplay = NO;
		BOOL available = YES;
		
		// note that the enabled state of the play and stop buttons
		// must be set for each runstatus.
		// a previous state cannot be presumed because a different action
		// could have been set.
		switch (_actionSpecifier.runStatus) {
				
			case MGSTaskRunStatusHostUnavailable:
				[playButton setState:PLAY_STATE];
				[playButton setEnabled:NO];
				[stopButton setEnabled:NO];
				available = NO;
				break;
				
			case MGSTaskRunStatusReady:
			case MGSTaskRunStatusComplete:
			case MGSTaskRunStatusCompleteWithError:
			case MGSTaskRunStatusTerminatedByUser:;
				[playButton setState:PLAY_STATE];
				[playButton setEnabled:YES];
				[stopButton setEnabled:NO];
				break;
				
			case MGSTaskRunStatusExecuting:
				[playButton setState:PAUSE_STATE];
				
				// enable suspend and terminate only if script allows
				[playButton setEnabled:![_actionSpecifier.script prohibitSuspend]];				
				[stopButton setEnabled:![_actionSpecifier.script prohibitTerminate]];
				hightlightDisplay = YES;
				break;
				
			case MGSTaskRunStatusSuspended:
			case MGSTaskRunStatusSuspendedSending:
			case MGSTaskRunStatusSuspendedReceiving:
				[playButton setState:RESUME_STATE];	
				[playButton setEnabled:YES];
				
				// enable terminate if script allows
				[stopButton setEnabled:![_actionSpecifier.script prohibitTerminate]];
				hightlightDisplay = YES;
		
			break;
				
			default:
				NSAssert(NO, @"invalid run status");
				break;
		}
		
		self.highlight = hightlightDisplay;
		lcdDisplayView.available = available;
	
	} else if (context == MGSActionTimeoutContext) {
		
		// action timeout changed 
		
		float timeout = [[_actionSpecifier script] timeout];
		[remainingTime setStringValue: [_negIntervalTransformer transformedValue:[NSNumber numberWithFloat:timeout]]];
		[remainingTime setHidden:timeout <= 0 ? YES : NO];
		
	} else if (context == MGSActionProgressContext) {
		
		// action progress changed
		switch (_actionSpecifier.requestProgress.value) {
				
			case MGSRequestProgressReplyReceived:
			case MGSRequestProgressCompleteWithNoErrors:
			case MGSRequestProgressCompleteWithErrors:;				
				break;
				
			default:
				break;
		}
	}
}

/*
 
 set highlight
 
 */
- (void)setHighlight:(BOOL)newValue
{
	_highlight = newValue;
	lcdDisplayView.active = _highlight;
	NSColor *color = nil;
	if (_highlight) {
		color = [NSColor whiteColor];
	} else {
		color = [NSColor colorWithCalibratedRed:0.922f green:0.922f blue:0.922f alpha:1.0f];
	}
	
	self.textColor = color;
}
/*
 
 toggle action execution
 
 */
- (IBAction)toggleActionExecution:(id)sender
{
	#pragma unused(sender)
	
	NSWindow *window = [[self view] window];

	// if action not processing then execute/resume
	if (_actionSpecifier.runStatus != MGSTaskRunStatusExecuting && ![_actionSpecifier canResume]) {
		
		// we could send -commitEditing to our active view controller to end editing.
		// but there's no easy way to get it.
		// so make the window itself firstResponder.
		// any active edits should be commited to the bound model.
		[[[self view] window] endEditing];
		
		// post execute notification
		[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteExecuteSelectedTask object:window userInfo:nil];
	} else {
		
		// if action suspended then resume it
		if ([_actionSpecifier canResume]) {
			
			// resume the action
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteResumeSelectedTask object:window userInfo:nil];
			
		} else {
			
			// suspend the action
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteSuspendSelectedTask object:window userInfo:nil];
		}
	}
}

/*
 
 terminate action
 
 */
- (IBAction)terminateAction:(id)sender
{
	#pragma unused(sender)
	
	if ([_actionSpecifier canTerminate]) {
		
		// post terminate notification
		[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteStopSelectedTask object:[[self view] window] userInfo:nil];
	}

}

@end
