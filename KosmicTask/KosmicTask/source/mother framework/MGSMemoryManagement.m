//
//  MGSMemoryManagement.m
//  KosmicTask
//
//  Created by Jonathan on 07/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSMemoryManagement.h"


@implementation MGSMemoryManagement

/*
 
 perform GC collection exhaustively after delay
 
 use with caution.
 did seem to increase likely hood of crash when large data sets loaded into NSTextView
 
 */
+ (void)collectExhaustivelyAfterDelay:(NSTimeInterval)delay
{
#pragma unused(delay)
	// disable this for now
	// see MID:572.
	return;
	
}
@end
