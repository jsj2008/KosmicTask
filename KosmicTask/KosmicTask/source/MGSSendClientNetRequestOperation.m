//
//  MGSSendClientNetRequestOperation.m
//  KosmicTask
//
//  Created by Jonathan on 27/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSSendClientNetRequestOperation.h"


@implementation MGSSendClientNetRequestOperation

/*
 
 - init
 
 */
- (id)init
{
	
	return self;
}

/*
 
 - main
 
 */
-(void)main {
	@try {
	}
	@catch(...) {
		// Do not rethrow exceptions.
	}
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

- (void)start {
	// Always check for cancellation before launching the task.
	if ([self isCancelled])
	{
		// Must move the operation to the finished state if it is canceled.
		[self willChangeValueForKey:@"isFinished"];
		finished = YES;
		[self didChangeValueForKey:@"isFinished"];
		return;
	}
	
	// If the operation is not canceled, begin executing the task.
	[self willChangeValueForKey:@"isExecuting"];
	[NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
	executing = YES;
	[self didChangeValueForKey:@"isExecuting"];
}
@end
