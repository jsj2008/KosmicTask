//
//  MGSMetaDataHandler.m
//  Mother
//
//  Created by Jonathan on 05/12/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSMetaDataHandler.h"
#import "MGSBundleInfo.h"
#import "MGSSystem.h"
#import "NSBundle_Mugginsoft.h"


// these externs will be linked in automatically from the derived sources folder
// depending on the target
#if MGS_KOSMICTASK_SERVER

// build is server
#import "KosmicTaskServer_vers.h"       // server
#define MGS_KOSMICTASK_SERVER_VERSION_EXTERN KosmicTaskServerVersionNumber

#elif MGS_KOSMICTASK_SERVER_FRAMEWORK

// build is framework
#import "MGSKosmicTaskServer_vers.h"    // framework
#define MGS_KOSMICTASK_SERVER_VERSION_EXTERN MGSKosmicTaskServerVersionNumber

#endif

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
				MLog(DEBUGLOG, @"mdimport %@ returns 0 - success", path);
				
				// get bundle task info dictionary
				NSMutableDictionary *taskInfo = [MGSBundleInfo serverInfoDictionary];
				[taskInfo setObject:[NSNumber numberWithDouble:MGS_KOSMICTASK_SERVER_VERSION_EXTERN] forKey:MGSKeyBundleVersionDocsImported];
				
				if (NO) {
					[taskInfo setObject:[[MGSSystem sharedInstance] machineSerialNumber] forKey:MGSKeyMachineSerial];
				}
				
				[MGSBundleInfo saveServerInfoDictionary];
				
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
