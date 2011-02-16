//
//  MGSLanguageResourcesManager.m
//  KosmicTask
//
//  Created by Jonathan on 28/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguageResourcesManager.h"
#import "MGSPath.h"
#import "mlog.h"

// class extension
@interface MGSLanguageResourcesManager()
@end

@implementation MGSLanguageResourcesManager

@synthesize templateManager, documentManager;


#pragma mark -
#pragma mark Initialisation


#pragma mark Load

/*
 
 - createResourceManagers
 
 */
- (void)createResourcesManagers
{
	[super createResourcesManagers];
	
	// create child resource managers
	templateManager = [[MGSLanguageTemplateResourcesManager alloc] 
					   initWithPath:self.managerPath 
					   name:self.resourceName
					   folder:@"Templates"];
	templateManager.delegate = self;
	
	documentManager = [[MGSLanguageDocumentResourcesManager alloc] 
					   initWithPath:self.managerPath 
					   name:self.resourceName
					   folder:@"Documents"];
	documentManager.delegate = self;
	
	// add to resources managers
	[self.resourcesManagers addObject:templateManager];
	[self.resourcesManagers addObject:documentManager];
	
}


#pragma mark -
#pragma mark Resource nodes

@end
