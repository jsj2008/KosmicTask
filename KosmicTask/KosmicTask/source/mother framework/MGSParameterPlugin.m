//
//  MGSParameterPlugin.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterPlugin.h"
#import "MGSParameterSubViewController.h"

NSString *MGSParameterPluginDefaultClassName = @"MGSDefaultParameterPluginClassName";

@implementation MGSParameterPlugin

/*
 
 create view controller
 
 */
- (id)createViewController:(Class)controllerClass
{
	MGSParameterSubViewController *viewController = nil;
	
	// if class is a subclass of our view controller super class then allocate it
	if ([controllerClass isSubclassOfClass:[MGSParameterSubViewController class]]) {
		viewController = [[controllerClass alloc] init];
		viewController.plugin = self;
	}
	
	return viewController;
}
@end
