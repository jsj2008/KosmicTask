//
//  MGSServerScriptManager.h
//  Mother
//
//  Created by Jonathan on 22/11/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSScriptManager.h"
#import "MGSScript.h"

extern NSString *MGSApplicationTaskPlist;

@interface MGSServerScriptManager : MGSScriptManager {
	NSMutableDictionary *_applicationTaskDictionary;
}
- (BOOL)saveScriptPropertyPublished:(MGSScript *)script error:(NSString **)error;
- (BOOL)loadScriptsWithRepresentation:(MGSScriptRepresentation)representation;
- (void)setApplicationTaskDictionaryProperties;
- (BOOL)scriptUUIDPublished:(NSString *)UUID;
@end
