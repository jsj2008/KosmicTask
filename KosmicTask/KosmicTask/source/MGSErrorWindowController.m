//
//  MGSErrorWindowController.m
//  Mother
//
//  Created by Jonathan on 17/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#define ERROR_SEGMENT 0
#define LOG_SEGMENT 1

#import "MGSMother.h"
#import "MGSErrorWindowController.h"
#import "MGSPreferences.h"
#import "NSTextView_Mugginsoft.h"
#import "UKKQueue.h"
#import "PLMailer.h"

NSString *MGSSupportEmail = @"support@mugginsoft.com";

@implementation MGSErrorWindowController

/*
 
 init
 
 */
- (id)init
{
	[super initWithWindowNibName:@"ErrorWindow"];
	_logRetrieved = NO;
	return self; 
}

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	
	[[self window] setDelegate:self];
	[[self window] setExcludedFromWindowsMenu:YES];	// don't want this in the menu
	
	[textView setLineWrap:NO];
	[[textView layoutManager] setBackgroundLayoutEnabled:YES];
	[[textView layoutManager] setAllowsNonContiguousLayout:YES];
	
	_errorController = [[NSArrayController alloc] init];
	[_errorController setContent:[NSMutableArray arrayWithCapacity:2]];
	
	
	// set up the bindings
	[[tableview tableColumnWithIdentifier:@"date"] bind:@"value" toObject:_errorController withKeyPath:@"arrangedObjects.date" options:nil];
	[[tableview tableColumnWithIdentifier:@"domain"] bind:@"value" toObject:_errorController withKeyPath:@"arrangedObjects.domain" options:nil];
	[[tableview tableColumnWithIdentifier:@"code"] bind:@"value" toObject:_errorController withKeyPath:@"arrangedObjects.code" options:nil];
	[[tableview tableColumnWithIdentifier:@"description"] bind:@"value" toObject:_errorController withKeyPath:@"arrangedObjects.localizedDescription" options:nil];
	[[tableview tableColumnWithIdentifier:@"reason"] bind:@"value" toObject:_errorController withKeyPath:@"arrangedObjects.localizedFailureReasonPreview" options:nil];
}

/*
 
 retrieve log

 note: tried using UKKQueue to get more notifications
 such as file size change etc but did not seem to work.

 */
- (void)retrieveLog
{
	// don't cycle the log while viewing it as it only causes confusion
	[[MLog sharedController] setRecycle:NO];
	
	// load log text
	NSString *logText = [[MLog sharedController] logFileRecentText];
		
	// if only logging to console then make a note of this
	BOOL MLogConsoleOnlyLogging = [[NSUserDefaults standardUserDefaults] boolForKey:MGSEnableLoggingToConsoleOnly];
	if (MLogConsoleOnlyLogging) {
		logText = [logText stringByAppendingString:@"\n\n *** LOGGING IS OFF. Enable using the debug panel.\n\n"];
	}
	
	// show log text
	[textViewScroller setFloatValue:1.0f];
	[textView setString:logText];
	
	// NOTE:
	// scrollRangeToVisible is very slow as it has to layout all the text
	// if the text gets large then this method can kill.
	//
	[textView scrollRangeToVisible:NSMakeRange([[textView textStorage] length], 0)];
	[textViewScroller setFloatValue:1.0f];
	[self updateLogSizeDisplay];
	_logRetrieved = YES;
	
	// register for file notifications
	UKKQueue *kq = [UKKQueue sharedFileWatcher];	// starts up a watcher thread
	[kq setDelegate:self];	// use delegate messages as they will be executed on this thread
	NSString *path = [[MLog sharedController] path];
	
	// if add too many notifications seems to fail
	[kq addPathToQueue: path notifyingAbout: UKKQueueNotifyAboutWrite];

	// notifications are excecuted within the watcher thread context which can crash the NSTextView
    //NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
    //NSNotificationCenter* notificationCenter = [workspace notificationCenter];
	//[notificationCenter addObserver:self selector:@selector(logFileChanged:) name:UKFileWatcherWriteNotification object:nil];
	//[notificationCenter addObserver:self selector:@selector(logFileChanged:) name:UKFileWatcherRenameNotification object:nil];
	//[notificationCenter addObserver:self selector:@selector(logFileChanged:) name:UKFileWatcherDeleteNotification object:nil];
}


/*
 
 UKKQueue delegate method
 
 */
