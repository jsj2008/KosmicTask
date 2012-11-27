//
//  MGSEditModeToolViewController.m
//  Mother
//
//  Created by Jonathan on 29/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSEditModeToolViewController.h"
#import "MGSNotifications.h"
#import "MGSMotherModes.h"
#import "MGSToolBarController.h"
#import "MGSNetClient.h"
#import "NSWindow_Mugginsoft.h"
#import "MGSTaskSpecifier.h"

// class extension
@interface MGSEditModeToolViewController()
- (void)scriptCanExecuteStateDidChange:(NSNotification *)notification;
- (void)changeEditMode:(NSNotification *)notification;
- (void)editModeDidChange:(NSNotification *)notification;
@end

const char MGSTaskProcessingContext;

@implementation MGSEditModeToolViewController

/*
 
 initialise for window
 
 */
- (void)initialiseForWindow:(NSWindow *)window
{
	NSAssert(window, @"window is nil");
	
	_lastSegmentedClicked = -1;
	_window = window;
	if (kMGSMotherEditModeConfigure != [segmentedButtons selectedSegment]) {
		[segmentedButtons setSelectedSegment:kMGSMotherEditModeConfigure];
	} else {
		
		// run button click action manually as won't be triggered otherwise
		[self performSelector:[segmentedButtons action] withObject:segmentedButtons];
	}
	
	// register for notifications

	// listen for script can execute state change notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptCanExecuteStateDidChange:) name:MGSNoteWindowCanExecuteScriptStateDidChange object:window];

	// listen for change mode notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeEditMode:) name:MGSNoteWindowEditModeShouldChange object:window];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editModeDidChange:) name:MGSNoteWindowEditModeDidChange object:window];


	// run button will be enabled when script compilation occurs
	[segmentedButtons setEnabled:NO forSegment:kMGSMotherEditModeRun];
}

/*
 
 segmented control click
 
 */
- (IBAction)segControlClicked:(id)sender
{
    NSInteger mode = [sender selectedSegment];	// mode is segment index
	
	// same segment clicked again - ignore
	if (_lastSegmentedClicked == mode) {
		return;
	}
	
	// end editing in window if changing mode
    if (_lastSegmentedClicked != -1) {
        if (![[[self view] window] endEditing:NO]) {
            [sender setSelectedSegment:_lastSegmentedClicked];
            return;
        }
	}
    
	NSString *text = @"";
	
	switch (mode) {
		case kMGSMotherEditModeConfigure:
			text = NSLocalizedString(@"Configure Task",@"toolbar - configure edit mode");
			break;
			
		case kMGSMotherEditModeScript:
			text = NSLocalizedString(@"Edit Task Script",@"toolbar - script edit mode");
			break;

		case kMGSMotherEditModeRun:
			text = NSLocalizedString(@"Run Task",@"toolbar - run edit mode");
			break;
			
		default:
			NSAssert(NO, @"bad segment");
			return;
			
	}
	if (NO) {
		[label setStringValue:text];
	}
	
	// post edit mode changed notification
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:mode], MGSNoteModeKey,
										[NSNumber numberWithInteger:_lastSegmentedClicked], MGSNotePrevModeKey,
										nil];

	_lastSegmentedClicked = mode;

	// mode change request
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteWindowEditModeChangeRequest object:_window userInfo:dict];
}

/*
 
 change edit mode notification
 
 */
- (void)changeEditMode:(NSNotification *)notification
{
	if ([notification object] != _window) return;
	
	NSInteger mode = [[[notification userInfo] objectForKey:MGSNoteModeKey] integerValue];
	
	// reselect run mode to udpate segmented button state and display
	[segmentedButtons setSelectedSegment:mode];
	[self performSelector:[segmentedButtons action] withObject:segmentedButtons];
}

/*
 
 change edit mode notification
 
 */
- (void)editModeDidChange:(NSNotification *)notification
{
	if ([notification object] != _window) return;
	
	NSInteger mode = [[[notification userInfo] objectForKey:MGSNoteModeKey] integerValue];
	
	// reselect run mode to udpate segmented button state and display
	[segmentedButtons setSelectedSegment:mode];	
	_lastSegmentedClicked = mode;
}

/*
 
 - scriptCanExecuteStateDidChange
 
 */
- (void)scriptCanExecuteStateDidChange:(NSNotification *)notification
{
	
	if ([notification object] != _window) return;
	
	// get can execute state
	BOOL canExecute = [[[notification userInfo] objectForKey:MGSNoteBoolStateKey] boolValue];
	
	// enable run segment button if script can execute
	[segmentedButtons setEnabled:canExecute forSegment:kMGSMotherEditModeRun];
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
				
		// remove observers
		@try {
			[_actionSpecifier removeObserver:self forKeyPath:@"isProcessing"];
		} 
		@catch (NSException *e)
		{
			MLog(RELEASELOG, @"%@", [e reason]);
		}
		
		_actionSpecifier = nil;
	}
	
	_actionSpecifier = action;	
		
	// add observers
	[_actionSpecifier addObserver:self forKeyPath:@"isProcessing" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:(void *)&MGSTaskProcessingContext];
}


/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
	
	
	// task is processing
	if (context == &MGSTaskProcessingContext) {
		
		BOOL enableEdit = ![_actionSpecifier isProcessing];
		[segmentedButtons setEnabled:enableEdit forSegment:kMGSMotherEditModeConfigure];
		[segmentedButtons setEnabled:enableEdit forSegment:kMGSMotherEditModeScript];		
	} 
	
}

@end
