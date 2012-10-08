//
//  MGSStopActionSheetController.m
//  Mother
//
//  Created by Jonathan on 24/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSStopActionSheetController.h"
#import "MGSRequestViewManager.h"

#define TIMER_INTERVAL 2.0f
#define TERMINATE_TIMEOUT 10.0

// class extension
@interface MGSStopActionSheetController()
- (void)actionMonitorTimerExpired:(NSTimer*)theTimer;
- (void)responseTimerExpired:(NSTimer*)theTimer;
@end

@implementation MGSStopActionSheetController

@synthesize processingCount = _processingCount;

/*
 
 init
 
 */
- (id)init
{
	self = [super initWithWindowNibName:@"StopActionSheet"];
	return self;
}

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	_acceptButtonQuits = NO;
}

/*
 
 processing count
 
 */

- (void)setProcessingCount:(NSInteger)count
{
	_processingCount = count;
	NSString *format;
	if (_processingCount < 1) {
		format = NSLocalizedString(@"All tasks stopped.", @"Application quit dialog title text - all tasks stopped");
	} else if (_processingCount == 1) {
		format = NSLocalizedString(@"There is %i task currently running.", @"Application quit dialog title text - 1 task still running");
	} else {
		format = NSLocalizedString(@"There are %i task currently running.", @"Application quit dialog title text - more than 1 task still running");
	}
	NSString *title = [NSString stringWithFormat:format, _processingCount];
	[titleTextField setStringValue:title];
	
	// setup timer to monitor actions
	if (!_actionMonitorTimer) {
		_actionMonitorTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(actionMonitorTimerExpired:) userInfo:nil repeats:YES];
	}
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
 
 accept
 
 */
- (IBAction)accept:(id)sender
{
	#pragma unused(sender)
	
	NSInteger processingCount = [[MGSRequestViewManager sharedInstance] processingCount];
	
	// if accept button quits or all processing actions have stopped
	if (processingCount == 0) {
		[self closeWindowWithReturnCode:1];
		return;
	}

	// if accept button quits or all processing actions have stopped
	if (_acceptButtonQuits) {
		[self closeWindowWithReturnCode:2];
		return;
	}
	
	// disable buttons and show info
	[cancelButton setEnabled:NO];
	[acceptButton setEnabled:NO];
	[infoView setHidden:NO];
	[progressIndicator startAnimation:self];
	[_actionMonitorTimer invalidate];
	
	// setup timer to monitor responses indicating that actions have indeed been stopped
	_responseTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(responseTimerExpired:) userInfo:nil repeats:YES];
	
	// stop all running actions
	_responseCount = 0;
	_waitTime = 0.0f;
	_stoppedActionCount = [[MGSRequestViewManager sharedInstance] stopAllRunningActions:self];
}

/*
 
 aaction monitor timer expired
 
 */
- (void)actionMonitorTimerExpired:(NSTimer*)theTimer
{
	#pragma unused(theTimer)
	
	NSInteger processingCount = [[MGSRequestViewManager sharedInstance] processingCount];
	[self setProcessingCount:processingCount];
	
	// all actions have terminated
	if (processingCount == 0) {
		[_actionMonitorTimer invalidate];
		_actionMonitorTimer = nil;
		[cancelButton setEnabled:NO];
		[acceptButton setEnabled:NO];
		
		// send quitNow: after short delay
		[self performSelector:@selector(quitNow:) withObject:self afterDelay:2.0];
	}
}

/*
 
 quit now
 
 */
- (void)quitNow:(id)sender
{
	#pragma unused(sender)
	
	[self closeWindowWithReturnCode:1];
}

/*
 
 response timer expired
 
 */
- (void)responseTimerExpired:(NSTimer*)theTimer
{
	#pragma unused(theTimer)
	
	// if a response has been received for all of our action
	// terminations then quit
	if (_responseCount >= _stoppedActionCount) {
		[_responseTimer invalidate];
		_responseTimer = nil;
		[self closeWindowWithReturnCode:1];
		return;
	}

	// if we have waited long enough for responses to our
	// termination request then
	_waitTime += TIMER_INTERVAL;
	if (_waitTime >= TERMINATE_TIMEOUT) {
		[_responseTimer invalidate];
		_responseTimer = nil;

		NSString *format;
		NSInteger noResponseCount = _stoppedActionCount - _responseCount;
			
		// set title
		if (noResponseCount == 1) {
			format = NSLocalizedString(@"%i task did not respond.", @"Application quit dialog title text - 1 task did not confirm termination");
		} else {
			format = NSLocalizedString(@"%i tasks did not respond.", @"Application quit dialog title text - more than 1 task did not confirm termination");
		}
		NSString *title = [NSString stringWithFormat:format, noResponseCount];
		[titleTextField setStringValue:title];

		// set message
		NSString *message = NSLocalizedString(@"All running tasks did not respond to the terminate request.\n\nTo quit now press the Quit button.", @"Application quit dialog message text - all tasks did not confirm termination");
		[messageTextField setStringValue:message];
		
		// hide info panel
		[infoView setHidden:YES];
		[progressIndicator stopAnimation:self];

		// still should be able to cancel out
		[cancelButton setEnabled:YES];

		// accept button now quits
		[acceptButton setEnabled:YES];
		[acceptButton setTitle:NSLocalizedString(@"Quit", @"Application quit - terminate task sheet - button text")];
		_acceptButtonQuits = YES;
	}
}

/*
 
 close window with return code
 
 */
- (void)closeWindowWithReturnCode:(NSInteger)returnCode
{	
	if (_actionMonitorTimer) {
		[_actionMonitorTimer invalidate];
		_actionMonitorTimer = nil;
	}
	[progressIndicator stopAnimation:self];
	
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:returnCode];
}


#pragma mark MGSNetRequestOwner protocol methods

/*
 
 net request responce
 
 */
-(void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	#pragma unused(netRequest)
	#pragma unused(payload)
	
	_responseCount++;
	
	// feedback on number actions terminated
	NSString *format = NSLocalizedString(@"%i of %i tasks stopped.", @"Application quit dialog title text - confirmation of number of tasks stopped");
	NSString *title = [NSString stringWithFormat:format, _responseCount, _stoppedActionCount];
	[titleTextField setStringValue:title];
}
@end
