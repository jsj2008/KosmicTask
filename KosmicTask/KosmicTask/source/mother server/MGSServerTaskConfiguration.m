//
//  MGSServerTaskConfiguration.m
//  Mother
//
//  Created by Jonathan on 10/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//
#import "MGSMother.h"
#import "MGSServerScriptRequest.h"
#import "MGSNetRequest.h"
#import "MGSNetMessage.h"
#import "MGSScriptPlist.h"
#import "MGSTaskPlist.h"
#import "MGSPath.h"
#import "MGSBundleInfo.h"
#import "MGSServerScriptManager.h"
#import "MGSScript.h"
#import "MGSScriptCode.h"
#import "MGSError.h"
#import "MGSPreferences.h"
#import "NSPropertyListSerialization_Mugginsoft.h"
#import "MGSNetAttachments.h"
#import "MGSNetAttachment.h"
#import "NSString_Mugginsoft.h"
#import "MGSServerRequestThreadHelper.h"
#import "MGSAppleScriptData.h"
#import "MGSServerRequestManager.h"
#import "MGSScriptManager.h"
#import "MGSMetaDataHandler.h"
#import "MGSSystem.h"
#import "MGSServerTaskConfiguration.h"
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

// class extension
@interface MGSServerTaskConfiguration()
- (void)importApplicationMetadata;
@end

@implementation MGSServerTaskConfiguration


/*
 
 init
 
 */
- (id)init {
	
	if ((self = [super init])) {
		// validate the built in application tasks
		[self validateApplicationTasks];

	}
	
	return self;
}

/*
 
 validate metadata
 
 */
- (void)validateMetadata
{
	// get tool info dictionary
	NSMutableDictionary *taskInfo = [MGSBundleInfo serverInfoDictionary];
	
	// check if docs already imported
	NSNumber *docsVersionImported = [taskInfo objectForKey:MGSKeyBundleVersionDocsImported];
	
	// our foundation tool has a plist embedded as a TEXT section in the Mach-0 file.
	// however agvtool will  not update it.
	// so use the agvtool autogenerated version info.
	// the file generated is not a member of the project but is a dervied file.
	// look in the build.debug.target.DerivedSources folder to examine the derived file.
	NSNumber *bundleVersion = [NSNumber numberWithDouble:MGS_KOSMICTASK_SERVER_VERSION_EXTERN];
	
	if ([bundleVersion isEqual:docsVersionImported]) {
		MLog(DEBUGLOG, @"metadata import will not occur - application tasks have already been imported.");
		return;
	}
	
	// not certain if this is even required on using the application task based model.
	// will the OS not detect the new task files and index them accordingly?
	
	// queue metadata import
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
									selector:@selector(importApplicationMetadata) object:nil];		
	[self queueOperation:theOp];
	
}
/*
 
 import bundle metadata
 
 our template task docs reside in our bundle and Spotlight won't see them.
 hence kick off mdimport manually and log the fact in a local plist.
 when the app gets updated the bundle docs will be re-imported.
 
 this fails on 10.6
 
 */
- (void)importBundleMetadata
{	
	// import bundle document data if required
	NSString *bundleDocumentPath = [MGSScriptManager bundleDocumentPath];
	[MGSMetaDataHandler importMetaDataAtPath:bundleDocumentPath];
}

/*
 
 import application
 
 */
- (void)importApplicationMetadata
{	
	// import bundle document data if required
	NSString *applicationDocumentPath = [MGSScriptManager applicationDocumentPath];
	[MGSMetaDataHandler importMetaDataAtPath:applicationDocumentPath];
}

/*
 
 validate application tasks
 
 */
- (void)validateApplicationTasks
{
	
	NSString *applicationDocumentPath = [MGSScriptManager applicationDocumentPath];
	BOOL docsExported = [MGSBundleInfo serverTasksInSyncWithBundle];
	
	/*
	 
	 if bundle version docs not exported then export them
	 
	 */
	if (!docsExported) {
		
		/*
		 
		 log bundle update operations
		 
		 */
		NSMutableString *infoString = [NSMutableString stringWithFormat:@"A new application bundle (ver: %@) has been found\n", [MGSBundleInfo applicationBundleVersion]];
		[infoString appendString:@"All Mugginsoft authored application tasks will be updated from the bundle.\n"];
		[infoString appendString:@"All application task meta data will be reimported"];		
		MLogInfo(infoString, nil);
		
		// delete any existing application docs when upgrade app
		// deleting the entire folder is risky.
		// the user may have inserted valid scripts hoping to make them look like application tasks
		if (NO) {
			if ([[NSFileManager defaultManager] removeItemAtPath:applicationDocumentPath error:nil]) {
				MLog(DEBUGLOG, @"cannot delete application document path");
			}
		}
		
		/*
		 
		 remove all bundled tasks in folder. this way we can be fairly sure that we are only
		 deleting tasks that shipped with the app.
		 
		 */
		[self removeAllBundledTasksAtPath:applicationDocumentPath];
		
		// mark as updated
		[MGSBundleInfo confirmServerTasksInSyncWithBundle];
		
		// recreate the path
		applicationDocumentPath = [MGSPath verifyApplicationDocumentPath];
	}
		
	// copy bundle docs to folder.
	// will skip existing documents.
	// always calling this ensures that the documents match the bundle
	[self copyBundleDocumentsToPath:applicationDocumentPath];
	
	// validate metadata
	[self validateMetadata];	
	
	return;
}

