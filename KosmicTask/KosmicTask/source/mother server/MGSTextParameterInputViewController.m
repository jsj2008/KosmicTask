//
//  MGSTextParameterInputViewController.m
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSTextParameterInputViewController.h"

@implementation MGSTextParameterInputViewController

@synthesize allowEmptyInput = _allowEmptyInput;
@synthesize inputStyle;

/*
 
 init  
 
 */
- (id)init
{
	self = [super initWithNibName:@"TextParameterInputView"];
	if (self) {
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
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	
	/*
	 
	 when the nib is loaded this may be called with self.plist == nil;
	 
	 */
	self.allowEmptyInput = [[self.plist objectForKey:MGSKeyAllowEmptyInput withDefault:[NSNumber numberWithBool:NSOffState]] boolValue];
	self.inputStyle = [[self.plist objectForKey:MGSKeyInputStyle withDefault:[NSNumber numberWithInteger:kMGSParameterInputStyleMultiLine]] integerValue];

	if (self.allowEmptyInput) {
		self.label = NSLocalizedString(@"Input is optional", @"label text");
	} else {
		self.label = NSLocalizedString(@"Input is required", @"label text");
	}
	
	NSView *textControlView = nil;
	NSView *subView = nil;
	switch (self.inputStyle) {
		case kMGSParameterInputStyleMultiLine:
			textControlView = textView;
			subView = multiLineView;
			break;
			
		case kMGSTextParameterInputStyleSingleLine:
			textControlView = textField;
			subView = singleLineView;
			break;
			
		default:
			NSAssert(NO, @"invalid input style");
			break;
	}
	
	[textControlView bind:NSValueBinding toObject:self withKeyPath:@"parameterValue" options:nil];
	
	/*
	 
	 update subview within parameter view
	 
	 */
	//if (self.plist) {
		BOOL resize = self.plist ? YES : NO;
		[self updateSubview:subView resize:resize];
	//}
}

/*
 
 can drag height override
 
 */
- (BOOL)canDragHeight
{
	switch (self.inputStyle) {
		case kMGSParameterInputStyleMultiLine:
			return YES;
			break;
			
		case kMGSTextParameterInputStyleSingleLine:
			break;
			
		default:
			NSAssert(NO, @"invalid input style");
			break;
	}
	
	return NO;
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
