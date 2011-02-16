//
//  MGSAppleScriptRunner.h
//  Mother
//
//  Created by Jonathan on 01/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSScriptRunner.h"

@interface MGSAppleScriptRunner : MGSScriptRunner {

}

+ (NSMutableDictionary *)userInfoFromAppleScriptErrorDict:(NSDictionary *)errorDict;

@end
