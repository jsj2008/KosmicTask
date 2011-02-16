//
//  MGSTextParameterEditViewController.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSTextParameterPlugin.h"
#import "MGSTextParameterEditViewController.h"

@implementation MGSTextParameterEditViewController

@synthesize defaultText = _defaultText;
@synthesize allowEmptyInput = _allowEmptyInput;

/*
 
 init
 
 */
- (id)init
{
	if ([super initWithNibName:@"TextParameterEditView"]) {
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
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	self.defaultText = [self.plist objectForKey:MGSScriptKeyDefault withDefault:@""];
	self.allowEmptyInput = [[self.plist objectForKey:MGSKeyAllowEmptyInput withDefault:[NSNumber numberWithBool:NSOffState]] boolValue];
}

@end
