//
//  MGSParameterPluginController.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterPluginController.h"
#import "MGSParameterPlugin.h"
#import "NSBundle_Mugginsoft.h"

#define DEFAULT_PLUGIN @"MGSTextParameterPlugin"

@implementation MGSParameterPluginController

/*
 
 + plugInClass
 
 */
+ (Class)plugInClass
{
	return [MGSParameterPlugin class];
}

/*
 
 default plugin name
 
 */
- (NSString *)defaultPluginName
{
	// get default parameter plugin class from info.plist
	 NSString *pluginName = [NSBundle mainBundleInfoObjectForKey:MGSParameterPluginDefaultClassName];
	
	return pluginName;
}
@end
