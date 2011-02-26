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
 
 - editViewControllerClass
 
 */
- (id)editViewControllerClass
{
	return [MGSDateParameterEditViewController class];
}


/*
 
 - inputViewControllerClass
 
 */
- (id)inputViewControllerClass
{
	return [MGSDateParameterInputViewController class];
}


/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Date", @"Parameter plugin menu item string");
}

@end
