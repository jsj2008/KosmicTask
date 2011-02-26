//
//  MGSParameterPluginInputViewController.m
//  Mother
//
//  Created by Jonathan on 02/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSParameterViewController.h"
#import "MGSParameterPluginInputViewController.h"
#import "MGSParameterPluginViewController.h"
#import "MGSKeyValueBinding.h"

const char MGSContextResetEnabled;

@implementation MGSParameterPluginInputViewController

@synthesize pluginView;
@synthesize parameterPluginViewController = _parameterPluginViewController;
@synthesize resetEnabled = _resetEnabled;
@synthesize delegate;

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
	
	[_parameterPluginViewController resetToDefaultValue];
	
	// set model data modified is called automatically
	// when the model is changed by bound inputs.
	// in this case we need to do it manually.
	[_parameterPluginViewController setModelDataModified:YES];
}


/*
 
 set parameter subview controller
 
 */
- (void)setParameterPluginViewController:(MGSParameterPluginViewController *)newValue
{
	_parameterPluginViewController = newValue;
	
	// bind reset button enabled state to subviewController default selected
	[resetButton bind:NSEnabledBinding 
			 toObject:_parameterPluginViewController 
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

/*
 
 - pluginViewWantsNewSize:
 
 */
- (void)pluginViewWantsNewSize:(NSSize)newSize
{
	/*
	 
	 the plugin view wants a new size.
	 
	 self.view will be vertically autosized by its superview.
	 
	 */
	CGFloat deltaY = newSize.height - _parameterPluginViewController.view.frame.size.height;
	NSSize size = self.view.frame.size;
	size.height += deltaY;
	if (delegate && [delegate respondsToSelector:@selector(subview:wantsNewSize:)]) {
		[delegate subview:self.view wantsNewSize:size];
	}
}

@end
