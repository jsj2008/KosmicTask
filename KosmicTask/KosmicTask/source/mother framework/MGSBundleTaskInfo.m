//
//  MGSBundleTaskInfo.m
//  KosmicTask
//
//  Created by Jonathan on 01/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSBundleTaskInfo.h"
#import "MGSMother.h"
#import "MGSPath.h"

NSString *MGSToolInfoPlist = @"BundleTaskInfo.plist";
NSString *MGSToolInfoKeyBundleVersionDocsImported = @"bundleVersionDocsImportedIntoMds";	// manual import of bundle docs into mds
NSString *MGSToolInfoKeyBundleVersionDocsExported = @"bundleVersionDocsExported";	// bundle docs exported to user space
NSString *MGSToolInfoKeyMachineSerial = @"machineSerial";

@implementation MGSBundleTaskInfo

/*
 
 info path
 
 */
+ (NSString *)infoPath
{
	// path to bundle task info
	NSString *path = [MGSPath userApplicationSupportPath];
	MLog(DEBUGLOG, @"Task info path: %@", path);
	return path;
}

/*
 
 info dictionary
 
 */
+ (NSMutableDictionary *)infoDictionary 
{
	// bundle path gives path to tool executable
	NSString *path = [[self infoPath] stringByAppendingPathComponent:MGSToolInfoPlist];
	NSMutableDictionary *toolInfo = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	if (!toolInfo) {
		MLog(RELEASELOG, @"Task info not found: %@", path);
		toolInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	}
	
	return toolInfo;
}

/*
 
 save info dictionary
 
 */
+ (BOOL)saveInfoDictionary:(NSDictionary *)dictionary
{
	NSString *path = [[self infoPath] stringByAppendingPathComponent:MGSToolInfoPlist];
	BOOL saved = [dictionary writeToFile:path atomically:YES];
	if (!saved) {
		MLog(RELEASELOG, @"Failed to save task info: %@", path);
	}
	
	return saved;
}
@end
