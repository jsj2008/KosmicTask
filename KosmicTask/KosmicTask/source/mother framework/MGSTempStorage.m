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

@synthesize reverseURL;

/*
 
 shared controller singleton
 
 note that we had a shared controller but that we can also instantiate separate instances
 
 */
+ (id)sharedController 
{
	@synchronized(self) {
		if (nil == _sharedController) {
			_sharedController = [[self alloc] initWithReverseURL:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]]; 
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
	return [self initWithReverseURL:nil];
}

/*
 
 - init
 
 designated initialiser
 
 */
- (id) initWithReverseURL:(NSString *)URL
{
	self = [super init];
	if (self) {
		if (!URL) return nil;
		
		reverseURL = URL;
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
	path = [path stringByAppendingPathComponent:reverseURL];
	
	return path;
}
/*
 
 - storageDirectory
 
 */

- (NSString *)storageDirectory
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
#pragma unused(options)
	
	NSString *suffix = [options objectForKey:MGSTempFileSuffix];
	if (!suffix) {
		suffix = @"";
	}

	NSString *directory = [options objectForKey:MGSTempFileTemporaryDirectory];
	if (!directory) {
		directory = [self storageDirectory];
	}
	
	NSString *template = [options objectForKey:MGSTempFileTemplate];
	if (!template) {
		template = @"XXXXXXXXXX";
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
		template = @"MGSTempStorage.XXXXXXXXXX";
	}
	
	// create directory template
	NSString *templatePath = [NSString stringWithFormat:@"%@%@", [self storageDirectory], template];
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
 
 - setReverseURL:
 
 */
- (void)setReverseURL:(NSString *)url
{
	if (url) {
		reverseURL = url;
		tempDirectory = nil;	// temp directory will now be different
	}
}
@end
