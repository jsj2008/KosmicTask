//
//  MGSDebugHandler.m
//  mother
//
//  Created by Jonathan Mitchell on 13/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSDebugHandler.h"
#import "MGSDebugController.h"
#import "MGSPreferences.h"

#import <sys/types.h>
#import <sys/time.h>
#import <sys/resource.h>
#import <errno.h>

// private category
@interface MGSDebugHandler (Private)
- (void)enableCoreDumpsChange;
- (void)enableDebugLoggingChange;
@end

@implementation MGSDebugHandler

- (id) init
{
	if ([super init]) {
		NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		
		// observe reqd user defaults
		[ud addObserver:self forKeyPath:MGSEnableCoreDumps options:NSKeyValueObservingOptionNew context:@selector(enableCoreDumpsChange)];
		[ud addObserver:self forKeyPath:MGSEnableDebugLogging options:NSKeyValueObservingOptionNew context:@selector(enableDebugLoggingChange)];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	
	NSKeyValueChange keyValueChangeKind = [((NSNumber *)[change objectForKey:NSKeyValueChangeKindKey]) intValue];
	
	if (keyValueChangeKind == NSKeyValueChangeSetting) {
		if ([self respondsToSelector:(SEL)context])
		{
			[self performSelector:(SEL)context];
		}
	}
}

- (void)dealloc
{
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
	@try {
		[ud removeObserver:self forKeyPath:MGSEnableCoreDumps];
		[ud removeObserver:self forKeyPath:MGSEnableDebugLogging];
	} 
	@catch (NSException *e) {
		MLog(RELEASELOG, @"%@", [e reason]);
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	#pragma unused(aNotification)
	
	// enable debug logging
	if ([[NSUserDefaults standardUserDefaults] boolForKey:MGSEnableDebugLogging]) {
		[self enableDebugLogging:YES];
	}
	
	// enable core dumps
	if ([[NSUserDefaults standardUserDefaults] boolForKey:MGSEnableCoreDumps]) {
		[self enableCoreDumps:YES];
	}
}

- (void) enableDebugLogging: (BOOL)enable
{
	#pragma unused(enable)
}

// enable core dumps
// see Dalrymple and Hillegass
- (void) enableCoreDumps: (BOOL)enable
{
	struct rlimit r1;
	
	if (enable) {
		r1.rlim_cur = RLIM_INFINITY;
		r1.rlim_max = RLIM_INFINITY;
	} else {
		r1.rlim_cur = 0;
		r1.rlim_max = 0;
	}
	
	if (setrlimit(RLIMIT_CORE, &r1) == -1) {
		MLogInfo(@"Error enabling core dump capture.");
	}
}

@end

#pragma mark -
#pragma mark Private Methods Category

@implementation MGSDebugHandler (Private)

- (void)enableCoreDumpsChange
{
	BOOL enable = [[NSUserDefaults standardUserDefaults] boolForKey:MGSEnableCoreDumps];
	[self enableCoreDumps:enable];
}

- (void)enableDebugLoggingChange
{
	BOOL enable = [[NSUserDefaults standardUserDefaults] boolForKey:MGSEnableDebugLogging];
	[self enableDebugLogging:enable];
}

@end
