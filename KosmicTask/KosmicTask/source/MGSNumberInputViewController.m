//
//  MGSNumberInputViewController.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSNumberInputViewController.h"
#import "NSSplitView_Mugginsoft.h"
#import "MGSIntegerTransformer.h"
#import "MGSKeyValueBinding.h"

const char MGSValueBindingContext;
const char MGSIncrementValueBindingContext;

@implementation MGSNumberInputViewController

@synthesize value = _value;
@synthesize increment = _increment;
@synthesize minValue = _minValue;
@synthesize maxValue = _maxValue;
@synthesize textField;
@synthesize stepper;
@synthesize integralValue = _integralValue;

/*
 
 init with delegate
 
 */
- (id)init
{
	if ([super initWithNibName:@"NumberInputView" bundle:[NSBundle bundleForClass:[self class]]]) {
		//[super setDelegate:delegate];
		self.value = 0.0;
		self.increment = 1.0;
		self.minValue = -DBL_MAX;
		self.maxValue = DBL_MAX;
		self.integralValue = YES;
		
		_updateObservedObject = YES;
		_bindings = [NSMutableDictionary dictionaryWithCapacity:5];
	}
	return self;
}



/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	// There doesn't seem to be an easy way to bind the stepper and get it to call -commitEditing on the
	// view controller (without this the textField binding is not updated correctly).
	// To avoid this problem continuously update the binding.
	[textField bind:NSValueBinding toObject:self withKeyPath:@"value" options:
		[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], 
		 NSContinuouslyUpdatesValueBindingOption, [NSNumber numberWithBool:YES], NSValidatesImmediatelyBindingOption, nil]];
	
	// note: no increment binding for stepper
	[stepper bind:NSValueBinding toObject:self withKeyPath:@"value" options:nil];
	[stepper bind:NSMinValueBinding toObject:self withKeyPath:@"minValue" options:nil];
	[stepper bind:NSMaxValueBinding toObject:self withKeyPath:@"maxValue" options:nil];
}


/*
 
 set increment
 
 */

- (void)setIncrement:(double)increment
{
	_increment = increment;
	[stepper setIncrement:_increment];
	
	// get value binding
	NSDictionary *binding = [_bindings objectForKey:MGSIncrementValueBinding];
	
	// inform observed object that value has changed
	if (binding && _updateObservedObject) {
		[[binding objectForKey:MGSObservableObject] setValue:[NSNumber numberWithDouble:_value] forKeyPath:[binding objectForKey:MGSObservableKeyPath]];
	}
}

/*
 
 splitview constrain min position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	#pragma unused(sender)
	#pragma unused(proposedMin)
	
	switch (offset) {
		case 0:
			return 20;
			break;
			
		default:
			NSAssert(NO, @"invalid subview offset");
	}
	
	return 0;
}	

/*
 
 splitview constrain max position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	#pragma unused(proposedMax)
	
	switch (offset) {
		case 0:
			return [sender frame].size.width - 25;
			break;
			
		default:
			NSAssert(NO, @"invalid subview offset");
	}
	
	return 0;
}	

/*
 
 size splitview subviews as required
 
 */
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{	
	MGSSplitviewBehaviour behaviour;
	
	// note that a view does not provide a -setTag method only -tag
	// so views cannot be easily tagged without subclassing.
	// NSControl implements -setTag;
	//
	switch ([[sender subviews] count]) {
		case 2:
			behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;
			break;
			
		case 3:
			behaviour = MGSSplitviewBehaviourOf3ViewsFirstAndSecondFixed;
			break;
			
		default:
			NSAssert(NO, @"invalid number of views in splitview");
			return;
	}

	// see the NSSplitView_Mugginsoft category
	NSArray *minSizes = [NSArray arrayWithObjects:[NSNumber numberWithDouble:30], [NSNumber numberWithDouble:25 - [sender dividerThickness]], nil];
	[sender resizeSubviewsWithOldSize:oldSize withBehaviour:behaviour minSizes:minSizes];
}

/*
 
 number value
 
 */
- (NSNumber *)numberValue
{
	return [NSNumber numberWithDouble:self.value];
}

/*
 
 set number value
 
 */
- (void)setNumberValue:(NSNumber *)number
{
	// discard nil values
	if (!number) return;
	if (![number isKindOfClass:[NSNumber class]]) return;
	
	self.value = [number doubleValue];
}


/*
 
 bind to object with key path
 
 perhaps the default implementation would have served here just as well
 
 */
- (void)bind:(NSString *)binding
	toObject:(id)observableObject
 withKeyPath:(NSString *)keyPath
	 options:(NSDictionary *)options
{
	#pragma unused(options)
	
	// Observe the observableObject for changes -- note, pass binding identifier
	// as the context, so you get that back in observeValueForKeyPath:...
	// This way you can easily determine what needs to be updated.
	void *context = NULL;
	if ([binding isEqualToString:NSValueBinding]) {
		context = NSValueBinding;
	} else if ([binding isEqualToString:MGSIncrementValueBinding]) {
		context = MGSIncrementValueBinding;
	} else if ([binding isEqualToString:NSMinValueBinding]) {
		context = NSMinValueBinding;
	} else if ([binding isEqualToString:NSMaxValueBinding]) {
		context = NSMaxValueBinding;
	} else if ([binding isEqualToString:MGSIntegralValueBinding]) {
		context = MGSIntegralValueBinding;
	} else {
		return;
	}
	
	// retain observed object and keypath
	[_bindings setObject:[NSDictionary dictionaryWithObjectsAndKeys:
						  observableObject, MGSObservableObject,
						  keyPath, MGSObservableKeyPath,
						  nil] forKey:binding];
	
	// start observing
	[observableObject addObserver:self
					   forKeyPath:keyPath
						  options:0
						  context:context];
}

