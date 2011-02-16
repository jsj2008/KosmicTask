//
//  MGSActionToolViewController.m
//  Mother
//
//  Created by Jonathan on 14/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionToolViewController.h"
#import "MGSNotifications.h"

@implementation MGSActionToolViewController

- (void)initialiseForWindow:(NSWindow *)window
{
	NSAssert(window, @"window is nil");
	
}

- (IBAction)newAction:(id)sender
{
	#pragma unused(sender)
	
	// post create new action
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteCreateNewTask object:nil userInfo:nil];
}

- (IBAction)deleteAction:(id)sender
{
	#pragma unused(sender)
	
	// post delete selected action
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteDeleteSelectedTask object:nil userInfo:nil];
}

- (IBAction)editAction:(id)sender
{
	#pragma unused(sender)
	
	// post edit selected action
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteEditSelectedTask object:nil userInfo:nil];
}

- (IBAction)duplicateAction:(id)sender
{
	#pragma unused(sender)
	
	// post duplicate selected action
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteDuplicateSelectedTask object:nil userInfo:nil];
}
@end
