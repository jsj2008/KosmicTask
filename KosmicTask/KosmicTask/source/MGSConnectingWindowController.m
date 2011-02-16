//
//  MGSConnectingWindowController.m
//  Mother
//
//  Created by Jonathan on 27/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSConnectingWindowController.h"
#import "MGSAppController.h"
#import "MGSLM.h"

@implementation MGSConnectingWindowController
@synthesize version = _version;
@synthesize licensedTo = _licensedTo;

/*
 
 init
 
 */
- (id)init
{
	self = [super initWithWindowNibName:@"ConnectingWindow"];
	//_delegate = nil;
	return self;
}

/* 
 
 window did load
 
 */
- (void)windowDidLoad
{
	// version
	MGSAppController *appController = [NSApp delegate];
	self.version = [appController versionStringForDisplay];
	
}

/*
 
 show window
 
 */
- (void)showWindow:(id)sender
{
	[self window];
	
	// licencee
	self.licensedTo = [NSString stringWithFormat: NSLocalizedString(@"%@", @"Connecting window licencee text"), 
					   [[MGSLM sharedController] firstOwner]];
	
	[progressIndicator startAnimation:self];
	[super showWindow:sender];
}

/*
 
 hide window
 
 */
- (void)hideWindow:(id)sender
{
	#pragma unused(sender)
	
	[progressIndicator stopAnimation:self];
	[[self window] orderOut:self];
}

@end
