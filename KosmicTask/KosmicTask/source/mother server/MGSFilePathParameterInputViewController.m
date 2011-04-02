//
//  MGSFilePathParameterInputViewController.m
//  KosmicTask
//
//  Created by Jonathan on 02/04/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSFilePathParameterInputViewController.h"


@implementation MGSFilePathParameterInputViewController

/*
 
 init  
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.sendAsAttachment = NO;
		self.fileLabel = @"File Path";
	}
	return self;
}
@end
