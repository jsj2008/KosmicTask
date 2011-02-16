//
//  MGSNumberParameterPlugin.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSNumberParameterPlugin.h"
#import "MGSNumberParameterEditViewController.h"
#import "MGSNumberParameterInputViewController.h"

NSString *MGSKeyNumberMinValue = @"MinValue";
NSString *MGSKeyNumberMaxValue = @"MaxValue";
NSString *MGSKeyNumberIncrementValue = @"IncrementValue";
NSString *MGSKeyNumberRequireInteger = @"RequireInteger";

@implementation MGSNumberParameterPlugin

/*
 
 create edit view controller with delegate
 
 */
-(MGSParameterSubEditViewController *)createEditViewControllerWithDelegate:(id)aDelegate
{
	#pragma unused(aDelegate)
	
	return [self createViewController:[MGSNumberParameterEditViewController class]];
}

/*
 
 create input view controller with delegate
 
 */
- (MGSParameterSubInputViewController *)createInputViewControllerWithDelegate:(id)aDelegate
{
	#pragma unused(aDelegate)
	
	return [self createViewController:[MGSNumberParameterInputViewController class]];
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Number", @"Parameter plugin menu item string");
}


@end
