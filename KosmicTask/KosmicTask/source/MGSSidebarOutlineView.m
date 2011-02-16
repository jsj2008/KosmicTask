//
//  MGSSidebarOutlineView.m
//  KosmicTask
//
//  Created by Jonathan on 13/02/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSSidebarOutlineView.h"

@interface MGSSidebarOutlineView()
- (void)generalInit;
@end

@implementation MGSSidebarOutlineView

@synthesize allowScrollRowVisible;

/* 
 
 init with coder
 
 */
- (id)initWithCoder:(NSCoder *)aCoder
{
	self = [super initWithCoder:aCoder];
	if (self) {
		[self generalInit];
	}
	
	return self;
}	

/*
 
 - initWithFrame:
 
 */
- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		[self generalInit];
	}
	
	return self;
	
}
/*
 
 - generalInit
 
 */
- (void)generalInit
{
	allowScrollRowVisible = NO;
}
/*
 
 - scrollRowToVisible:
 
 */
- (void)scrollRowToVisible:(NSInteger)row {
	if (self.allowScrollRowVisible) {
		[super scrollRowToVisible:row];
	}
}

@end
