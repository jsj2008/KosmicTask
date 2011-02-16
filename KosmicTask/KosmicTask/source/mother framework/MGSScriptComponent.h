//
//  MGSScriptComponent.h
//  Mother
//
//  Created by Jonathan on 08/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSDictionary_Localize.h"

@interface MGSScriptComponent : NSObject {
		NSDictionary *_scriptDict;
		NSString *_preferredLang;
	}
- (void)setScriptDict:(NSDictionary *)dict;
- (NSDictionary *)scriptDict;
- (NSString *)name;
- (NSString *)description;
- (NSString *)stringForKey:(NSString *)key;
@end
