//
//  MGSNumberParameterInputViewController.m
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSNumberParameterInputViewController.h"
#import "MGSNumberInputViewController.h"
#import "NSView_Mugginsoft.h"
#import "MGSNumberParameterPlugin.h"
#import "MGSKeyValueBinding.h"

@implementation MGSNumberParameterInputViewController

@synthesize minValue = _minValue;
@synthesize maxValue = _maxValue;
@synthesize wholeNumber = _wholeNumber;
@synthesize incrementValue = _incrementValue;

/*
 
 init  
 
 */
- (id)init
{
	if ([super initWithNibName:@"NumberParameterInputView"]) {
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
	[_valueSlider bind:NSValueBinding toObject:self withKeyPath:@"parameterValue" options:
			[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSValidatesImmediatelyBindingOption, nil]];
	[_valueSlider bind:NSMinValueBinding toObject:self withKeyPath:@"minValue" options:nil];
	[_valueSlider bind:NSMaxValueBinding toObject:self withKeyPath:@"maxValue" options:nil];
	[_minValueTextField bind:NSValueBinding toObject:self withKeyPath:@"minValue" options:nil];
	[_maxValueTextField bind:NSValueBinding toObject:self withKeyPath:@"maxValue" options:nil];
	
	// create number input view - class defined in plugin
	_numberInputViewController = [[MGSNumberInputViewController alloc] init];
	[[self view] replaceSubview:valueInputView withViewFrameAsOld:[_numberInputViewController view]];	// load the input view
	
	// bind the input view
	[_numberInputViewController bind:NSValueBinding toObject:self withKeyPath:@"parameterValue" options:nil];
	[_numberInputViewController bind:MGSIntegralValueBinding toObject:self withKeyPath:@"wholeNumber" options:nil];
	[_numberInputViewController bind:MGSIncrementValueBinding toObject:self withKeyPath:@"incrementValue" options:nil];
	[_numberInputViewController bind:NSMinValueBinding toObject:self withKeyPath:@"minValue" options:nil];
	[_numberInputViewController bind:NSMaxValueBinding toObject:self withKeyPath:@"maxValue" options:nil];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	NSNumber *minNumber = [self.plist objectForKey:MGSKeyNumberMinValue withDefault:[NSNumber numberWithDouble:0]];
	NSNumber *maxNumber = [self.plist objectForKey:MGSKeyNumberMaxValue withDefault:[NSNumber numberWithDouble:100]];
	
	self.minValue = [minNumber doubleValue];
	self.maxValue = [maxNumber doubleValue];
	self.wholeNumber = [[self.plist objectForKey:MGSKeyNumberRequireInteger withDefault:[NSNumber numberWithBool:YES]] boolValue];
	self.incrementValue = [[self.plist objectForKey:MGSKeyNumberIncrementValue withDefault:[NSNumber numberWithDouble:1]] doubleValue];

	NSString *fmt = nil;
	if (self.wholeNumber) {
		fmt = NSLocalizedString(@"A whole number between %@ and %@", @"label text");
	} else {
		fmt = NSLocalizedString(@"A number between %@ and %@", @"label text");
	}
	self.label = [NSString stringWithFormat:fmt, minNumber, maxNumber];
}

/*
 
 parameter value
 
 */
- (id)parameterValue
{
	id value = [super parameterValue];
	if (self.wholeNumber) {
		value = [NSNumber numberWithInteger:[value integerValue]];
	}
	
	return value;
}
@end