/*
 
 queue an operation
 
 */
- (void)queueOperation:(NSInvocationOperation *)theOp
{
	// lazy
	if (!_operationQueue) {
		_operationQueue = [NSOperationQueue new];
	}
	
	[_operationQueue addOperation:theOp];
	
	return;
}

//===============================================
// copy the default plists to the folder if
// they do not already exist
//
//===============================================
- (BOOL)copyBundleDocumentsToPath:(NSString *)folder
{
	NSAssert(folder, @"folder is nil");
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	/*
	 
	 regardless of where server is in the app bundle the plists are in the bundle resources folder
	 
	 */
	NSString *path = [MGSServerScriptManager bundleDocumentPath];
	if (!path) {
		return NO;
	}
	
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	if (!dirEnum) {
		MLog(DEBUGLOG, @"cannot enumerate bundle tasks path");	// when not run by parent the path points to the process executable
		return YES;
	}
	
	
	NSString *file;
	while ((file = [dirEnum nextObject])) {
		
		// want to copy files only
		if (![[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString: NSFileTypeRegular]) {
			[dirEnum skipDescendents];	// don't enumerate directory any further
			continue;
		}
		
		// want to copy plists only (there shouldn't be anything else in there though)
		if (NSOrderedSame != [[file pathExtension] caseInsensitiveCompare:MGSScriptPlistExt]) {	
			continue;
		}
		
		// validate that filename is a valid UUID
		if (![[file stringByDeletingPathExtension] mgs_isUUID]) {
			MLog(RELEASELOG, @"invalid UUID at path: %@", [path stringByAppendingPathComponent:file]);
			continue;
		}
		
		// check if target file already exists
		NSString *targetFile = [folder stringByAppendingPathComponent: file];
		if ([fileManager fileExistsAtPath: targetFile]) {
			continue;
		}
		
		// copy script file to folder
		// files will inherit folder permissions
		NSString *sourceFile = [path stringByAppendingPathComponent: file];
		NSError *error;
		if (![fileManager copyItemAtPath:sourceFile toPath:targetFile error:&error]) {
			MLog(DEBUGLOG, @"Cannot copy plist %@ to %@ : error is : %@", sourceFile, targetFile, [error localizedDescription]);
			return NO;
		}
	}
	
	return YES;
}
/*
 
 remove all bundled tasks at path
 
 */
- (BOOL)removeAllBundledTasksAtPath:(NSString *)folder
{
	NSAssert(folder, @"folder is nil");
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
		
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:folder];
	if (!dirEnum) {
		MLog(DEBUGLOG, @"cannot enumerate folder: %@", folder);	// when not run by parent the path points to the process executable
		return YES;
	}

	NSString *file;
	while ((file = [dirEnum nextObject])) {

		// want files only
		if (![[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString: NSFileTypeRegular]) {
			[dirEnum skipDescendents];	// don't enumerate directory any further
			continue;
		}
		
		// want to scan plists only 
		if (NSOrderedSame != [[file pathExtension] caseInsensitiveCompare:MGSScriptPlistExt]) {	
			continue;
		}

		NSString *filePath = [folder stringByAppendingPathComponent:file];
		
		// validate that filename is a valid UUID
		if (![[file stringByDeletingPathExtension] mgs_isUUID]) {
			MLog(RELEASELOG, @"invalid UUID at path: %@", filePath);
			continue;
		}
		
		// attempt to load the script from the  file
		MGSError *mgsError = nil;
		MGSScript *script = [MGSScript scriptWithContentsOfFile:filePath error:&mgsError];
		if (!script) {
			continue;
		}
		
		// remove file if script is bundled and the origin is Mugginsoft.
		// the origin property cannot be set so it provides reasonable confirmation
		// that we are only deleting a bundled script that shipped with the app.
		if (script.isBundled && [script.origin caseInsensitiveCompare:MGSScriptOriginMugginsoft] == NSOrderedSame) {
			if (![fileManager removeItemAtPath:filePath error:NULL]) {
				MLog(RELEASELOG, @"could not delete bundled task: %@", filePath);
			}
		}
		script = nil;
	}

	return YES;
}


@end
