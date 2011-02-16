//
//  MGSServerRequestThreadHelper.m
//  Mother
//
//  Created by Jonathan on 15/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSServerRequestThreadHelper.h"


@implementation MGSServerRequestThreadHelper

@synthesize script = _script;
@synthesize netRequest = _netRequest;
@synthesize error = _error;
@synthesize boolValue = _boolValue;

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		_boolValue = NO;
	}
	return self;
}
@end
