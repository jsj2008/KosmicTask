//
//  MGSLanguagePluginController.m
//  KosmicTask
//
//  Created by Jonathan on 26/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguagePluginController.h"
#import "NSBundle_Mugginsoft.h"
#import "MGSPath.h"
#import "MGSBundleInfo.h"

static MGSLanguagePluginController *mgs_sharedController = nil;

@implementation MGSLanguagePluginController

@synthesize scriptTypes, resourcesLoaded;

/*
 
 + applicationLanguageResourcesPath
 
 */

+ (NSString *)applicationLanguageResourcesPath
{
	NSString *path = [MGSPath applicationDocumentPath];
	return [path stringByAppendingPathComponent:@"Resources/Languages"];
}

/*
 
 + userLanguageResourcesPath
 
 */

+ (NSString *)userLanguageResourcesPath
{
	NSString *path = [MGSPath userDocumentPath];	
	return [path stringByAppendingPathComponent:@"Resources/Languages"];
}

/*
 
 + bundleExtension
 
 */
+ (NSString *) bundleExtension
{
	return @"lang-plugin";
}

/*
 
 shared controller singleton
 
 */
+ (id)sharedController 
{
	@synchronized(self) {
		if (nil == mgs_sharedController) {
			[[self alloc] init];  // assignment occurs below
		}
	}
	return mgs_sharedController;
}

/*
 
 alloc with zone for singleton
 
 */
+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (mgs_sharedController == nil) {
            mgs_sharedController = [super allocWithZone:zone];
            return mgs_sharedController;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
} 

/*
 
 + plugInClass
 
 */
+ (Class)plugInClass
{
	return [MGSLanguagePlugin class];
}

#pragma mark instance methods

/*
 
 copy with zone for singleton
 
 */
- (id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
    return self;
}

/*
 
 - allPluginsLoaded
 
 */
- (void)allPluginsLoaded
{	
	
	// sorted array of script types
	scriptTypes = [NSMutableArray arrayWithCapacity:15];
	for (MGSLanguagePlugin *plugin in [self instances]) {
		
		// sanity check on plugin class
		NSAssert([plugin isKindOfClass:[MGSLanguagePlugin class]], @"Language plugin has wrong class");
		
		[scriptTypes addObject:[plugin scriptType]];
	}
	[scriptTypes sortUsingSelector:@selector(isEqualToString:)];	
}

/*
 
 - loadPluginResources
 
 */
- (void)loadPluginResources
{
	if (!self.resourcesLoaded) {
		
		NSString *appPath = [[self class] applicationLanguageResourcesPath];
		BOOL resourcesInSyncWithBundle = [MGSBundleInfo appResourcesInSyncWithBundle];
		
		/*
		 
		 if local resources are not synced with the bundle then we 
		 delete the local application resources to force all of them 
		 to be reloaded from the bundle
		 
		 */
		if (!resourcesInSyncWithBundle) {
			
			NSMutableString *infoString = [NSMutableString stringWithFormat:@"A new application bundle (ver: %@) has been found\n", [MGSBundleInfo applicationBundleVersion]];
			[infoString appendString:@"All application resources will be updated from the bundle.\n"];	
			MLogInfo(infoString, nil);		

			NSError *error = nil;
			[[NSFileManager defaultManager] removeItemAtPath:appPath error:&error];
			if (error) {
				MLogInfo(@"An error occured when trying to update the application resources : %@", error);
			} 
		}
		
		// load app resources
		for (MGSLanguagePlugin *plugin in [self instances]) {
			[plugin loadApplicationResourcesAtPath:appPath name:[plugin scriptType]];
		}
		
		// load user resources
		NSString *userPath = [[self class] userLanguageResourcesPath];
		for (MGSLanguagePlugin *plugin in [self instances]) {
			[plugin loadUserResourcesAtPath:userPath name:[plugin scriptType]];	
		}
		
		self.resourcesLoaded = YES;
		
		/*
		 
		 confirm that app resources are now in sync with bundle.
		 
		 at present we don't use any error reporting to confirm wether the resources were imported without error.
	
		 */
		if (!resourcesInSyncWithBundle) {
			[MGSBundleInfo confirmAppResourcesInSyncWithBundle];
		}
	}
	
}
/*
 
 - savePluginSettings
 
 */
- (void)savePluginSettings
{
	if (self.resourcesLoaded) {
		
		// save settings
		for (MGSLanguagePlugin *plugin in [self instances]) {
			[plugin saveSettings];
		}
		
	}
	
}
/*
 
 - resolvePluginResources
 
 */
- (void)resolvePluginResources
{
	/*
	 
	 resources are generally loaded lazily.
	 we may however wish to preload the resources before binding to prevent
	 excess KVO activity.
	 
	 */
	[self loadPluginResources];
	[[self instances] makeObjectsPerformSelector:@selector(userResourcesManager)];
	[[self instances] makeObjectsPerformSelector:@selector(applicationResourcesManager)];
}
/*
 
 default plugin name
 
 */
- (NSString *)defaultPluginName
{

	// get default plugin class from info.plist
	NSString *pluginName = [NSBundle mainBundleInfoObjectForKey:MGSLanguagePluginDefaultClassName];
	
	return pluginName;
}

/*
 
 - defaultScriptType
 
 */
- (NSString *)defaultScriptType
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:MGSDefaultScriptType];
}

/*
 
 - setDefaultScriptType:
 
 */
- (void)setDefaultScriptType:(NSString *)scriptType
{
	if ([scriptTypes containsObject:scriptType]) {
		[[NSUserDefaults standardUserDefaults] setObject:scriptType forKey:MGSDefaultScriptType];
	} else {
		MLogInfo(@"Invalid default script type request : %@", scriptType);
	}
}

/*
 
 - pluginWithScriptType:
 
 */
- (MGSLanguagePlugin *)pluginWithScriptType:(NSString *)scriptType
{
	// an old style search representation wil lack the
	// script type.
	if (!scriptType) {
		return nil;
	}
	
	/*
	 
	 plugin with class name
	 
	 */
	for (MGSLanguagePlugin *plugin in _instances) {
		if ([[plugin scriptType] isEqualToString:scriptType]) {
			return plugin;
		}
	}
	
	NSAssert(NO, @"No language plugin for scriptType: %@", scriptType);
	
	return nil;
}

/*
 
 - pluginForSourceFileExtension:
 
 */
- (MGSLanguagePlugin *)pluginForSourceFileExtension:(NSString *)extension
{
	/*
	 
	 plugin with source file extension
	 
	 */
	
	for (MGSLanguagePlugin *plugin in _instances) {
		if ([plugin hasSourceFileExtension:extension]) {
			return plugin;
		}
	}
	
	return nil;
}

@end
