//
//  MGSParameterPlugin.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterPlugin.h"
#import "MGSParameterPluginViewController.h"

NSString *MGSParameterPluginDefaultClassName = @"MGSDefaultParameterPluginClassName";

@implementation MGSParameterPlugin

/*
 
 create view controller
 
 */
- (id)createViewController:(Class)controllerClass delegate:(id)delegate
{
	MGSParameterPluginViewController *viewController = nil;
	
	// if class is a subclass of our view controller super class then allocate it
	if ([controllerClass isSubclassOfClass:[MGSParameterPluginViewController class]]) {
		viewController = [[controllerClass alloc] init];
		viewController.plugin = self;
		viewController.delegate = delegate;
	}
	
	return viewController;
}

/*
 
 - editViewControllerClass
 
 */
- (id)editViewControllerClass
{
	NSAssert(NO, @"subclasses must override");
	
	return nil;
}

/*
 
 - inputViewControllerClass
 
 */
- (id)inputViewControllerClass
{
	NSAssert(NO, @"subclasses must override");
	
	
	return nil;
}
@end
