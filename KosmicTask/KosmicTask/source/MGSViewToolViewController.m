//
//  MGSViewToolViewController.m
//  Mother
//
//  Created by Jonathan on 07/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSViewToolViewController.h"
#import "MGSNotifications.h"
#import "MGSMotherModes.h"
#import "MGSNetClient.h"
#import "MGSNetClientContext.h"

@interface MGSViewToolViewController()
- (void)viewConfigDidChange:(NSNotification *)notification;
@end

@implementation MGSViewToolViewController

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
}

/*
 
 initialise
 
 */
- (void)initialiseForWindow:(NSWindow *)window
{
	NSAssert(window, @"window is nil");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewConfigDidChange:) name:MGSNoteViewConfigDidChange object:window];
}


#pragma mark NSNotificationCenter callbacks

/*
 
 view config did change 
 
 */
- (void)viewConfigDidChange:(NSNotification *)notification
{
	
	NSNumber *number = [[notification userInfo] objectForKey:MGSNoteViewConfigKey];
	if (!number) return;
	int viewConfig = [number intValue];
	
	// sync GUI to view state
	switch (viewConfig) {
			
			
			break;
			
		default:
			break;
			
	}
}


@end
