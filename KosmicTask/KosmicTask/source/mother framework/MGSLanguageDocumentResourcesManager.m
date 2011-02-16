//
//  MGSLanguageInfoResourcesManager.m
//  KosmicTask
//
//  Created by Jonathan on 15/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguageDocumentResourcesManager.h"
#import "mlog.h"

@implementation MGSLanguageDocumentResourcesManager

#pragma mark -
#pragma mark Resource nodes

/*
 
 - resourceTitle
 
 */
- (NSString *)resourceTitle
{
	return @"Document";
}

/*
 
 - nodeName
 
 */
- (NSString *)nodeName
{
	return @"Documents";
}

/*
 
 - resourceClass
 
 */
- (Class)resourceClass
{
	return [MGSLanguageDocumentResource class];
}

/*
 
 - defaultNodeImage
 
 */
- (NSImage *)defaultNodeImage
{
	return [[[MGSImageManager sharedManager] documentTemplate] copy];
}

@end
