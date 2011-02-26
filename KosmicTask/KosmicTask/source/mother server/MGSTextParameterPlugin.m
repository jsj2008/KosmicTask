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
NSString *MGSKeyInputStyle = @"InputStyle";


@implementation MGSTextParameterPlugin

/*
 
 - editViewControllerClass
 
 */
- (id)editViewControllerClass
{
	return [MGSTextParameterEditViewController class];
}


/*
 
 - inputViewControllerClass
 
 */
- (id)inputViewControllerClass
{
	return [MGSTextParameterInputViewController class];
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
