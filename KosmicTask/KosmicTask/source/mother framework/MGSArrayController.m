//
//  MGSArrayController.m
//  Mother
//
//  Created by Jonathan on 10/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSArrayController.h"

@implementation MGSArrayController

@synthesize modelDataModified = _modelDataModified;

- (id)init
{
	if ([super init]) {
		self.modelDataModified = NO;
	}
	return self;
	
}
// this will be called by the binding machinery to
// modify the model data
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
	self.modelDataModified = YES;
	[super setValue:value forKeyPath:keyPath];
}

@end
