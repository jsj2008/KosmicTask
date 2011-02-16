//
//  MGSImageAndText.m
//  Mother
//
//  Created by Jonathan on 16/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSImageAndText.h"
#import "MGSImageAndTextCell.h"

NSString *MGSImageAndTextValueKey = @"value";

@implementation MGSImageAndText

@synthesize value = _value;
@synthesize indentation = _indentation;
@synthesize image = _image;
@synthesize count = _count;
@synthesize hasCount = _hasCount;
@synthesize countColor = _countColor;
@synthesize statusImage = _statusImage;
@synthesize countAlignment = _countAlignment;

- (id)init
{
	if ([super init]) {
		_value = nil;
		_indentation = 0;
		_count = 0;
		_hasCount = NO;
		_countColor = [[MGSImageAndTextCell countColor] copy];
		_image = nil;
		_statusImage = nil;
		_countAlignment = MGSAlignRight;
	}
	return self;
}

/*
 
 compare
 
 */
- (NSComparisonResult)compare:(MGSImageAndText *)object
{
	id value2 = [object value];
	
	// can only compare matching classes
	if ([_value isKindOfClass:[value2 class]]) {
		
		// if no compare then order same
		if (![_value respondsToSelector:@selector(compare:)]) return NSOrderedSame;
		
		// for strings make it case insenstive
		if ([_value isKindOfClass:[NSString class]]) return [_value caseInsensitiveCompare:value2];
		
		return [_value compare:[object value]];
	}
	
	// default to order same
	return NSOrderedSame;
}

@end
