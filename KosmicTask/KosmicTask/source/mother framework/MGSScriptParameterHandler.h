//
//  MGSScriptParameterHandler.h
//  Mother
//
//  Created by Jonathan on 09/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MGSFactoryArrayController.h"

@interface MGSScriptParameterHandler : MGSFactoryArrayController {

}
- (void)setHandlerFromDict:(NSMutableDictionary *)dict;
- (NSString *)shortStringValue;
@end
