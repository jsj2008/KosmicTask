//
//  MGSLanguagePropertiesResource.m
//  KosmicTask
//
//  Created by Jonathan on 31/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguagePropertiesResource.h"


@implementation MGSLanguagePropertiesResource

/*
 
 + initialize
 
 */

+ (void)initialize
{
	
	// register subclass with the language node
	[MGSResourceBrowserNode registerClass:self
								  options:[NSDictionary dictionaryWithObjectsAndKeys:@"info", @"description", nil]];
	
}

/*
 
 - title
 
 */
+ (NSString *)title
{
	return @"Settings";
}

/*
 
 - persistResourceType:
 
 */
- (BOOL)persistResourceType:(MGSResourceItemFileType)fileType
{
	
	switch (fileType) {
		case MGSResourceItemPlistFile:;
			return YES;
			break;
			
		default:
			break;
	}
	
	return NO;
}

@end
