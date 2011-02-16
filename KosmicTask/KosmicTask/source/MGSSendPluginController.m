//
//  MGSSendPluginController.m
//  Mother
//
//  Created by Jonathan on 21/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSSendPluginController.h"
#import "MGSSendPlugin.h"

@implementation MGSSendPluginController

/*
 
 + plugInClass
 
 */
+ (Class)plugInClass
{
	return [MGSSendPlugin class];
}

@end
