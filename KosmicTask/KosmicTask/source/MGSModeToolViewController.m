//
//  MGSModeToolViewController.m
//  Mother
//
//  Created by Jonathan on 07/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSModeToolViewController.h"
#import "MGSNotifications.h"
#import "MGSMotherModes.h"
#import "MGSToolBarController.h"
#import "MGSNetClient.h"
#import "MGSNetClientContext.h"
#import "MGSRequestViewManager.h"
#import "MGSAppController.h"

// class extension
@interface MGSModeToolViewController()
- (void)changeRunMode:(eMGSMotherRunMode)mode;
- (void)runModeShouldChange:(NSNotification *)notification;
- (void)netClientSelected:(NSNotification *)notification;
- (void)netClientActive:(NSNotification *)notification;
- (void)pendingModeChangeConfirmed:(NSNotification *)notification;
- (void)pendingModeChangeConfirmed:(NSNotification *)notification;
- (void)configureAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
@end

@implementation MGSModeToolViewController

/*
 
 init
 
 */
- (id)init
{
	if ([super init]) {
		_netClient = nil;
	}
	
	return self;
}

/*
 
 initialise
 
 */
- (void)initialiseForWindow:(NSWindow *)window
{
	NSAssert(window, @"window is nil");
	
	_segmentMode = -1;
	
	if (kMGSMotherRunModePublic != [segmentedButtons selectedSegment]) {
		[segmentedButtons setSelectedSegment:kMGSMotherRunModePublic];
		[self updateSegmentModeText:segmentedButtons];
	} else {
		
		// run button click action manually as won't be triggered otherwise
		[self performSelector:[segmentedButtons action] withObject:segmentedButtons];
	}
	
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientSelected:) name:MGSNoteClientSelected object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pendingModeChangeConfirmed:) name:MGSNoteAuthenticateAccessSucceeded object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runModeShouldChange:) name:MGSNoteAppRunModeShouldChange object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pendingModeChangeConfirmed:) name:MGSNoteClientSaveSucceeded object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientActive:) name:MGSNoteClientActive object:nil];
    
    
}

/*
 
 segmented control click
 
 */
- (IBAction)segControlClicked:(id)sender
{
	// mode is segment index.
	// this index corresponds to the runMode
    int mode = [sender selectedSegment];	

	// change run mode
	[self changeRunMode: mode];
}

/*
 
 change run mode
 
 */
- (void)changeRunMode:(eMGSMotherRunMode)mode 
{
	
	// same segment clicked again - ignore
	if (_segmentMode == mode) {
		return;
	}
	
	// don't enter config mode if we have tasks running.
	// once in config mode we cannot start ot stop a task.
	// plus if enter config mode and leave it appears that previously running tasks cannot be stopped.
	// this limitation shoul probably be removed but for first release it will have to stand.
	// note that actions in detached windows can run in congfiguration mode.
	if (mode == kMGSMotherRunModeConfigure && 
		[[MGSRequestViewManager sharedInstance] processingCountInWindow:[[NSApp delegate] applicationWindow]] > 0) {
		
		NSBeginAlertSheet(
						  NSLocalizedString(@"Cannot configure while tasks running.", @"Alert sheet text"),	// sheet message
						  nil,              //  default button label
						  nil,             //  alternate button label
						  nil,              //  other button label
						  [[self view] window],	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  @selector(configureAlertSheetDidEnd:returnCode:contextInfo:),					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  NULL,       // context info
						  NSLocalizedString(@"Please stop tasks running in this window before attempting configuration.\n\nTasks running in other windows may continue.", @"Alert sheet text"),	// additional text
						  nil);
		
		// reset previous segment
		[segmentedButtons setSelectedSegment:_segmentMode];
		return;
	}
	
	// send pending mode
	_pendingSegmentMode = mode;
	
	// leaving configuration mode?
	if (_segmentMode == kMGSMotherRunModeConfigure) {
		
		// ask delegate if mode should change.
		// if changes have to be saved to the server then this has to occur before the mode change
		// can complete.
		// if the user cancels out of the save operation then we will have to reset the selected segment.
		//
		if ([self delegate] && [[self delegate] respondsToSelector:@selector(saveClientBeforeChangeToRunMode:)]) {
			if ([[self delegate] saveClientBeforeChangeToRunMode:mode]) {
				
				// we need to reset the segment display here beacuse the user may have opportunity during the
				// save and review procedure to reselet the segmentedControl
				[segmentedButtons setSelectedSegment:_segmentMode];
				
				// we do not post the mode change until we receive notification of successful save.
				return;
			}
		}
	}	
	
	// info dict supplies mode
	NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:mode], MGSNoteModeKey , nil];

	// we MUST authenticate if leaving public mode
	if (_segmentMode == kMGSMotherRunModePublic) {

		[segmentedButtons setSelectedSegment:_segmentMode];
		[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteShouldAuthenticateAccess object:self userInfo:infoDict];
		
		// we do not post the mode change until we receive notification of successful authentication.
		return;
	}
	
	// set mode and text
	// _segmentMode will be updated here.
	// _prevSegmentMode will retain prev mode
	[self updateSegmentModeText:segmentedButtons];
	
	// post mode changed notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAppRunModeChanged object:self userInfo:infoDict];
}
/*
 
 configure alert sheet ended
 
 */
- (void)configureAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	#pragma unused(contextInfo)

	[sheet orderOut:self];
	
	switch (returnCode) {
			
			// compile
		case NSAlertDefaultReturn:			
		break;
			
			// close and don't save or compile
		case NSAlertAlternateReturn:
			break;
			
			// cancel compile
		case NSAlertOtherReturn:
			break;
	}
}
/*
 
 set toolbar text for selected segment
 
 */
