//
//  MGSLanguageInfoResource.m
//  KosmicTask
//
//  Created by Jonathan on 17/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguageDocumentResource.h"
#import "MGSResourceBrowserNode.h"

@implementation MGSLanguageDocumentResource

//@synthesize attributedText, rtfData;

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
	return @"Document";
}

/*
 
 - persistResourceType:
 
 */
- (BOOL)persistResourceType:(MGSResourceItemFileType)fileType
{
	
	switch (fileType) {
		case MGSResourceItemTextFile:;
			return NO;
			break;
			
		case MGSResourceItemRTFDFile:
		case MGSResourceItemMarkdownFile:;
			return YES;
			break;
			
		default:
			break;
	}
	
	return NO;
}

@end
