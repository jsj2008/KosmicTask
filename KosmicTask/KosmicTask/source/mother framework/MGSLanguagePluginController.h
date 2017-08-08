//
//  MGSLanguagePluginController.h
//  KosmicTask
//
//  Created by Jonathan on 26/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSPluginController.h"
#import "MGSLanguagePlugin.h"

@interface MGSLanguagePluginController : MGSPluginController {
	NSMutableArray *__strong scriptTypes;
	BOOL resourcesLoaded;
}

@property (strong, readonly) NSArray * scriptTypes;
@property BOOL resourcesLoaded;

+ (id)sharedController;
+ (NSString *)applicationLanguageResourcesPath;
+ (NSString *)userLanguageResourcesPath;

- (MGSLanguagePlugin *)pluginWithScriptType:(NSString *)scriptType;

- (void)setDefaultScriptType:(NSString *)scriptType;
- (NSString *)defaultScriptType;
- (void)loadPluginResources;
- (void)resolvePluginResources;
- (void)savePluginSettings;
- (MGSLanguagePlugin *)pluginForSourceFileExtension:(NSString *)extension;
@end
