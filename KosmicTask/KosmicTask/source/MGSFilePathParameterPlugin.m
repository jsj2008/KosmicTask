//
//  MGSFilePathParameterPlugin.m
//  KosmicTask
//
//  Created by Jonathan on 02/04/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSFilePathParameterPlugin.h"

#import "MGSFileParameterEditViewController.h"
#import "MGSFileParameterInputViewController.h"
#import "MGSFilePathParameterInputViewController.h"

@implementation MGSFilePathParameterPlugin

/*
 
 - editViewControllerClass
 
 */
- (id)editViewControllerClass
{
	return [MGSFilePathParameterEditViewController class];
}


/*
 
 - inputViewControllerClass
 
 */
- (id)inputViewControllerClass
{
	return [MGSFilePathParameterInputViewController class];
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"File Path", @"Parameter plugin menu item string");
}

@end
