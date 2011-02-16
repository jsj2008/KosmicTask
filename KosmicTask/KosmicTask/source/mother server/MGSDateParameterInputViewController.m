//
//  MGSDateParameterInputViewController.m
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSDateParameterInputViewController.h"
#import "MGSDateParameterPlugin.h"

@implementation MGSDateParameterInputViewController


/*
 
 init  
 
 */
- (id)init
{
	if ([super initWithNibName:@"DateParameterInputView"]) {
		
		
	}
	return self;
}



/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	[super awakeFromNib];

	// bind it
	[textualDatePicker bind:NSValueBinding toObject:self withKeyPath:@"parameterValue" options:nil];
	[graphicalDatePicker bind:NSValueBinding toObject:self withKeyPath:@"parameterValue" options:nil];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	// parameterValue will be assigned to default automatically
	
	// initialise to todays date if required
	_initialiseToCurrentDate =  [[self.plist objectForKey:MGSKeyInitialiseToCurrentDate withDefault:[NSNumber numberWithBool:YES]] boolValue];
	if (_initialiseToCurrentDate) {
		[self resetToDefaultValue];
	}
}

/*
 
 override reset to default value
 
 */
- (void)resetToDefaultValue
{
	if (_initialiseToCurrentDate) {
		[self commitEditing];
		self.parameterValue = [NSDate date];
	} else {
		[super resetToDefaultValue];
	}
}
@end
