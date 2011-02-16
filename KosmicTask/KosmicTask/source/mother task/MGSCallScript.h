//
//  MGSCallScript.h
//  Mother
//
//  Created by Jonathan Mitchell on 29/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCallScript.h"

@interface MGSCallScript : TCallScript {

}

- (NSAppleEventDescriptor*) callHandler:(NSString *)handlerName withArrayOfParameters: (NSArray *)array;
- (NSAppleEventDescriptor *)executeAndReturnError;

+ (id) withURLToCompiledScript:(NSURL*)scriptURL;
+ (id) withCompiledData:(NSData *)data;
@end
