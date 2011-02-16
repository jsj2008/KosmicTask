//
//  MGSShellLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 10/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSShellLanguage.h"


@implementation MGSShellLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initExecutorProcessType = kMGSOutOfProcess;
		self.initExecutorAcceptsOptions = YES;
		self.initExecutableFormat = kMGSSource;
		
		// interface
		self.initSourceFileExtensions = [NSArray arrayWithObjects:@"sh", nil];
		self.initScriptTypeFamily = @"Shell";
	}
	
	return self;
}		
@end
