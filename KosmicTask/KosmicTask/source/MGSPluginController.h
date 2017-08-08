//
//  MGSPluginController.h
//  Mother
//
//  Created by Jonathan on 19/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSPluginController : NSObject {
	//Class _pluginClass;
	NSArray *_instances;
	NSMutableArray *_additionalSearchPaths;
}


// base class for our plugin
@property (strong) Class pluginClass;

// array of plugin instances
@property (readonly) NSArray *instances;

+ (Class)plugInClass;

+ (NSString *)bundleExtension;
+ (SEL)pluginsSelector;

// validate the class
- (BOOL)plugInClassIsValid:(Class)plugInClass;

// load all plugins
- (void)loadAllPlugins;
- (void)allPluginsLoaded;

// form array of bundle names
- (NSMutableArray *)allBundles;

- (id)pluginWithClassName:(NSString *)className;

- (NSString *)defaultPluginName;

- (id)defaultPlugin;

- (void)addAdditionalSearchPaths:(NSArray *)paths;
@end
