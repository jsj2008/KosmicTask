//
//  MGSTextParameterEditViewController.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSTextParameterEditViewController.h"

@implementation MGSTextParameterEditViewController

@synthesize defaultText = _defaultText;
@synthesize allowEmptyInput = _allowEmptyInput;
@synthesize inputStyle;

/*
 
 init
 
 */
- (id)init
{
	self = [super initWithNibName:@"TextParameterEditView"];
	if (self) {
		inputStyle = kMGSParameterInputStyleMultiLine;
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
	[textView bind:NSValueBinding toObject:self withKeyPath:@"defaultText" options:nil];
	[allowEmptyInputCheckbox bind:NSValueBinding toObject:self withKeyPath:@"allowEmptyInput" options:nil];
	[initialInputSizePopUpButton bind:NSSelectedIndexBinding toObject:self withKeyPath:@"inputStyle" options:nil];
}


/*
 
 can drag middle view
 
 */
- (BOOL)canDragMiddleView
{
	return YES;
}


/*
 
 update plist
 
 */
- (void)updatePlist
{
	[self setDefaultValue:self.defaultText];
	[self.plist setObject:[NSNumber numberWithBool:self.allowEmptyInput] forKey:MGSKeyAllowEmptyInput];
	[self.plist setObject:[NSNumber numberWithInteger:self.inputStyle] forKey:MGSKeyInputStyle];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	self.defaultText = [self.plist objectForKey:MGSScriptKeyDefault withDefault:@""];
	self.allowEmptyInput = [[self.plist objectForKey:MGSKeyAllowEmptyInput withDefault:[NSNumber numberWithBool:NSOffState]] boolValue];
	self.inputStyle = [[self.plist objectForKey:MGSKeyInputStyle withDefault:[NSNumber numberWithInteger:kMGSParameterInputStyleMultiLine]] integerValue];
}

@end
