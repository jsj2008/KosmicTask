//
//  MGSScriptParameterVariableStatusTransformer.m
//  KosmicTask
//
//  Created by Jonathan on 06/04/2013.
//
//

#import "MGSScriptParameterVariableStatusTransformer.h"
#import "MGSScriptParameter.h"

@implementation MGSScriptParameterVariableStatusTransformer

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
- (id)transformedValue:(id)value {
	NSInteger status = MGSScriptParameterVariableStatusNew;
	NSString *output = @"missing";
    
	if ([value isKindOfClass:[NSNumber class]]) {
		status = [(NSNumber *)value integerValue];
	}
	
    switch (status) {
        case MGSScriptParameterVariableStatusNew:
            output = NSLocalizedString(@"New", @"new variable");
            break;
            
        case MGSScriptParameterVariableStatusUsed:
            output = NSLocalizedString(@"Used", @"used variable");
            break;
            
    }

    return output;
}

@end