/*
 
 set nil value for key
 
 */
- (void)setNilValueForKey:(NSString *)key
{
	// sent when delete number
	if ([key isEqualToString:@"value"]) {
		self.value = self.minValue;
	}
}

/*
 
 set value
 
 */
- (void)setValue:(double)newValue
{
	_value = newValue;
	
	// get value binding
	NSDictionary *binding = [_bindings objectForKey:NSValueBinding];
	
	// inform observed object that value has changed
	if (binding && _updateObservedObject) {
		[[binding objectForKey:MGSObservableObject] setValue:[NSNumber numberWithDouble:_value] forKeyPath:[binding objectForKey:MGSObservableKeyPath]];
	}
}

/*
 
 set min value
 
 */
- (void)setMinValue:(double)newValue
{
	_minValue = newValue;
	[[[textField cell] formatter] setMinimum:[NSNumber numberWithDouble:newValue]];
	
	// get value binding
	NSDictionary *binding = [_bindings objectForKey:NSMinValueBinding];
	
	// inform observed object that value has changed
	if (binding && _updateObservedObject) {
		[[binding objectForKey:MGSObservableObject] setValue:[NSNumber numberWithDouble:_minValue] forKeyPath:[binding objectForKey:MGSObservableKeyPath]];
	}
}

/*
 
 set max value
 
 */
- (void)setMaxValue:(double)newValue
{
	_maxValue = newValue;
	[[[textField cell] formatter] setMaximum:[NSNumber numberWithDouble:newValue]];
	
	// get value binding
	NSDictionary *binding = [_bindings objectForKey:NSMaxValueBinding];
	
	// inform observed object that value has changed
	if (binding && _updateObservedObject) {
		[[binding objectForKey:MGSObservableObject] setValue:[NSNumber numberWithDouble:_maxValue] forKeyPath:[binding objectForKey:MGSObservableKeyPath]];
	}
}

/*
 
 set integral value
 
 */
- (void)setIntegralValue:(BOOL)aBool
{
	_integralValue = aBool;
	
	if (_integralValue) {
		// transformer doesn't seem necessary. formatter seems enough.
		/*MGSIntegerTransformer *integerTransformer = [[MGSIntegerTransformer alloc] init];
		[textField unbind:NSValueBinding];
		[textField bind:NSValueBinding toObject:self withKeyPath:@"value" options:
		 [NSDictionary dictionaryWithObjectsAndKeys:
		  [NSNumber numberWithBool:YES], NSContinuouslyUpdatesValueBindingOption, 
		  [NSNumber numberWithBool:YES], NSValidatesImmediatelyBindingOption, 
		  integerTransformer, NSValueTransformerBindingOption,
		  nil]];*/
	} else {
	}
	
	[[[textField cell] formatter] setMaximumFractionDigits:_integralValue ? 0 : 3];
	
	// get value binding
	NSDictionary *binding = [_bindings objectForKey:MGSIntegralValueBinding];
	
	// inform observed object that value has changed
	if (binding && _updateObservedObject) {
		[[binding objectForKey:MGSObservableObject] setValue:[NSNumber numberWithBool:_integralValue] forKeyPath:[binding objectForKey:MGSObservableKeyPath]];
	}
}


/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(change)
	
	BOOL validSelectionForValue = YES;
	NSDictionary *binding = nil;
	NSString *keySelf = nil;
	id newValue = nil;
	
	// if our model has been updated then update ourself
    if (context == NSValueBinding){
		keySelf = @"value";
		binding = [_bindings objectForKey:context];
        newValue = [[binding objectForKey:MGSObservableObject]
					   valueForKeyPath:[binding objectForKey:MGSObservableKeyPath]];
        if ((newValue == NSNoSelectionMarker) ||
            (newValue == NSNotApplicableMarker) ||
            (newValue == NSMultipleValuesMarker))
        {
            validSelectionForValue = NO;
        }
	} else if (context == MGSIncrementValueBinding) {
		keySelf = @"increment";
	} else if (context == MGSIntegralValueBinding) {
		keySelf = @"integralValue";
	} else if (context == NSMinValueBinding) {
		keySelf = @"minValue";
	} else if (context == NSMaxValueBinding) {
		keySelf = @"maxValue";
    } else {
		return;
	}

	if (!binding) {
		binding = [_bindings objectForKey:context];
		newValue = [[binding objectForKey:MGSObservableObject]
				valueForKeyPath:[binding objectForKey:MGSObservableKeyPath]];
	}
	
	if (validSelectionForValue) {	
		// don't want to update our observed object in this case
		_updateObservedObject = NO;
		[self setValue:newValue forKey:keySelf];
		_updateObservedObject = YES;
	}
	
}
/*
 
 finalize
 
 */
- (void)finalize
{
	// unbind
	@try {
		for (NSString *key in [_bindings allKeys]) {
			NSDictionary *binding = [_bindings objectForKey:key];
			[[binding objectForKey:MGSObservableObject] removeObserver:self forKeyPath:[binding objectForKey:MGSObservableKeyPath]];
		}
	} 
	@catch (NSException *e) {
		MLog(RELEASELOG, @"%@", [e reason]);
	}
	
	[super finalize];
}
@end
