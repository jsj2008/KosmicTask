//
//  MGSApplicationLanguageResourcesManager.m
//  KosmicTask
//
//  Created by Jonathan on 30/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSApplicationLanguageResourcesManager.h"
#import "MGSPreferences.h"

@implementation MGSApplicationLanguageResourcesManager

@synthesize settingsManager;

/*
 
 - resourceTitle
 
 */
- (NSString *)resourceTitle
{
	return @"Application";
}

/*
 
 - nodeName
 
 */
- (NSString *)nodeName
{
	return @"Application";
}

/*
 
 - defaultNodeImage
 
 */
- (NSImage *)defaultNodeImage
{
	return [self originImage];
}

/*
 
 - createResourceManagers
 
 */
- (void)createResourcesManagers
{
	[super createResourcesManagers];

	// create properties resource managers
	settingsManager = [[MGSLanguagePropertiesResourcesManager alloc] 
					   initWithPath:self.managerPath 
					   name:self.resourceName
					   folder:@"Settings"];
	
	settingsManager.delegate = self;
	[self.resourcesManagers addObject:settingsManager];
	
	// normally we cannot mutate the application resources manager
	// but in the development environment it is convenient to be able to do so 
	BOOL pref = [[NSUserDefaults standardUserDefaults] boolForKey:MGSAllowEditApplicationResources];
	self.templateManager.canMutate = pref;
	self.documentManager.canMutate = pref;
}	
@end
