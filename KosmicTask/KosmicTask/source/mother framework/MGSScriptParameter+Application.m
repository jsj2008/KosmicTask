//
//  MGSScriptParameter+Application.m
//  KosmicTask
//
//  Created by Jonathan Mitchell on 26/01/2014.
//
//

#import "MGSScriptParameter+Application.h"
#import "MGSParameterPluginController.h"
#import "MGSAppController.h"

@implementation MGSScriptParameter (Application)

+ (id)newWithDefaultTypeName
{
	// set default plugin class name
	MGSParameterPluginController *parameterPluginController = [[NSApp delegate] parameterPluginController];
	NSString *pluginClassName = [parameterPluginController defaultPluginName];
    
    return [self newWithTypeName:pluginClassName];
}

@end
