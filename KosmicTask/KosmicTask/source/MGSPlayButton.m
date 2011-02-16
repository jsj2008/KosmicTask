//
//  MGSPlayButton.m
//  Mother
//
//  Created by Jonathan on 04/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSPlayButton.h"

@implementation MGSPlayButton

/* 
 
 init with coder
 
 */
- (id)initWithCoder:(NSCoder *)aCoder
{
	self = [super initWithCoder:aCoder];

	self.onStateImage =  [NSImage imageNamed:@"Run.png"];
	self.onStateAltImage =  [NSImage imageNamed:@"RunPressed.png"];
	self.onStateDisabledImage =  [NSImage imageNamed:@"RunDisabled.png"];
	self.offStateImage =  [NSImage imageNamed:@"Pause.png"];
	self.offStateAltImage =  [NSImage imageNamed:@"PausePressed.png"];
	self.offStateDisabledImage =  [NSImage imageNamed:@"PauseDisabled.png"];
	self.mixedStateImage =  [NSImage imageNamed:@"Resume.png"];
	self.mixedStateAltImage =  [NSImage imageNamed:@"ResumePressed.png"];
	self.mixedStateDisabledImage =  [NSImage imageNamed:@"ResumeDisabled.png"];
	
	[self setState:NSOnState];
	
	return self;
}


@end
