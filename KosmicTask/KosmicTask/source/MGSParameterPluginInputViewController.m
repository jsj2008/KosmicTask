//
//  MGSParameterPluginInputViewController.m
//  Mother
//
//  Created by Jonathan on 02/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterPluginInputViewController.h"
#import "MGSParameterSubViewController.h"
#import "MGSKeyValueBinding.h"

const char MGSContextResetEnabled;

@implementation MGSParameterPluginInputViewController

@synthesize pluginView;
@synthesize subViewController = _subViewController;
@synthesize resetEnabled = _resetEnabled;

/*
 
 init  
 
 */
-(id)init
{
	if ([super initWithNibName:@"ParameterPluginInputView" bundle:nil]) {
	}
	return self;
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{

}

/*
 
 reset parameter to default value
 
 */
- (IBAction)resetToDefaultValue:(id)sender
{
	#pragma unused(sender)
	
	//[resetButton setEnabled:NO];
	
	[_subViewController resetToDefaultValue];
	
	// set model data modified is called automatically
	// when the model is changed by bound inputs.
	// in this case we need to do it manually.
	[_subViewController setModelDataModified:YES];
}


/*
 
 set parameter subview controller
 
 */
- (void)setSubViewController:(MGSParameterSubViewController *)newValue
{
	_subViewController = newValue;
	
	// bind reset button enabled state to subviewController default selected
	[resetButton bind:NSEnabledBinding 
			 toObject:_subViewController 
		  withKeyPath:@"defaultValueSelected" 
			  options:[NSDictionary dictionaryWithObjectsAndKeys: NSNegateBooleanTransformerName,NSValueTransformerNameBindingOption, nil]];

	// observe reset button enabled state
	[resetButton addObserver:self forKeyPath:@"enabled" 
				options:NSKeyValueObservingOptionNew context:(void *)&MGSContextResetEnabled];
}

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(change)
	
	if (context == &MGSContextResetEnabled) {
		[self willChangeValueForKey:@"resetEnabled"];
		_resetEnabled = [resetButton isEnabled];
		[self didChangeValueForKey:@"resetEnabled"];
	}
}

@end
