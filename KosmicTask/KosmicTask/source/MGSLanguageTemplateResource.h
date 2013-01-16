//
//  MGSLanguageTemplateResource.h
//  KosmicTask
//
//  Created by Jonathan on 14/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSResourceItem.h"

#ifdef MGS_USE_MGTemplateEngine
#import <MGTemplateEngine/MGTemplateEngine.h>
#endif

@class MGSScript;

#ifdef MGS_USE_MGTemplateEngine
@interface MGSLanguageTemplateResource : MGSResourceItem <MGTemplateEngineDelegate> {
#else
@interface MGSLanguageTemplateResource : MGSResourceItem {
#endif

}

- (NSString *)stringResourceWithVariables:(NSDictionary *)variables;

- (NSString *)scriptTemplate:(MGSScript *)script withInsertion:(NSString *)insertion;
- (NSString *)scriptSubroutineTemplate:(MGSScript *)script;

@end
