//
//  MGSScriptParameterManager+Application.h
//  KosmicTask
//
//  Created by Jonathan Mitchell on 26/01/2014.
//
//

#import "MGSScriptParameterManager.h"

@interface MGSScriptParameterManager (Application)
- (void)copyValidValuesWithMatchingUUID:(MGSScriptParameterManager *)parameterManager;
@end
