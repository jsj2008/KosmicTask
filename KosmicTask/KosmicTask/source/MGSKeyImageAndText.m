//
//  MGSKeyObject.m
//  Mother
//
//  Created by Jonathan on 13/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSKeyImageAndText.h"


@implementation MGSKeyImageAndText

@synthesize key = _key;

- (id)init
{
	if ([super init]) {
		_key = nil;
	}
	return self;
}

@end
