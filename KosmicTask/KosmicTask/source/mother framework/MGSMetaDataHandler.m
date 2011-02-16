//
//  MGSMetaDataHandler.m
//  Mother
//
//  Created by Jonathan on 05/12/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSMetaDataHandler.h"
#import "MGSBundleTaskInfo.h"
#import "MGSSystem.h"
#import "NSBundle_Mugginsoft.h"
#import "MGSKosmicTaskServer_vers.h"

@implementation MGSMetaDataHandler

/*
 
 import meta data at path
 
 */
+ (NSInteger)importMetaDataAtPath:(NSString *)path
{
	NSInteger status = 0;
	
	@try {
		
		NSArray *arguments = [NSArray arrayWithObjects: path,  nil];
		NSTask *task = [[NSTask alloc] init];
		
		MLog(DEBUGLOG, @"starting mdimport %@", path);
		
		[task setArguments:arguments];
		[task setLaunchPath:@"/usr/bin/mdimport"];
		[task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];	
		[task setStandardError:[NSFileHandle fileHandleWithNullDevice]];	
		[task launch];
		[task waitUntilExit];
		status = [task terminationStatus];
		
		switch (status) {
			case 0:
				MLog(RELEASELOG, @"mdimport %@ returns 0 - success", path);
				
				// get bundle task info dictionary
				NSMutableDictionary *taskInfo = [MGSBundleTaskInfo infoDictionary];
				[taskInfo setObject:[NSNumber numberWithDouble:KosmicTaskServerVersionNumber] forKey:MGSToolInfoKeyBundleVersionDocsImported];
				
				if (NO) {
					[taskInfo setObject:[[MGSSystem sharedInstance] machineSerialNumber] forKey:MGSToolInfoKeyMachineSerial];
				}
				
				[MGSBundleTaskInfo saveInfoDictionary:taskInfo];
				
				break;
				
			case 1:
				MLog(RELEASELOG, @"mdimport %@ returned 1 - failed", path);
				break;
				
			default:
				break;
				
		}
		
				
	}@catch (NSException *e) {
		NSLog(@"Exception launching mdimport: %@", [e reason]);
	}
	
	return status;
}

@end
