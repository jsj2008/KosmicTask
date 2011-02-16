//
//  MGSParameterSubEditViewController.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterSubEditViewController.h"


@implementation MGSParameterSubEditViewController

/*
 
 designated initilaiser
 
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.updatesDocumentEdited = YES;
	}
	
	return self;
}

/*
 
 can drag height
 
 */
- (BOOL)canDragHeight
{
	return YES;
}

@end
