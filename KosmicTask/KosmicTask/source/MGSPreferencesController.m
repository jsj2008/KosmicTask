//
//  PreferencesController.m
//  mother
//
//  Created by Jonathan Mitchell on 07/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSPreferencesController.h"
#import "MGSDebugController.h"

@implementation MGSPreferencesController

- (id)init
{
	self = [super initWithWindowNibName:@"PreferencesPanel"];
	return self;
}

// show debug panel
- (IBAction) showDebugPanel:(id)sender
{
	if (debugController == nil) {
		debugController = [[MGSDebugController alloc] init];
	}
	[debugController showWindow:self];
}

- (void) dealloc
{
	[debugController release];
	[super dealloc];
}
@end
