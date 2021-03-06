//
//  MGSBundleTaskInfo.m
//  KosmicTask
//
//  Created by Jonathan on 01/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSBundleInfo.h"
#import "MGSMother.h"
#import "MGSPath.h"
#import "MGSKosmicTask_vers.h"

NSString *MGSServerInfoPlist = @"BundleTaskInfo.plist";
NSString *MGSAppInfoPlist = @"BundleAppInfo.plist";

NSString *MGSKeyBundleVersionDocsImported = @"bundleVersionDocsImportedIntoMds";	// manual import of bundle docs into mds
NSString *MGSKeyBundleVersionDocsExported = @"bundleVersionDocsExported";	// bundle docs exported to user space
NSString *MGSKeyBundleVersionResourcesExported = @"bundleVersionResourcesExported";	// bundle resources exported to user space
NSString *MGSKeyMachineSerial = @"machineSerial";

@implementation MGSBundleInfo

/*
 
 info path
 
 */
+ (NSString *)infoPath
{
	// path to bundle task info
	NSString *path = [MGSPath userApplicationSupportPath];
	MLog(DEBUGLOG, @"Bundle info path: %@", path);
	return path;
}

/*
 
 + applicationBundleVersion
 
 */
+ (NSNumber *)applicationBundleVersion
{
	/*
	 
	 get the current bundle version
	 
	 note that the version here is not read from the info.plist but is autogenerated by 
	 agvtool bump -all
	 
	 it is imperative that the bundle version is bumped in this way otherwise
	 new application task importing will not occur
	 
	 we use the compiled in version as it is guaranteed to be accesible to all
	 the components that link against the framework rather than having to access
	 the app bundle info.plist
	 
	 */
	NSNumber *bundleVersion = [NSNumber numberWithDouble:MGSKosmicTaskVersionNumber];
	
	return bundleVersion;
}

/*
 
 + infoDictionary:
 
 */
+ (NSMutableDictionary *)infoDictionary:(NSString *)name 
{
	// bundle path gives path to tool executable
	NSString *path = [[self infoPath] stringByAppendingPathComponent:name];
	NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	if (!info) {
		MLog(DEBUGLOG, @"Info dictionary not found: %@", path);
		info = [NSMutableDictionary dictionaryWithCapacity:1];
	}
	
	return info;
}

/*
 
 save info dictionary
 
 */
+ (BOOL)saveInfoDictionary:(NSDictionary *)dictionary withName:(NSString *)name
{
	NSString *path = [[self infoPath] stringByAppendingPathComponent:name];
	BOOL saved = [dictionary writeToFile:path atomically:YES];
	if (!saved) {
		MLogInfo(@"Failed to save task info: %@", path);
	}
	
	return saved;
}


#pragma mark -
#pragma mark Application 
/*
 
 + appInfoDictionary
 
 */
+ (NSMutableDictionary *)appInfoDictionary 
{
	static NSMutableDictionary *dict = nil;
	
	if (!dict) {
		dict = [self infoDictionary:MGSAppInfoPlist];
	}
	
	return dict;
}

/*
 
 + appResourcesSyncedWithBundle
 
 */
+ (BOOL)appResourcesInSyncWithBundle
{
	// get exported version and bundle version
	NSNumber *bundleVersionExported = [[self appInfoDictionary] objectForKey:MGSKeyBundleVersionResourcesExported];
	NSNumber *bundleVersion = [self applicationBundleVersion];
	
	MLog(DEBUGLOG, @"exported resource version: %@", bundleVersionExported);
	MLog(DEBUGLOG, @"bundle resource version: %@", bundleVersion);
	
	// check if docs exported for the current bundle
	BOOL inSync = [bundleVersion isEqual:bundleVersionExported];
	
	return inSync;
}
/*
 
 + updateAppResourcesInSyncWithBundle
 
 */
+ (void)confirmAppResourcesInSyncWithBundle
{
	NSMutableDictionary *dict = [self appInfoDictionary];
	[dict setObject:[self applicationBundleVersion] forKey:MGSKeyBundleVersionResourcesExported];
	[self saveInfoDictionary:dict withName:MGSAppInfoPlist];
}

#pragma mark -
#pragma mark Server

/*
 
 + serverInfoDictionary
 
 */
+ (NSMutableDictionary *)serverInfoDictionary 
{
	static NSMutableDictionary *dict = nil;
	
	if (!dict) {
		dict = [self infoDictionary:MGSServerInfoPlist];
	}
	
	return dict;
}


/*
 
 + serverTasksSyncedWithBundle
 
 */
+ (BOOL)serverTasksInSyncWithBundle
{
	// get exported version and bundle version
	NSNumber *bundleVersionExported = [[self serverInfoDictionary] objectForKey:MGSKeyBundleVersionDocsExported];
	NSNumber *bundleVersion = [self applicationBundleVersion];
	
	MLog(DEBUGLOG, @"exported tasks version: %@", bundleVersionExported);
	MLog(DEBUGLOG, @"bundle tasks version: %@", bundleVersion);
	
	// check if docs exported for the current bundle
	BOOL inSync = [bundleVersion isEqual:bundleVersionExported];
	
	return inSync;
}
/*
 
 + updateServerTasksInSyncWithBundle
 
 */
+ (void)confirmServerTasksInSyncWithBundle
{
	NSMutableDictionary *dict = [self serverInfoDictionary];
	[dict setObject:[self applicationBundleVersion] forKey:MGSKeyBundleVersionDocsExported];
	[self saveServerInfoDictionary];
}

/*
 
 + saveServerInfoDictionary
 
 */
+ (void)saveServerInfoDictionary
{
	[self saveInfoDictionary:[self serverInfoDictionary] withName:MGSServerInfoPlist];
}

@end
