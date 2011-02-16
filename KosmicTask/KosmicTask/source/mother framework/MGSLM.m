//
//  MGSLM.m
//  Mother
//
//  Created by Jonathan on 29/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSLM.h"
#import "MGSL.h"
#import "MGSPath.h"
#import "MGSError.h"
#import "NSString_Mugginsoft.h"
#import "MGSUser.h"
#import "MGSAPLicence.h"
#import "NSBundle_Mugginsoft.h"

NSString *MGSStoreURL = @"MGSStoreURL";

static MGSLM *_sharedController = nil;
NSString *ext = @"ktlic";
NSString *MGSSoftwareLicenceFolder = @"Software Licences";

NSString *MGSNoteLicenceStatusChanged = @"MGSWindowStatusChanged";	// non obvious

@interface MGSLM (Private)
- (NSMutableArray *)allPaths:(NSString *)fileExtension;
- (MGSL *)trial;
- (MGSL *)itemWithHash:(NSString *)hash;
@end


@implementation MGSLM


@synthesize lastError = _lastError;
@synthesize mode = _mode;

/*
 
 init
 
 */
- (id) init
{
	if ((self = [super init])) {
		[self setObjectClass:[MGSL class]];	// add this class
		_lastError = nil;
		_mode = MGSInvalidLicenceMode;
	}
	return self;
}


/* 
 
 initialize paths
 
 */
+ (void) initializePaths
{
	// user licence save path
	NSString *folder = [self userApplicationSavePath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:folder])
	{
		[MGSPath createFolder:folder withAttributes:[MGSPath userFileAttributes]];
	}
	 
	// admin licence support path
	if ([[MGSUser currentUser] isMemberOfAdminGroup]) {
		folder = [self applicationSavePath];
		if (![[NSFileManager defaultManager] fileExistsAtPath:folder])
		{
			[MGSPath createFolder:folder withAttributes:[MGSPath adminFileAttributes]];
		}
	}
}
/*
 
 licence file extension
 
 */
- (NSString *)extension
{
	return ext;
}

/*
 
 buy licences
 
 */