- (void)updateSegmentModeText:(id)sender
{
	int mode = [sender selectedSegment];	// mode is segment index
	
	// select mode text
	NSString *text = @"";
	switch (mode) {
		case kMGSMotherRunModePublic:
			text = NSLocalizedString(@"Public Tasks",@"toolbar - public run mode");
			break;
			
		case kMGSMotherRunModeAuthenticatedUser:
			text = NSLocalizedString(@"Trusted User Tasks",@"toolbar - trusted user mode");
			break;
			
		case kMGSMotherRunModeConfigure:			
			text = NSLocalizedString(@"Configuration",@"toolbar - task configure mode");
			break;
			
		default:
			NSAssert(NO, @"bad segment");
			return;
			
	}
	if (NO) {
		[label setStringValue:text];
	}
	
	// we set the segment mode here
	_prevSegmentMode = _segmentMode;
	_segmentMode = mode;
}

/*
 
 update the segment status
 
 */
- (void)updateSegmentStatus
{
	BOOL enabled;
	
	if ([_netClient hostViaBonjour]) {
		enabled = YES;
	} else {
		// if host not connected (say a manual host that has not come on line)
		// then restrict the run mode selection
		enabled = ([_netClient hostStatus] == MGSHostStatusNotYetAvailable ? NO : YES);
		
		// if  manual host becomes disabled and is configured to reconnect it may
		// remain in the table. make sure the public run mode is selected
		// while disabled
		if (!enabled) {
			[_netClient contextForWindow:[[self view] window]].runMode = kMGSMotherRunModePublic;
		}
	}
	
	[segmentedButtons setEnabled:enabled forSegment:kMGSMotherRunModeConfigure];
	[segmentedButtons setEnabled:enabled forSegment:kMGSMotherRunModeAuthenticatedUser];	
}

/*
 
 set the run mode
 
 */
- (void)setRunMode:(int)mode
{
	[segmentedButtons setSelectedSegment:mode];
	[self segControlClicked:segmentedButtons];
}

// log in
- (IBAction)logIn:(id)sender {
#pragma unused(sender)
	
	/*
	 if (NSOnState == [loginButton state]) {
	 // log in
	 [[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAutheticateLoginAccess object:self userInfo:nil];
	 } else {
	 // log out
	 [[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteLogout object:self userInfo:nil];
	 }
	 */
}

#pragma mark NSNotificationCenter callbacks
/*
 
 netClientSelected:
 
 net client selected in browser
 
 */
- (void)netClientSelected:(NSNotification *)notification
{	
	NSDictionary *userInfo = [notification userInfo];
	MGSNetClient *netClient = [userInfo objectForKey:MGSNoteNetClientKey];
	if (_netClient == netClient) {
		return;
	}
	
	// remove observer
	if (_netClient) {
		@try {
			[_netClient removeObserver:self forKeyPath:MGSNetClientKeyPathHostStatus];
		} 
		@catch (NSException *e)
		{
			MLog(RELEASELOG, @"%@", [e reason]);
		}
		
	}
	
	_netClient = netClient;
	NSAssert(_netClient, @"netClient is nil");
	
	// add observer
	[_netClient addObserver:self forKeyPath:MGSNetClientKeyPathHostStatus options:NSKeyValueObservingOptionNew context:nil];
	
	// update the segment status
	[self updateSegmentStatus];
	
	// set the run mode to that retained by the netclient.
	// it should not be neccesary to initiate any actions here.
	_segmentMode = [_netClient contextForWindow:[[self view] window]].runMode;
	[segmentedButtons setSelectedSegment:_segmentMode];	
}

/*
 
 netClientActive:
 
 */
- (void)netClientActive:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];

	// true if at least one net client is updating
    BOOL isUpdating = [[userInfo objectForKey:@"isUpdating"] boolValue];
    if (isUpdating) {
        [progress startAnimation:self];
    } else {
        [progress stopAnimation:self];
    }
}
//
// mode change cancelled.
//
// tool bar controls reset to reflect reset mode
//
- (void)pendingModeChangeCancelled:(NSNotification *)notification
{
	#pragma unused(notification)
}

//
// pending mode change confirmed
//
// our mode change has been confirmed
//
// send out notification of mode change
//
- (void)pendingModeChangeConfirmed:(NSNotification *)notification
{
	#pragma unused(notification)
	
	// impose our pending mode
	[segmentedButtons setSelectedSegment:_pendingSegmentMode];
	[self updateSegmentModeText:segmentedButtons];
	
	// info dict supplies mode
	NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_segmentMode], MGSNoteModeKey , nil];
	
	// post mode changed notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAppRunModeChanged object:self userInfo:infoDict];
}

/*
 
 run mode should change
 
 */
- (void)runModeShouldChange:(NSNotification *)notification
{
	NSNumber *numberMode = [[notification userInfo] objectForKey:MGSNoteModeKey];
	if (!numberMode) {
		MLog(DEBUGLOG, @"run mode is nil");
		return;
	}
	
	eMGSMotherRunMode mode = [numberMode integerValue];
	[self setRunMode:mode];
}

#pragma mark KVO
/*
 
 KVO observing
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	#pragma unused(change)
	#pragma unused(context)
	
	// net client
	if (object == _netClient) {
		
		// hoststatus
		if ([keyPath isEqualToString:MGSNetClientKeyPathHostStatus]) {
			// update the segment status
			[self updateSegmentStatus];
			
		}
	}
}
@end
