//
//  MGSExportPluginController.m
//  Mother
//
//  Created by Jonathan on 19/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSExportPluginController.h"
#import "MGSExportPlugin.h"

@implementation MGSExportPluginController

/*
 
 + plugInClass
 
 */
+ (Class)plugInClass
{
	return [MGSExportPlugin class];
}

@end
