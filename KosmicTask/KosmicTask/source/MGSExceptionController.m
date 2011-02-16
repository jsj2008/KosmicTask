//
//  ExceptionController.m
//  mother
//
//  Created by Jonathan Mitchell on 06/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSExceptionController.h"


@implementation MGSExceptionController

- (id)init
{
	self = [super initWithWindowNibName:@"ExceptionPanel"];
	return self;
}


- (void) hideExceptionPanel:(id)sender
{
	#pragma unused(sender)
	
	[self close];
}

@end
