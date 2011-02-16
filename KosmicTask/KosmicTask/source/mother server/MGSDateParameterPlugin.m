//
//  MGSDateParameterPlugin.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSDateParameterPlugin.h"
#import "MGSDateParameterEditViewController.h"
#import "MGSDateParameterInputViewController.h"

NSString *MGSKeyInitialiseToCurrentDate = @"InitialiseToCurrent";

@implementation MGSDateParameterPlugin

/*
 
 create edit view controller with delegate
 
 */
-(MGSParameterSubEditViewController *)createEditViewControllerWithDelegate:(id)aDelegate
{
	#pragma unused(aDelegate)
	
	return [self createViewController:[MGSDateParameterEditViewController class]];
}

/*
 
 create input view controller with delegate
 
 */
- (MGSParameterSubInputViewController *)createInputViewControllerWithDelegate:(id)aDelegate
{
	#pragma unused(aDelegate)
	
	return [self createViewController:[MGSDateParameterInputViewController class]];
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Date", @"Parameter plugin menu item string");
}

@end
