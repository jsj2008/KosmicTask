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
 
 - editViewControllerClass
 
 */
- (id)editViewControllerClass
{
	return [MGSFileParameterEditViewController class];
}


/*
 
 - inputViewControllerClass
 
 */
- (id)inputViewControllerClass
{
	return [MGSFileParameterInputViewController class];
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"File Contents", @"Parameter plugin menu item string");
}

@end
