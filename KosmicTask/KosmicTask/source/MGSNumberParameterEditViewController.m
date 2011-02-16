//
//  MGSNumberParameterEditViewController.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSNumberParameterEditViewController.h"
#import "NSView_Mugginsoft.h"
#import "MGSNumberInputViewController.h"
#import "MGSNumberParameterPlugin.h"

NSString *MGSInitialValueContext = @"InitialValue";
NSString *MGSMinValueContext = @"MinValue";
NSString *MGSMaxValueContext = @"MaxValue";
NSString *MGSIncrementValueContext = @"IncrementValue";

@implementation MGSNumberParameterEditViewController

@synthesize wholeNumber = _wholeNumber;
@synthesize initialValue = _initialValue;
@synthesize minValue = _minValue;
@synthesize maxValue = _maxValue;
@synthesize incrementValue = _incrementValue;

/*
 
 init  
 
 */
- (id)init
{
	if ([super initWithNibName:@"NumberParameterEditView"]) {
		self.wholeNumber = YES;
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
	
	// bind it
	[wholeNumberCheckbox bind:NSValueBinding toObject:self withKeyPath:@"wholeNumber" options:nil];
	
	// allocate our input views
	_initialValueInput = [[MGSNumberInputViewController alloc] init];
	_minValueInput = [[MGSNumberInputViewController alloc] init];
	_maxValueInput = [[MGSNumberInputViewController alloc] init];
	_incrementValueInput = [[MGSNumberInputViewController alloc] init];

	// add to view hierarchy
	[[self view] replaceSubview:initialValueInputView withViewFrameAsOld:[_initialValueInput view]];
	[[self view] replaceSubview:minValueInputView withViewFrameAsOld:[_minValueInput view]];
	[[self view] replaceSubview:maxValueInputView withViewFrameAsOld:[_maxValueInput view]];
	[[self view] replaceSubview:incrementValueInputView withViewFrameAsOld:[_incrementValueInput view]];
	
	// bind to controller
	[_initialValueInput bind:@"value" toObject:self withKeyPath:@"initialValue" options:nil];
	[_minValueInput bind:@"value" toObject:self withKeyPath:@"minValue" options:nil];
	[_maxValueInput bind:@"value" toObject:self withKeyPath:@"maxValue" options:nil];
	[_incrementValueInput bind:@"value" toObject:self withKeyPath:@"incrementValue" options:nil];
}

/*
 
 update plist
 
 */
- (void)updatePlist
{
	[self.plist setObject:[NSNumber numberWithDouble:self.initialValue] forKey:MGSScriptKeyDefault];
	[self.plist setObject:[NSNumber numberWithDouble:self.minValue] forKey:MGSKeyNumberMinValue];
	[self.plist setObject:[NSNumber numberWithDouble:self.maxValue] forKey:MGSKeyNumberMaxValue];
	[self.plist setObject:[NSNumber numberWithDouble:self.incrementValue] forKey:MGSKeyNumberIncrementValue];
	[self.plist setObject:[NSNumber numberWithBool:self.wholeNumber] forKey:MGSKeyNumberRequireInteger];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	self.initialValue =  [[self.plist objectForKey:MGSScriptKeyDefault withDefault:[NSNumber numberWithDouble:1]] doubleValue];
	self.minValue = [[self.plist objectForKey:MGSKeyNumberMinValue withDefault:[NSNumber numberWithDouble:0]] doubleValue];
	self.maxValue = [[self.plist objectForKey:MGSKeyNumberMaxValue withDefault:[NSNumber numberWithDouble:10]] doubleValue];
	self.incrementValue = [[self.plist objectForKey:MGSKeyNumberIncrementValue withDefault:[NSNumber numberWithDouble:1]] doubleValue];
	self.wholeNumber = [[self.plist objectForKey:MGSKeyNumberRequireInteger withDefault:[NSNumber numberWithBool:YES]] boolValue];
}

/*
 
 set whole number
 
 */
- (void)setWholeNumber:(BOOL)aBool
{
	_wholeNumber = aBool;
}
@end
