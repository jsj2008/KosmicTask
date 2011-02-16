//
//  MGSSidebarOutlineController.m
//  Mother
//
//  Created by Jonathan on 22/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSSidebarOutlineController.h"
#import "MGSOutlineViewNode.h"

@implementation MGSSidebarOutlineController

- (id) init
{
	if ((self = [super init])) {
		[self setObjectClass:[MGSOutlineViewNode class]];	// add this class
	}
	return self;
}

@end
