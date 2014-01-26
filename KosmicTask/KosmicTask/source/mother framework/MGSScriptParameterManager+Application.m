//
//  MGSScriptParameterManager+Application.m
//  KosmicTask
//
//  Created by Jonathan Mitchell on 26/01/2014.
//
//

#import "MGSScriptParameterManager+Application.h"
#import "MGSAppController.h"
#import "MGSParameterPluginController.h"
#import "MGSParameterPlugin.h"

@implementation MGSScriptParameterManager (Application)

/*
 
 - copyValidValuesWithMatchingUUID:
 
 */
- (void)copyValidValuesWithMatchingUUID:(MGSScriptParameterManager *)srcManager
{
    for (NSInteger i = 0; i < [srcManager count]; i++) {
        MGSScriptParameter *srcParameter = [srcManager itemAtIndex:i];
        
        // get parameter with matching UUID
        MGSScriptParameter *parameter = [self scriptParameterWithUUID:srcParameter.UUID];
        
        // match parameter type
        if (parameter && [parameter.typeName isEqualToString:srcParameter.typeName]) {
            
            // we cannot simply set the value as it may be invalid or out of range
            // on the target parameter. hence we need to validate it using the plugin
            MGSParameterPluginController *parameterPluginController = [[NSApp delegate] parameterPluginController];
            MGSParameterPlugin *plugin = [parameterPluginController pluginWithClassName:parameter.typeName];
            
            if (plugin) {
                parameter.value = srcParameter.value;
            }
        }
    }
    
}



@end
