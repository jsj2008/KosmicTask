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
#import "MGSKeyValueBinding.h"
#import "MGSNumberParameterPlugin.h"

NSString *MGSInitialValueContext = @"InitialValue";
NSString *MGSMinValueContext = @"MinValue";
NSString *MGSMaxValueContext = @"MaxValue";
NSString *MGSIncrementValueContext = @"IncrementValue";

@implementation MGSNumberParameterEditViewController

@synthesize initialValue = _initialValue;
@synthesize minValue = _minValue;
@synthesize maxValue = _maxValue;
@synthesize incrementValue = _incrementValue;
@synthesize representationMax = _representationMax;
@synthesize representationMin = _representationMin;
@synthesize minIncrement = _minIncrement;
@synthesize maxIncrement = _maxIncrement;
@synthesize notation = _notation;
@synthesize decimalPlaces = _decimalPlaces;

/*
 
 init  
 
 */
- (id)init
{
	if ([super initWithNibName:@"NumberParameterEditView"]) {
		_notation = kMGSNumberInputViewDecimalNotation;
		_decimalPlaces = 0;
		_representationMax = DBL_MAX;
		_representationMin = -DBL_MAX;
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
	
	[stylePopupButton bind:NSSelectedTagBinding toObject:self withKeyPath:@"notation" options:nil];
	[decimalPlacesPopupButton bind:NSSelectedIndexBinding toObject:self withKeyPath:@"decimalPlaces" options:nil];
	
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
	[_initialValueInput bind:NSMinValueBinding toObject:self withKeyPath:@"minValue" options:nil];
	[_initialValueInput bind:NSMaxValueBinding toObject:self withKeyPath:@"maxValue" options:nil];
	[_initialValueInput bind:MGSNotationBinding toObject:self withKeyPath:@"notation" options:nil];
	[_initialValueInput bind:MGSDecimalPlacesBinding toObject:self withKeyPath:@"decimalPlaces" options:nil];

	[_minValueInput bind:@"value" toObject:self withKeyPath:@"minValue" options:nil];
    [_minValueInput bind:NSMaxValueBinding toObject:self withKeyPath:@"maxValue" options:nil];
    [_minValueInput bind:NSMinValueBinding toObject:self withKeyPath:@"representationMin" options:nil];
	[_minValueInput bind:MGSNotationBinding toObject:self withKeyPath:@"notation" options:nil];
	[_minValueInput bind:MGSDecimalPlacesBinding toObject:self withKeyPath:@"decimalPlaces" options:nil];
	
	[_maxValueInput bind:@"value" toObject:self withKeyPath:@"maxValue" options:nil];
    [_maxValueInput bind:NSMinValueBinding toObject:self withKeyPath:@"minValue" options:nil];
    [_maxValueInput bind:NSMaxValueBinding toObject:self withKeyPath:@"representationMax" options:nil];
	[_maxValueInput bind:MGSNotationBinding toObject:self withKeyPath:@"notation" options:nil];
	[_maxValueInput bind:MGSDecimalPlacesBinding toObject:self withKeyPath:@"decimalPlaces" options:nil];
	
	[_incrementValueInput bind:@"value" toObject:self withKeyPath:@"incrementValue" options:nil];
	[_incrementValueInput bind:NSMinValueBinding toObject:self withKeyPath:@"minIncrement" options:nil];
    [_incrementValueInput bind:NSMaxValueBinding toObject:self withKeyPath:@"maxIncrement" options:nil];
	[_incrementValueInput bind:MGSNotationBinding toObject:self withKeyPath:@"notation" options:nil];
	[_incrementValueInput bind:MGSDecimalPlacesBinding toObject:self withKeyPath:@"decimalPlaces" options:nil];
	
	[self addObserver:self forKeyPath:@"minValue" options:0 context:MGSMinValueContext];
	[self addObserver:self forKeyPath:@"maxValue" options:0 context:MGSMaxValueContext];
	
}

/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
	
	if (context == MGSMinValueContext || context == MGSMaxValueContext ) {
		if (self.initialValue < self.minValue) {
			self.initialValue = self.minValue;
		}
		if (self.initialValue > self.maxValue) {
			self.initialValue = self.maxValue;
		}
		
		self.maxIncrement =  self.maxValue - self.minValue;
		if (self.incrementValue > self.maxIncrement) {
			self.incrementValue = self.maxIncrement;
		}
	}
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
	[self.plist setObject:[NSNumber numberWithInteger:self.notation] forKey:MGSKeyNumberStyle];
	[self.plist setObject:[NSNumber numberWithInteger:self.decimalPlaces] forKey:MGSKeyNumberDecimalPlaces];
	
	// we no longer require to persist the following keys
	if (NO) {
		//[self.plist setObject:[NSNumber numberWithBool:self.wholeNumber] forKey:MGSKeyNumberRequireInteger];
	}
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	NSLog(@"plist = %@", self.plist);
	self.minIncrement = 0;
	self.minValue = [[self.plist objectForKey:MGSKeyNumberMinValue withDefault:[NSNumber numberWithDouble:0]] doubleValue];
	self.maxValue = [[self.plist objectForKey:MGSKeyNumberMaxValue withDefault:[NSNumber numberWithDouble:10]] doubleValue];
	self.incrementValue = [[self.plist objectForKey:MGSKeyNumberIncrementValue withDefault:[NSNumber numberWithDouble:1]] doubleValue];
	self.initialValue =  [[self.plist objectForKey:MGSScriptKeyDefault withDefault:[NSNumber numberWithDouble:1]] doubleValue];
	self.notation = [[self.plist objectForKey:MGSKeyNumberStyle withDefault:[NSNumber numberWithInteger:kMGSNumberInputViewDecimalNotation]] integerValue];
	self.decimalPlaces = [[self.plist objectForKey:MGSKeyNumberDecimalPlaces withDefault:[NSNumber numberWithInteger:0]] integerValue];
	
	// wholenumber key may be present in older scripts
	if ([self.plist objectForKey:MGSKeyNumberRequireInteger]) {
		BOOL wholeNumber = [[self.plist objectForKey:MGSKeyNumberRequireInteger withDefault:[NSNumber numberWithBool:YES]] boolValue];
		self.decimalPlaces = wholeNumber ? 0 : 2;
	}
}

@end