-(void) watcher: (id<UKFileWatcher>)kq receivedNotification: (NSString*)nm forPath: (NSString*)fpath
{
	#pragma unused(kq)
	#pragma unused(nm)
	#pragma unused(fpath)
	
	//NSString *name = [notification name];
	//if ([name isEqualToString:UKFileWatcherWriteNotification]) {
		[self updateLogDisplay];
	//}
	
	//else if ([name isEqualToString:UKFileWatcherDeleteNotification]) {
	//	[textView setString:@""];
	//}
	
}

// notification received from UKKQueue when log file changes
/*
- (void)logFileChanged: (NSNotification *)notification
{
	NSString *name = [notification name];
	if ([name isEqualToString:UKFileWatcherWriteNotification]) {
		[self updateLogDisplay];
	}
	
	else if ([name isEqualToString:UKFileWatcherDeleteNotification]) {
		[textView setString:@""];
	}
}
 */

/*
 
 update log display
 
 */
- (void)updateLogDisplay
{
	if (NO == _logRetrieved) {
		[textView setString:@""];
	}
	
	/*
	unsigned long long textLength = (unsigned long long)[[textView textStorage] length];
	NSString *logChanges = [[MLog sharedController] textStartingAtLocation: textLength];
	 */
	
	NSString *logChanges = [[MLog sharedController] logFileRecentText];
	
	// update the log display
	if (logChanges) {
		float scrollerValue = [textViewScroller floatValue];
		if ((NSInteger)scrollerValue == 1) {
			[textView addStringAndScrollToVisible:logChanges];
			[textViewScroller setFloatValue:1.0f];	// force to 1.0 otherwise it can fall to 0.99xx which spoils operation
		} else {
			[textView addString:logChanges];
		}
	}

	[self updateLogSizeDisplay];
}

/*
 
 update log size display
 
 */

- (void)updateLogSizeDisplay
{
	NSString *logSize = [NSString stringWithFormat: NSLocalizedString(@"Size: %3.1f KB", @"log size"), (float)[[textView textStorage] length]/1024];
	[logSizeTextField setStringValue:logSize];

}
/*
 
 add an error
 
 */
- (void)addError:(MGSError *)error
{
	[_errorController addObject:error];
}

/*
 
 segment control clicked
 
 */
- (IBAction)segControlClick:(id)sender
{
	#pragma unused(sender)
	
	NSInteger idx = [modeSegment selectedSegment];
	BOOL logHidden;
	
	switch ([modeSegment selectedSegment]) {
		case ERROR_SEGMENT:
			[tabView selectTabViewItemAtIndex:idx];	
			logHidden = YES;
			break;
			
		case LOG_SEGMENT:
			[tabView selectTabViewItemAtIndex:idx];
			if (!_logRetrieved) {
				[textView setString:NSLocalizedString(@"Retrieving log...", @"Log window message")];
				//[NSThread detachNewThreadSelector:@selector(retrieveLog) toTarget:self withObject:nil];
				[self performSelector:@selector(retrieveLog) withObject:nil afterDelay:0.2];
			}
			logHidden = NO;
			break;
			
		default:
			return;
	}
	[logSizeTextField setHidden:logHidden];
}

/*
 
 send log
 
 */
- (IBAction)sendLog:(id)sender
{
	#pragma unused(sender)
	
	PLMailer *mailer = [[PLMailer alloc] init];
	
	[mailer setTo:MGSSupportEmail];
	[mailer setSubject:@"KosmicTask log"];
	
	NSString *bodyLeader = @"Problem description:\n\n\n\nLog:\n\n";
	NSMutableAttributedString *body = [[NSMutableAttributedString alloc] initWithString:bodyLeader];
	NSString *logText = [[MLog sharedController] logFileText];
	[body appendAttributedString:[[NSAttributedString alloc] initWithString:logText]];
	[mailer setBody:body];
	[mailer setType:PLMailerUrlType];
	[mailer send:self];
}

/*
 
 clear log
 
 */
- (IBAction)clearLog:(id)sender
{
	#pragma unused(sender)
	
	// clear the error content
	[_errorController setContent:[NSMutableArray arrayWithCapacity:2]];
	
	// remove observers
	//[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[UKKQueue sharedFileWatcher] removePathFromQueue:[[MLog sharedController] path]];
	
	// clear log
	[[MLog sharedController] clear];
	[textView setString:@""];
	
	// retrieve new log
	[self performSelector:@selector(retrieveLog) withObject:nil afterDelay:0.0];
}
@end
