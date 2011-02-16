//
//  MGSLanguageTemplateResourcesManager.m
//  KosmicTask
//
//  Created by Jonathan on 15/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguageTemplateResourcesManager.h"
#import "MGSPath.h"
#import "mlog.h"

// class extension
@interface MGSLanguageTemplateResourcesManager()
- (NSString *)templateBundlePath;
- (NSString *)templateFileName; 
@end

@implementation MGSLanguageTemplateResourcesManager

#pragma mark -
#pragma mark Resource nodes

/*
 
 - resourceTitle
 
 */
- (NSString *)resourceTitle
{
	return @"Template";
}

/*
 
 - nodeName
 
 */
- (NSString *)nodeName
{
	return @"Templates";
}


/*
 
 - resourceClass
 
 */
- (Class)resourceClass
{
	return [MGSLanguageTemplateResource class];
}

/*
 
 - defaultNodeImage
 
 */
- (NSImage *)defaultNodeImage
{
	return [[[MGSImageManager sharedManager] script] copy];
}


#pragma mark -
#pragma mark Name
/*
 
 - defaultTemplateName:
 
 */
- (NSString *)defaultTemplateName
{
	NSString *name = nil;
	
	NSNumber *fileNumber = [self defaultResourceID];
	for (MGSLanguageTemplateResource *template in self.resources) {
		if ([template.ID isEqualTo:fileNumber]) {
			name = template.name;
		}
	}
	
	
	if (!name) {
		if ([self.resources count] > 0) {
			name = [[self.resources objectAtIndex:0] name];
		}
	}
	
	return name;
}

#pragma mark -
#pragma mark Path


/*
 
 - templateBundlePath
 
 */
- (NSString *)templateBundlePath
{
	
	// Get path to template.
	NSString *templatePath = [[NSBundle bundleForClass:[self class]] pathForResource:[self templateFileName] ofType:@"template.txt"];
	
	return templatePath;
}

/*
 
 - templateFile
 
 */
- (NSString *)templateFileName
{	
	return @"1";	
}

@end