+ (void)buyLicences
{
	// get store URL string from app info.plist
	NSString *urlString = [NSBundle mainBundleInfoObjectForKey:MGSStoreURL];
	if (!urlString) return;
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

/* 
 
 shared controller
 
 */
+ (id)sharedController
{
	if (!_sharedController) {
		_sharedController = [[self alloc] init];
		if (![_sharedController loadAll]) {
			NSString *endMessage = [NSString stringWithFormat:@"Licence file error: %@\n\nApplication will end.", _sharedController.lastError];
			MLog(RELEASELOG, endMessage);
			NSRunAlertPanel(@"Licence File Problem", endMessage, @"OK", nil, nil);
			[NSApp terminate:nil];
		}
	}
	return _sharedController;
}


/*
 
 default licence option dictionary
 
 */
+ (NSMutableDictionary *)defaultOptionDictionary
{
	// current date
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	NSString *formattedDateString = [dateFormatter stringFromDate:date];
	
	// default licence type
	NSNumber *licenceType = [MGSL defaultType];
	
	// make dictionary
	return [NSMutableDictionary dictionaryWithObjectsAndKeys: formattedDateString, MGSAddedLicenceKey, licenceType, MGSTypeLicenceKey, nil];
}

/*
 
 all licence data
 
 sensitive message name is not descriptive
 
 */
- (NSArray *)allAppData
{
	NSMutableArray *licenceData = [NSMutableArray arrayWithCapacity:2];
	for (MGSL *licence in [self arrangedObjects]) {
		NSDictionary *dict = [licence plist];
		if (dict) {
			[licenceData addObject:dict];
		}
	}
	
	return licenceData;
}

/*
 
 connections count
  
 */
- (NSUInteger)seatCount
{
	NSUInteger seatCount = 0;
	for (MGSL *licence in [self arrangedObjects]) {
		seatCount += [licence seatCount];
	}
	
	return seatCount;
}


/*
 
 load all licences
 
 */
- (BOOL)loadAll
{
    NSString *currPath;
	
	_mode = MGSInvalidLicenceMode;
	
	// discard current objects
	[self removeObjects: [self arrangedObjects]];
	
    NSMutableArray *bundlePaths = [NSMutableArray array];	
    [bundlePaths addObjectsFromArray:[self allPaths:ext]];
	
    NSEnumerator * pathEnum = [bundlePaths objectEnumerator];
    while((currPath = [pathEnum nextObject]))
    {		
		// if path contains a valid licence file then retain it
		MGSL *licence = [[MGSL alloc] initWithPath:currPath];
		if ([licence valid]) {
			[self addObject:licence];
		}
	}
	
	// finished if no licences found
	if ([[self arrangedObjects] count] == 0) {
		_lastError = NSLocalizedString(@"No valid licence file found.", @"No valid licence file found.");
		return NO;
	}
	
	// if no trial licence found then the bundle has been interfered with
	id trial = [self trial];
	if (!trial) {
		_lastError = NSLocalizedString(@"Default trial licence file not found.", @"Default trial licence file not found.");
		return NO;
	}
	
	// if only one licence then we must be in trial mode
	if ([[self arrangedObjects] count] == 1) {
		_mode = MGSValidLicenceMode;
		return YES;
	}
	
	// if more than one licence found then the trial is not required
	// so remove it
	if ([[self arrangedObjects] count] > 1) {
		[self removeObject:trial];
	}
	
	// remove any duplicates
	for (int i = [[self arrangedObjects] count] -1; i >= 1; i--) {
		MGSL *licence_i = [[self arrangedObjects] objectAtIndex:i];
		for (int j = i-1; j >= 0; j--) {
			MGSL *licence_j = [[self arrangedObjects] objectAtIndex:j];
			if ([[licence_j hash] isEqualToString:[licence_i hash]]) {
				[self removeObject:licence_i];
				MLog(RELEASELOG, @"Duplicate licence found at path: %@ hash: %@", [licence_i path], [licence_i hash]);
				break;
			}
		}
	}
	
	// if a trial licence is still present then bundle has been interfered with
	if ([self trial]) {
		_lastError = NSLocalizedString(@"Licence configuration error.", @"Licence configuration error.");
		return NO;
	}
	
	_mode = MGSValidLicenceMode;
	
	return YES;
}

/*
 
 owner of first licence
 
 */
- (NSString *)firstOwner
{
	if (0 == [[self arrangedObjects] count]) {
		return @"none";
	}
	
	MGSL *licence = [[self arrangedObjects] objectAtIndex:0];
	return [licence owner];
}

/*
 
 add item at path
 
 */
- (BOOL)addItemAtPath:(NSString *)path withDictionary:(NSDictionary *)dictionary
{
	// does path contain a valid licence
	MGSL *licence = [[MGSL alloc] initWithPath:path];
	if (![licence valid]) {
		_lastError = NSLocalizedString(@"Licence is invalid.", @"Licence error.");
		return NO;
	}
	
	// cannot add a trial licence
	if ([licence isTrial]) {
		_lastError = NSLocalizedString(@"Trial licences cannot be installed in this manner.", @"Licence error.");
		return NO;
	}
	
	// has this licence already been loaded
	if ([self itemWithHash:[licence hash]]) {
		_lastError = NSLocalizedString(@"This licence is already installed.", @"Licence error.");
		return NO;
	}

	// if no dictionary supplied used default
	if (!dictionary) {
		dictionary = [MGSLM defaultOptionDictionary];
	}
	NSInteger licenceType = [[dictionary objectForKey:MGSTypeLicenceKey] integerValue];
	
	// form a target path for our licence
	// as multiple licences may be issued under the owners name use hash to guarantee uniqueness
	NSString *targetFilename = [[licence hash] stringByAppendingPathExtension:[path pathExtension]];
	NSString *targetPath = [[self savePathFromLicenceType:licenceType] stringByAppendingPathComponent:targetFilename];

	// save licence copy to target
	NSError *error = nil;
	if (![[NSFileManager defaultManager] copyItemAtPath:path toPath:targetPath error:&error]) {
		[MGSError clientCode:MGSLicenceCopyError userInfo:[error userInfo]];
		_lastError = NSLocalizedString(@"The licence file could not be copied to disk.", @"Licence error.");
		return NO;
	}
	
	// save dictionary as property list
	NSString *errorString = nil;
	NSData * data = [NSPropertyListSerialization dataFromPropertyList:dictionary format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
	if (errorString) {
		[MGSError clientCode:MGSLicenceCopyError reason:errorString];
		_lastError = NSLocalizedString(@"The licence file options could not be copied to disk.", @"Licence error.");
		return NO;
	}

	// save plist data to file
	NSString *dictFilename = [[licence hash] stringByAppendingPathExtension:@"plist"];
	NSString *DictPath =  [[self savePathFromLicenceType:licenceType] stringByAppendingPathComponent:dictFilename];
	if (![data writeToFile:DictPath atomically:YES]) {
		[MGSError clientCode:MGSLicenceCopyError reason:NSLocalizedString(@"File could not be written.", @"Licence file write error.")];
		_lastError = NSLocalizedString(@"The licence file options could not be copied to disk.", @"Licence error.");
		return NO;
	}
	
	// reload - this will discard an existing trial licences
	if  (![self loadAll]) {
		return NO;
	}

	// post licence change notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteLicenceStatusChanged object:nil userInfo:nil];
	
	return YES;
}

/*
 
 show last error as alert
 
 */
- (void)showLastError
{
	NSString *error = _lastError;
	if (!error) error = NSLocalizedString(@"No error to report", @"Licence error");
	NSRunCriticalAlertPanel(NSLocalizedString(@"Licence file error", @"Licence alert title text"),
							error,
							NSLocalizedString(@"OK", @"Licence button text"),nil,nil); 
	
}

/*
 
 show on successful licence addition
 
 */
- (void)showSuccess
{
	NSRunAlertPanel(NSLocalizedString(@"Licence file installed", @"Licence alert title text"),
							NSLocalizedString(@"The licence was successfully installed", @"Licence alert title text"),
							NSLocalizedString(@"OK", @"Licence button text"),nil,nil); 
	
}

/*
 
 path to save licence files to
 
 */
- (NSString *)savePathFromLicenceType:(NSInteger)licenceType
{
	NSString *path;
	
	switch (licenceType) {
		case MGSLTypeComputer:
			// will require admin rights
			path = [[self class] applicationSavePath];
			break;
			
		case MGSLTypeIndividual:
		default:
			path = [[self class] userApplicationSavePath];
			break;
	}
	return path;
}

/*
 
 application save path
 
 */

+ (NSString *)applicationSavePath
{
	return [[MGSPath applicationSupportPath] stringByAppendingPathComponent:MGSSoftwareLicenceFolder];
}

/*
 
 user application save path
 
 */
+ (NSString *)userApplicationSavePath
{
	return [[MGSPath userApplicationSupportPath] stringByAppendingPathComponent:MGSSoftwareLicenceFolder];
}
/*
 
 validate item at path
 
 */
- (BOOL)validateItemAtPath:(NSString *)path
{
	// does path contain a valid licence
	MGSL *licence = [[MGSL alloc] initWithPath:path];
	if (![licence valid]) {
		_lastError = NSLocalizedString(@"Licence is invalid.", @"Licence error.");
		return NO;
	}
	
	return YES;
}

/*
 
 dictionary of item at path
 
 */
- (NSDictionary *)dictionaryOfItemAtPath:(NSString *)path
{
	// does path contain a valid licence
	MGSL *licence = [[MGSL alloc] initWithPath:path];
	if (![licence valid]) {
		_lastError = NSLocalizedString(@"Licence is invalid.", @"Licence error.");
		return nil;
	}
	
	return [licence dictionary];
}

/*
 
 remove object and file
 
 */
- (BOOL)removeObjectAndFile:(MGSL *)licence
{
	[self removeObject:licence];
	
	// delete path to licence file
	NSError *error = nil;
	NSString *path = [licence path];
	if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
		[MGSError clientCode:MGSLicenceRemovalError	userInfo:[error userInfo]];
		return NO;
	}
	
	// delete path to option dict
	path = [licence optionDictPath];
	if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
		[MGSError clientCode:MGSLicenceRemovalError	userInfo:[error userInfo]];
		return NO;
	}	
	
	// post licence change notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteLicenceStatusChanged object:nil userInfo:nil];

	return YES;
}

