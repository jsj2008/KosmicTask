//
//  MGSNetClientContext.m
//  KosmicTask
//
//  Created by Jonathan on 08/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSNetClientContext.h"

@implementation MGSNetClientContext

@synthesize runMode = _runMode, pendingRunMode = _pendingRunMode;

/*
 
 init with window
 
 designated initialiser
 
 */
- (id)initWithWindow:(NSWindow *)window
{
	if ((self = [super init])) {
		_window = window;
		_runMode = kMGSMotherRunModePublic;
		_pendingRunMode = kMGSMotherRunModePublic;
	}
	
	return self;
}

/*
 
 init
 
 */
- (id)init
{
	return [self initWithWindow:nil];
}

/*
 
 - setRunMode:
 
 */
- (void)setRunMode:(eMGSMotherRunMode)mode
{
	_runMode = mode;
}
@end
