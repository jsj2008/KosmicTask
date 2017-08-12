//
//  MGSPluginController.m
//  Mother
//
//  Created by Jonathan on 19/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSPluginController.h"
#import "mlog.h"

static NSString *appSupportSubpath = @"Application Support/KosmicTask/PlugIns";

// class interface
@interface MGSPluginController()
- (id)initWithPlugInClass:(Class)aClass;

@property (strong) NSArray *instances;
@end


@implementation MGSPluginController

//@synthesize pluginClass = _pluginClass;
@synthesize instances = _instances;

/*
 
 + plugInClass
 
 */
+ (Class)plugInClass
{
	return nil;
}

/*
 
 + bundleExtension
 
 */
+ (NSString *)bundleExtension
{
	return @"plugin";
}

/*
 
 + plugins
 
 */
+ (SEL)pluginsSelector
{
	return NULL;
}

/*
 
 - init
 
 */
- (id)init
{
	return [self initWithPlugInClass:[[self class] plugInClass]];
}


/*
 
 - initWithPlugInClass:
 
 designated initialiser
 
 */
- (id)initWithPlugInClass:(Class)aClass
{
	_pluginClass = aClass;
	
	if ([super init]) {
		_additionalSearchPaths = [[NSMutableArray alloc] init];
	}
	return self;
}

/*
 
 validate the plugin class
 
 */
- (BOOL)plugInClassIsValid:(Class)plugInClass
{
    if([plugInClass isSubclassOfClass:self.pluginClass])
    {
        return YES;
    }
	
    return NO;
}

/*
 
 plugin with class name
 
 */
- (id)pluginWithClassName:(NSString *)className
{
	for (id plugin in _instances) {
		if ([[plugin className] isEqual:className]) {
			return plugin;
		}
	}
	
	return nil;
}


/*
 
 default plugin name
 
 subclass whould override
 
 */
- (NSString *)defaultPluginName
{
	return @"";
}

/*
 
 default plugin 

 
 */
- (id)defaultPlugin
{
	return [self pluginWithClassName:[self defaultPluginName]];
}
/*
 
 load all plugins.
 
 This method scans all application plgin support directories for pluglins.
 It then loads them and validates them against the plugin class.
 
 Validated instances of our plugin class are asssigned to the _instances NSArray.
 
 */
- (void)loadAllPlugins
{
	// one shot 
	if (self.instances) {
		MLogInfo(@"plugins already loaded");
		return;
	}
	
	NSMutableArray *plugins = [[NSMutableArray alloc] init];
	
    NSMutableArray *bundlePaths;
    NSEnumerator *pathEnum;
    NSString *currPath;
    NSBundle *currBundle;
    Class currPrincipalClass;
    id currInstance;
	
    bundlePaths = [NSMutableArray array];	
    [bundlePaths addObjectsFromArray:[self allBundles]];
	
    pathEnum = [bundlePaths objectEnumerator];
    while((currPath = [pathEnum nextObject]))
    {
		currBundle = nil;
		
		// create bundle
        currBundle = [NSBundle bundleWithPath:currPath];
		
		// NSLog(@"bundleWithPath: %@", currPath);
        
		if (currBundle) {
			currPrincipalClass = nil;
			
			// extract principle class (this will trigger loading)
            currPrincipalClass = [currBundle principalClass];
			
			// validate that the principle class is valid
            if (currPrincipalClass && [self plugInClassIsValid:currPrincipalClass])  
            {
				// instantiate an instance of our plug in.
                currInstance = [[currPrincipalClass alloc] init];
                if (currInstance) {
                    [plugins addObject:currInstance];
                }
				
				// if a selector is defined to allow access other 
				// plugins from the same bundle then do so
				SEL otherPluginsSel = [[self class] pluginsSelector];
				if (otherPluginsSel != NULL && [currInstance respondsToSelector:otherPluginsSel]) {
					
					// get an array of other plugins
					NSArray *otherPlugins = [currInstance performSelector:otherPluginsSel];
					if (![otherPlugins isKindOfClass:[NSArray class]]) { continue; }
					
					// validate other plugins
					for (id otherPlugin in otherPlugins) {
						if ([self plugInClassIsValid:[otherPlugin class]]) {
							[plugins addObject:otherPlugin];
						} else {
							MLogInfo(@"bad plugin Class found");
						}
					}
				}
            }
        }
    }
	self.instances = [NSArray arrayWithArray:plugins];
	
	[self allPluginsLoaded];
}

/*
 
 - allPluginsLoaded
 
 */
- (void)allPluginsLoaded
{
}

/*
 
 form array of bundle paths
 
 */
- (NSMutableArray *)allBundles
{
    NSArray *librarySearchPaths;
    NSEnumerator *searchPathEnum;
    NSString *currPath;
    NSMutableArray *bundleSearchPaths = [NSMutableArray array];
    NSMutableArray *allBundles = [NSMutableArray array];
	
	/*
	 
	 add library search paths
	 
	 */
    librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
	
    searchPathEnum = [librarySearchPaths objectEnumerator];
    while((currPath = [searchPathEnum nextObject]))
    {
        [bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:appSupportSubpath]];
    }
	
	// add bundle plugins path
    [bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];
	
	// add additional search paths
	[bundleSearchPaths addObjectsFromArray:_additionalSearchPaths];
	
	// look for plugin bundles
    searchPathEnum = [bundleSearchPaths objectEnumerator];
    while((currPath = [searchPathEnum nextObject]))
    {
         NSDirectoryEnumerator *bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:currPath];
        if (bundleEnum)
        {
			NSString *currBundlePath = nil;
            while ((currBundlePath = [bundleEnum nextObject]))
            {
                if([[currBundlePath pathExtension] isEqualToString:[[self class] bundleExtension]])
                {
					[allBundles addObject:[currPath stringByAppendingPathComponent:currBundlePath]];
                }
            }
        }
    }
	
    return allBundles;
}

/*
 
 - addAdditionalSearchPaths:
 
 */
- (void)addAdditionalSearchPaths:(NSArray *)paths
{
	[_additionalSearchPaths addObjectsFromArray:paths];
}

@end

