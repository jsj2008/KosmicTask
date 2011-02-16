//
//  MGSStopButton.m
//  Mother
//
//  Created by Jonathan on 15/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSStopButton.h"


@implementation MGSStopButton

/* 
 
 init with coder
 
 */
- (id)initWithCoder:(NSCoder *)aCoder
{
	self = [super initWithCoder:aCoder];
	
	[self setImage: [NSImage imageNamed:@"Stop.png"]];
	[self setAlternateImage:[NSImage imageNamed:@"StopPressed.png"]];
	
	[[self cell] setImageDimsWhenDisabled:NO];
	
	return self;
}

/*
 
 set enabled
 
 */
- (void)setEnabled:(BOOL)value
{
	[super setEnabled:value];
	
	if (value) {
		[self setImage:[NSImage imageNamed:@"Stop.png"]];
	} else {
		[self setImage:[NSImage imageNamed:@"StopDisabled.png"]];		
	}
}
@end