@end

@implementation MGSLM (Private)
/*
 
 form array of paths to licences
 
 */
- (NSMutableArray *)allPaths:(NSString *)fileExtension
{
    NSString *currPath;
    NSMutableArray *bundleSearchPaths = [NSMutableArray array];
    NSMutableArray *allBundles = [NSMutableArray array];
	
	// search for all licences in bundle search path
	//
	[bundleSearchPaths addObject: [[self class] userApplicationSavePath]];
	[bundleSearchPaths addObject: [[self class] applicationSavePath]];
	
	// trial licence framework bundle resource path
    [bundleSearchPaths addObject: [[NSBundle bundleForClass:[self class]] resourcePath]];	
	
    NSEnumerator *searchPathEnum = [bundleSearchPaths objectEnumerator];
    while((currPath = [searchPathEnum nextObject]))
    {
        NSDirectoryEnumerator *bundleEnum;
        NSString *currBundlePath;
        bundleEnum = [[NSFileManager defaultManager]
					  enumeratorAtPath:currPath];
        if(bundleEnum)
        {
            while((currBundlePath = [bundleEnum nextObject]))
            {
                if([[currBundlePath pathExtension] isEqualToString:fileExtension])
                {
					[allBundles addObject:[currPath stringByAppendingPathComponent:currBundlePath]];
                }
            }
        }
    }
	
    return allBundles;
}

/*
 
 trial
 
 */
- (MGSL *)trial
{
	for (MGSL *item in [self arrangedObjects]) {
		if ([item isTrial]) return item;
	}
	
	return nil;
}

/* 
 
 return item matching hash
 
 */
- (MGSL *)itemWithHash:(NSString *)hash
{
	for (MGSL *item in [self arrangedObjects]) {
		if ([[item hash] isEqualToString:hash]) return item;
	}
	
	return nil;
}
@end
	
	 
