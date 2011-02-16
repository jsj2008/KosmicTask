//
//  MGSUserLanguageResourcesManager.m
//  KosmicTask
//
//  Created by Jonathan on 30/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSUserLanguageResourcesManager.h"


@implementation MGSUserLanguageResourcesManager

/*
 
 - resourceTitle
 
 */
- (NSString *)resourceTitle
{
	return @"User";
}

/*
 
 - nodeName
 
 */
- (NSString *)nodeName
{
	return @"User";
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
	self.templateManager.canMutate = YES;
	self.documentManager.canMutate = YES;
}	


@end

