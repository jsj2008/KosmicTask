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
 
 - editViewControllerClass
 
 */
- (id)editViewControllerClass
{
	return [MGSListParameterEditViewController class];
}


/*
 
 - inputViewControllerClass
 
 */
- (id)inputViewControllerClass
{
	return [MGSListParameterInputViewController class];
}


/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"List Item", @"Parameter plugin menu item string");
}

@end
