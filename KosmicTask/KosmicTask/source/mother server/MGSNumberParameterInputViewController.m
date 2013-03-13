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

char MGSSliderValueContext;

@implementation MGSNumberParameterInputViewController

@synthesize minValue = _minValue;
@synthesize maxValue = _maxValue;
@synthesize incrementValue = _incrementValue;
@synthesize notation = _notation;
@synthesize decimalPlaces = _decimalPlaces;
@synthesize sliderValue = _sliderValue;

/*
 
 init  
 
 */
- (id)init
{
	if ([super initWithNibName:@"NumberParameterInputView"]) {
		_updateSliderValue = YES;
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
	[_valueSlider bind:NSValueBinding toObject:self withKeyPath:@"sliderValue" options:
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
	[_numberInputViewController bind:MGSIncrementValueBinding toObject:self withKeyPath:@"incrementValue" options:nil];
	[_numberInputViewController bind:NSMinValueBinding toObject:self withKeyPath:@"minValue" options:nil];
	[_numberInputViewController bind:NSMaxValueBinding toObject:self withKeyPath:@"maxValue" options:nil];
	[_numberInputViewController bind:MGSNotationBinding toObject:self withKeyPath:@"notation" options:nil];
	[_numberInputViewController bind:MGSDecimalPlacesBinding toObject:self withKeyPath:@"decimalPlaces" options:nil];

	[_minValueTextField setFormatter:[[_numberInputViewController formatter] copy]];
	[_maxValueTextField setFormatter:[[_numberInputViewController formatter] copy]];
	
	[self addObserver:self forKeyPath:@"sliderValue" options:0 context:&MGSSliderValueContext];
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
	
	self.incrementValue = [[self.plist objectForKey:MGSKeyNumberIncrementValue withDefault:[NSNumber numberWithDouble:1]] doubleValue];
	self.notation = [[self.plist objectForKey:MGSKeyNumberStyle withDefault:[NSNumber numberWithInteger:kMGSNumberInputViewDecimalNotation]] integerValue];
	self.decimalPlaces = [[self.plist objectForKey:MGSKeyNumberDecimalPlaces withDefault:[NSNumber numberWithInteger:2]] integerValue];

	if ([self.plist objectForKey:MGSKeyNumberRequireInteger]) {
		BOOL wholeNumber = [[self.plist objectForKey:MGSKeyNumberRequireInteger withDefault:[NSNumber numberWithBool:YES]] boolValue];
		self.decimalPlaces = wholeNumber ? 0 : 2;
	}
	
	NSString *fmt = NSLocalizedString(@"A value between %@ and %@", @"label text");
	self.label = [NSString stringWithFormat:fmt, [_minValueTextField stringValue], [_maxValueTextField stringValue]];
	
	[_valueSlider setAltIncrementValue:self.incrementValue];
}

/*
 
 - setParameterValue:
 
 */
- (void)setParameterValue:(id)value
{
    if ([self validateParameterValue:value]) {
        [super setParameterValue:value];
        if (_updateSliderValue) {
            self.sliderValue = [[self parameterValue] doubleValue];
        }
    }
}

/*
 
 - validateParameterValue:
 
 */
- (BOOL)validateParameterValue:(id)newValue
{
#pragma unused(newValue)
    
    BOOL isValid = NO;
    
    if ([newValue isKindOfClass:[NSNumber class]]) {
        double numberValue = [(NSNumber *)newValue doubleValue];
        if (numberValue >= self.minValue && numberValue <= self.maxValue) {
            isValid = YES;
        }
    }
    
    return isValid;
}

/*
 
 KVO 
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &MGSSliderValueContext) {
		NSString *stringValue = [_numberInputViewController.formatter stringFromNumber:[NSNumber numberWithDouble:self.sliderValue]];
		NSNumber *number = [_numberInputViewController.formatter numberFromString:stringValue];
		_updateSliderValue = NO;
		self.parameterValue = number;	
		_updateSliderValue = YES;

	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}
@end
