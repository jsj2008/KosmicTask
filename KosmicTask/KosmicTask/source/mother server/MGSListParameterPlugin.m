//
//  MGSListParameterPlugin.m
//  Mother
//
//  Created by Jonathan on 08/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSListParameterPlugin.h"
#import "MGSListParameterEditViewController.h"
#import "MGSListParameterInputViewController.h"

NSString *MGSKeyList = @"List";
NSString *MGSSelectedObjectsContext = @"SelectedObjects";
NSString *MGSArrangedObjectsContext = @"ArrangedObjects";

@implementation MGSListParameterPlugin
/*
 
 create edit view controller with delegate
 
 */
- (MGSParameterSubEditViewController *)createEditViewControllerWithDelegate:(id)aDelegate
{
	#pragma unused(aDelegate)
	
	return [self createViewController:[MGSListParameterEditViewController class]];
}

/*
 
 create input view controller with delegate
 
 */
- (MGSParameterSubInputViewController *)createInputViewControllerWithDelegate:(id)aDelegate
{
	#pragma unused(aDelegate)
	
	return [self createViewController:[MGSListParameterInputViewController class]];
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"List Item", @"Parameter plugin menu item string");
}

@end
