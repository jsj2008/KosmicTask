//
//  MGSTextParameterPlugin.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSTextParameterPlugin.h"
#import "MGSTextParameterEditViewController.h"
#import "MGSTextParameterInputViewController.h"


NSString *MGSKeyAllowEmptyInput = @"AllowEmptyInput";

@implementation MGSTextParameterPlugin

/*
 
 create edit view controller with delegate
 
 */
-(MGSParameterSubEditViewController *)createEditViewControllerWithDelegate:(id)aDelegate
{
	#pragma unused(aDelegate)
	
	return [self createViewController:[MGSTextParameterEditViewController class]];
}


/*
 
 create input view controller with delegate
 
 */
- (MGSParameterSubInputViewController *)createInputViewControllerWithDelegate:(id)aDelegate
{
	#pragma unused(aDelegate)
	
	return [self createViewController:[MGSTextParameterInputViewController class]];
}

/*
 
 is default
 
 */
- (BOOL)isDefault
{
	return YES;
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Text", @"Parameter plugin menu item string");
}

@end
