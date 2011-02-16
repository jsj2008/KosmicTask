//
//  MGSLanguagePropertiesResourcesManager.m
//  KosmicTask
//
//  Created by Jonathan on 31/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguagePropertiesResourcesManager.h"
#import "MGSLanguagePropertiesResource.h"

@implementation MGSLanguagePropertiesResourcesManager

#pragma mark -
#pragma mark Resource nodes

/*
 
 - resourceTitle
 
 */
- (NSString *)resourceTitle
{
	return @"Settings";
}

/*
 
 - nodeName
 
 */
- (NSString *)nodeName
{
	return @"Settings";
}

/*
 
 - resourceClass
 
 */
- (Class)resourceClass
{
	return [MGSLanguagePropertiesResource class];
}

/*
 
 - defaultNodeImage
 
 */
- (NSImage *)defaultNodeImage
{
	return [[[MGSImageManager sharedManager] pinMeTemplate] copy];
}

@end
