//
//  MGSParameterEndViewController.m
//  Mother
//
//  Created by Jonathan on 12/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterEndViewController.h"
#import "MGSCapsuleTextCell.h"

@implementation MGSParameterEndViewController

@synthesize inputSegmentedControl;
@synthesize contextPopupButton;

/*
 
 init
 
 */
- (id)init
{
	if ([super initWithNibName:@"ParameterEndView" bundle:nil]) {
	}
	return self;
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	NSCell *cell = [_textField cell];
	if ([cell isKindOfClass:[MGSCapsuleTextCell class]]) {
		[(MGSCapsuleTextCell *)cell setCapsuleHasShadow:YES];
	}
}

@end
