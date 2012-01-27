//
//  MGSLanguageTemplateResource.h
//  KosmicTask
//
//  Created by Jonathan on 14/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSResourceItem.h"
#import <MGTemplateEngine/MGTemplateEngine.h>

@class MGSScript;

@interface MGSLanguageTemplateResource : MGSResourceItem <MGTemplateEngineDelegate> {


}

- (NSString *)stringResourceWithVariables:(NSDictionary *)variables;

- (NSString *)scriptTemplate:(MGSScript *)script withInsertion:(NSString *)insertion;
- (NSString *)scriptSubroutineTemplate:(MGSScript *)script;

@end
