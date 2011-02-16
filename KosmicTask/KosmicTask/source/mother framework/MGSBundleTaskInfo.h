//
//  MGSBundleTaskInfo.h
//  KosmicTask
//
//  Created by Jonathan on 01/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSToolInfoKeyBundleVersionDocsImported;
extern NSString *MGSToolInfoKeyMachineSerial;
extern NSString *MGSToolInfoKeyBundleVersionDocsExported;

@interface MGSBundleTaskInfo : NSObject {

}

+ (NSString *)infoPath;
+ (NSMutableDictionary *)infoDictionary;
+ (BOOL)saveInfoDictionary:(NSDictionary *)dictionary;

@end
