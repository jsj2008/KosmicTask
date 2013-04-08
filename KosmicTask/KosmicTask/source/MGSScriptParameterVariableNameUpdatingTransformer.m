//
//  MGSScriptParameterVariableNameUpdatingTransformer.m
//  KosmicTask
//
//  Created by Jonathan on 07/04/2013.
//
//

#import "MGSScriptParameterVariableNameUpdatingTransformer.h"
#import "MGSScriptParameter.h"

@implementation MGSScriptParameterVariableNameUpdatingTransformer

/*
 
 + transformedValueClass
 
 */
+ (Class)transformedValueClass
{
	return [NSString class];
}
/*
 
 + allowsReverseTransformation
 
 */
+ (BOOL)allowsReverseTransformation
{
	return NO;
}

/*
 
 - transformedValue
 
 */
- (id)transformedValue:(id)value
{
    
	NSInteger status = MGSScriptParameterVariableNameUpdatingAuto;
	NSString *output = @"missing";
    
	if ([value isKindOfClass:[NSNumber class]]) {
		status = [(NSNumber *)value integerValue];
	}
	
    switch (status) {
        case MGSScriptParameterVariableNameUpdatingAuto:
            output = NSLocalizedString(@"Auto", @"Auto update variable name");
            break;
            
        case MGSScriptParameterVariableNameUpdatingManual:
            output = NSLocalizedString(@"Manual", @"Manual update variable name");
            break;
            
        default:
            break;
    }
    
    return output;
}

@end
