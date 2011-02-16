//
//  MGSTextParameterInputViewController.m
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSTextParameterPlugin.h"
#import "MGSTextParameterInputViewController.h"

@implementation MGSTextParameterInputViewController

@synthesize allowEmptyInput = _allowEmptyInput;

/*
 
 init  
 
 */
- (id)init
{
	if ([super initWithNibName:@"TextParameterInputView"]) {
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
	[textView bind:NSValueBinding toObject:self withKeyPath:@"parameterValue" options:nil];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	self.allowEmptyInput = [[self.plist objectForKey:MGSKeyAllowEmptyInput withDefault:[NSNumber numberWithBool:NSOffState]] boolValue];
}

/*
 
 can drag height override
 
 */
- (BOOL)canDragHeight
{
	return YES;
}

/*
 
 parameter value
 
 */
- (NSString *)parameterValue
 {
	 NSString *value = [super parameterValue];
	 
	 // if clear all text from NSTextView then value can be nil
	 if (!value) {
		 value = @"";
	 }
	 
	 return value;
 }
 
/*
 
 is valid
 
 */
- (BOOL)isValid
{
	NSString *stringValue = self.parameterValue;
	if (!stringValue) {
		stringValue = @"";
	} else {
		stringValue = [stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	
	// parameter value must be defined
	if ([stringValue length] == 0 && !self.allowEmptyInput) {
		self.validationString = NSLocalizedString(@"Please enter valid text.", @"Validation string - no text available");
		return NO;
	}
		
	return YES;
}


@end
