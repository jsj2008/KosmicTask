//
//  MGSDateParameterEditViewController.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSDateParameterEditViewController.h"
#import "MGSDateParameterPlugin.h"

@implementation MGSDateParameterEditViewController

@synthesize initialDate = _initialDate;
@synthesize initialiseToCurrentDate = _initialiseToCurrentDate;
@synthesize enableDatePickers = _enableDatePickers;

/*
 
 init 
 
 */
- (id)init
{
	if ([super initWithNibName:@"DateParameterEditView"]) {
		self.parameterDescription = NSLocalizedString(@"Select a date.", @"Date selection prompt");
	}
	return self;
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	// call our super implementation
	[super awakeFromNib];
	
	// establish value bindings
	[textualDatePicker bind:NSValueBinding toObject:self withKeyPath:@"initialDate" options:nil];
	[graphicalDatePicker bind:NSValueBinding toObject:self withKeyPath:@"initialDate" options:nil];
	[currentDateCheckBox bind:NSValueBinding toObject:self withKeyPath:@"initialiseToCurrentDate" options:nil];
	
	// establish availability binsings
	[textualDatePicker bind:NSEnabledBinding toObject:self withKeyPath:@"enableDatePickers" options:nil];
	[graphicalDatePicker bind:NSEnabledBinding toObject:self withKeyPath:@"enableDatePickers" options:nil];
}


/*
 
 update plist
 
 */
- (void)updatePlist
{
	[self.plist setObject:self.initialDate forKey:MGSScriptKeyDefault];
	[self.plist setObject:[NSNumber numberWithBool:self.initialiseToCurrentDate] forKey:MGSKeyInitialiseToCurrentDate];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	self.initialDate =  [self.plist objectForKey:MGSScriptKeyDefault withDefault:[NSDate date]];
	self.initialiseToCurrentDate = [[self.plist objectForKey:MGSKeyInitialiseToCurrentDate withDefault:[NSNumber numberWithBool:NO]] boolValue];
}


/*
 
 set initialise to current date
 
 */

- (void)setInitialiseToCurrentDate:(BOOL)value
{
	_initialiseToCurrentDate = value;
	if (_initialiseToCurrentDate) {
		self.initialDate = [NSDate date];
	}
	self.enableDatePickers = !_initialiseToCurrentDate;
}
@end
