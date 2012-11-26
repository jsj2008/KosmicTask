//
//  MGSTempStorage.m
//  KosmicTask
//
//  Created by Jonathan on 03/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSTempStorage.h"
#import "mlog.h"

// option keys
NSString *MGSTempFileTemporaryDirectory = @"tempDirectory";
NSString *MGSTempFileSuffix = @"suffix";
NSString *MGSTempFileTemplate = @"template";

NSString *MGSKosmicTempFileNamePrefix = @"-KosmicTempFile-";

static id _sharedController = nil;


@implementation MGSTempStorage

@synthesize storageFolder, alwaysGenerateUniqueFilenames;

/*
 
 + defaultReverseURL
 
 */
+ (NSString *)defaultReverseURL
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

/*
 
 shared controller singleton
 
 note that we had a shared controller but that we can also instantiate separate instances.
 by default separate instances create their storage within the folder managed by the shared controller.
 when the shared controller is deallocated all the separate storage instances will be deleted too.
 
 */
+ (id)sharedController 
{
	@synchronized(self) {
		if (nil == _sharedController) {
			NSString *revURL = [[self defaultReverseURL] stringByAppendingString:@".files"];
			_sharedController = [[self alloc] initWithFolder:revURL];
			[(MGSTempStorage *)_sharedController setAlwaysGenerateUniqueFilenames:YES];
		}
	}
	return _sharedController;
}

#pragma mark instance methods

/*
 
 - init
 
 */
- (id) init
{
	return [self initStorageFacility];
}

/*
 
 - initWithFolder:
 
 designated initialiser
 
 */
- (id) initWithFolder:(NSString *)folder
{
	self = [super init];
	if (self) {
		if (!folder) { 
			folder = [[self class] defaultReverseURL];
		}
		storageFolder = folder;
		alwaysGenerateUniqueFilenames = NO;
	}
	
	return self;
}

/*
 
 - initStorageFacility
 
 */
- (id)initStorageFacility
{
	MGSTempStorage *sharedController = [[self class] sharedController];
	
	// We want to use the same storage folder as the shared instance.
	// This will ensure that the separate instances storage folders are created
	// within the shared instance folder. When the shared instance is deleted at application
	// shutdown all the separate instance storage will also get removed.
	// This should prevent any orphaned files from being persisted.
	
	// create a new storage directory
	NSString *storageDirectory = [sharedController storageDirectoryWithOptions:nil];
	
	// extract the folder for the above directory
	NSString *folder = [[sharedController storageFolder] stringByAppendingPathComponent:[storageDirectory lastPathComponent]];
	
	
	self = [self initWithFolder:folder];
	if (self) {
	}
	
	return self;	
}

/*
 
 - deleteStorageFacility
 
 */
- (void)deleteStorageFacility
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:[self storagePath]]) {
		return;
	}
	
	NSError *error = nil;
	if (![[NSFileManager defaultManager] removeItemAtPath:[self storagePath] error:&error]) {
		NSLog(@"%@ : %@", [error localizedDescription], [self storagePath]);
	}
}

/*
 
 - storagePath
 
 */
- (NSString *)storagePath
{
	NSString *path = nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count])
	{
		path = [paths objectAtIndex:0];
	} else {
		path = NSTemporaryDirectory();
	}

	// bundleName
	path = [path stringByAppendingPathComponent:storageFolder];
	
	return path;
}
/*
 
 - storageDirectory
 
 */

- (NSString *)storageFacility
{
	/*
	
	 NSTemporaryDirectory() is cleaned out every three days!
	 
	 http://cocoawithlove.com/2009/07/temporary-files-and-folders-in-cocoa.html
	 
	 */
	
	if (!tempDirectory) {
		tempDirectory = [self storagePath];
	}
	
	// make sure it exists
	if (![[NSFileManager defaultManager] fileExistsAtPath:tempDirectory]) {		
		if (![[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory 
									   withIntermediateDirectories:YES attributes:nil error:NULL]) {
			NSLog(@"Cannot establish temp storage facility at : %@", tempDirectory);
			tempDirectory = NSTemporaryDirectory();
		}
	}
	
	if (![tempDirectory hasSuffix:@"/"]) {
		tempDirectory = [tempDirectory stringByAppendingString:@"/"];
	}
	
	return tempDirectory;
}
/*
 
 - storageFileWithOptions:
 
 */
- (NSString *)storageFileWithOptions:(NSDictionary *)options
{

	NSString *suffix = [options objectForKey:MGSTempFileSuffix];
	if (!suffix) {
		suffix = @"";
	}

	NSString *directory = [options objectForKey:MGSTempFileTemporaryDirectory];
	if (!directory) {
		directory = [self storageFacility];
	}
	
	NSString *template = [options objectForKey:MGSTempFileTemplate];
	if (!template) {
		template = @"XXXXXX";
	}
	
	// create template
	NSString *templatePath = [NSString stringWithFormat:@"%@%@", directory, [template stringByAppendingString:suffix]];
	char *buffer = (char *)[templatePath fileSystemRepresentation];
	if (buffer == NULL) {
		NSLog(@"Cannot get representation of  temp file: %@", templatePath);
		return nil;
	}
		
	// create the file
	int fd = mkstemps(buffer, (int)[suffix length]);
	if (fd == -1) {
		NSLog(@"Cannot create temp file: %s", buffer);
		return nil;
	}
	close(fd);
	
	NSString *path = [NSString stringWithFormat:@"%s", buffer];
	return path;
}

/*
 
 - storageDirectoryWithOptions:
 
 */
- (NSString *)storageDirectoryWithOptions:(NSDictionary *)options
{
	NSString *template = [options objectForKey:MGSTempFileTemplate];
	if (!template) {
		template = @"XXXXXX";
	}
	
	// create directory template
	NSString *templatePath = [NSString stringWithFormat:@"%@%@", [self storageFacility], template];
	char *buffer = (char *)[templatePath fileSystemRepresentation];
	if (buffer == NULL) {
		NSLog(@"Cannot get representation of temp dir: %@", templatePath);
		return nil;
	}
	
	// create the directory
	char *dir = mkdtemp(buffer);
	if (dir == NULL) {
		NSLog(@"Cannot create temp dir: %s", buffer);
		return nil;
	}
	
	NSString *path = [NSString stringWithFormat:@"%s", dir];
	
	if (![path hasSuffix:@"/"]) {
		path = [path stringByAppendingString:@"/"];
	}
	
	return path;
	
}

/*
 
 - removeStorageItemAtPath:
 
 */
- (BOOL)removeStorageItemAtPath:(NSString *)path
{
	NSError *error = nil;
	
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
	
	return success;
}

/*
 
 - setStorageFolder:
 
 */
- (void)setStorageFolder:(NSString *)folder
{
	if (folder) {
		storageFolder = folder;
		tempDirectory = nil;	// temp directory will now be different
	}
}
@end
