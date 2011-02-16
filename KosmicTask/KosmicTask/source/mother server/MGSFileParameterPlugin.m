//
//  MGSFileParameterPlugin.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSFileParameterPlugin.h"
#import "MGSFileParameterEditViewController.h"
#import "MGSFileParameterInputViewController.h"


NSString *MGSKeyUseFileExtensions = @"UseFileExtensions";
NSString *MGSKeyFileExtensions = @"FileExtensions";

@implementation MGSFileParameterPlugin

/*
 
 create edit view controller with delegate
 
 */
- (MGSParameterSubEditViewController *)createEditViewControllerWithDelegate:(id)aDelegate
{
	#pragma unused(aDelegate)
	
	return [self createViewController:[MGSFileParameterEditViewController class]];
}

/*
 
 create input view controller with delegate
 
 */
- (MGSParameterSubInputViewController *)createInputViewControllerWithDelegate:(id)aDelegate
{
	#pragma unused(aDelegate)
	
	return [self createViewController:[MGSFileParameterInputViewController class]];
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"File Contents", @"Parameter plugin menu item string");
}

@end
