//
//  MGSScriptParameterHandler.h
//  Mother
//
//  Created by Jonathan on 09/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MGSFactoryArrayController.h"
#import "MGSScriptParameter.h"


@interface MGSScriptParameterManager : MGSFactoryArrayController {

}
- (void)setHandlerFromDict:(NSMutableDictionary *)dict;
- (NSString *)shortStringValue;

- (void)setRepresentation:(MGSScriptParameterRepresentation)value;
- (MGSScriptParameterRepresentation)representation;
- (BOOL)conformToRepresentation:(MGSScriptParameterRepresentation)representation;
- (BOOL)conformToRepresentation:(MGSScriptParameterRepresentation)representation options:(NSDictionary *)options;
- (void)removeRepresentation;
- (void)copyValidValuesWithMatchingUUID:(MGSScriptParameterManager *)parameterManager;
@end
