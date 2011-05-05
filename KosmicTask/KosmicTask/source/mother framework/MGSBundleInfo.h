//
//  MGSBundleTaskInfo.h
//  KosmicTask
//
//  Created by Jonathan on 01/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSKeyBundleVersionDocsImported;
extern NSString *MGSKeyMachineSerial;
extern NSString *MGSKeyBundleVersionDocsExported;
extern NSString *MGSKeyBundleVersionResourcesExported;

@interface MGSBundleInfo : NSObject {

}

+ (NSString *)infoPath;
+ (NSNumber *)applicationBundleVersion;
+ (NSMutableDictionary *)infoDictionary:(NSString *)name;
+ (BOOL)saveInfoDictionary:(NSDictionary *)dictionary withName:(NSString *)name;

+ (NSMutableDictionary *)appInfoDictionary;
+ (BOOL)appResourcesInSyncWithBundle;
+ (void)confirmAppResourcesInSyncWithBundle;

+ (NSMutableDictionary *)serverInfoDictionary;
+ (BOOL)serverTasksInSyncWithBundle;
+ (void)confirmServerTasksInSyncWithBundle;
+ (void)saveServerInfoDictionary;

@end
