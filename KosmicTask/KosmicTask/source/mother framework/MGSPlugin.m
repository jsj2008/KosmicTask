//
//  MGSPlugin.m
//  Mother
//
//  Created by Jonathan on 21/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSPlugin.h"
#import "MGSError.h"

static id _sharedInstance = nil;

@implementation MGSPlugin

/*
 
 shared instance
 
 */
+ (id)sharedInstance
{
	if (!_sharedInstance) {
		_sharedInstance = [[self alloc] init];
	}
	return _sharedInstance;
}

/*
 
 - init

 designated initialiser
 
 */
- (id)init
{
	self = [super init];
	if (self) {
	}
	
	return self;
}

/*
 
 interface version
 
 */
- (unsigned)interfaceVersion
{
    return 0; 
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Plugin", @"default plugin menu string");
}

/*
 
 on exception
 
 */
- (void)onException:(NSException *)e
{
	NSString *error = [NSString stringWithFormat: NSLocalizedString(@"Plugin error: %@ ", @"Plugin error string"), e];
	[MGSError clientCode:MGSErrorCodeSendPlugin reason:error];
}


/*
 
 is default
 
 */
- (BOOL)isDefault
{
	return NO;
}

/*
 
 - plugins
 
 */
- (NSArray *)plugins
{
	/*
	 
	 other plugins available
	 
	 */
	return [NSArray new];
}
@end
