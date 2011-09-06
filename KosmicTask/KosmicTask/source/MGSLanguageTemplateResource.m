//
//  MGSLanguageTemplateResource.m
//  KosmicTask
//
//  Created by Jonathan on 14/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguageTemplateResource.h"
#import "MGSResourceBrowserNode.h"
#import "MGSTemplateEngine/ICUTemplateMatcher.h"

// class extension
@interface MGSLanguageTemplateResource()
@end

@implementation MGSLanguageTemplateResource


#pragma mark -
#pragma mark Class methods
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
	return @"Template";
}

/*
 
 + canDefaultResource
 
 */
+ (BOOL)canDefaultResource
{
	return YES;
}

#pragma mark -
#pragma mark Instance methods
/*
 
 - persistResourceType:
 
 */
- (BOOL)persistResourceType:(MGSResourceItemFileType)fileType
{
	
	switch (fileType) {
		case MGSResourceItemTextFile:
		case MGSResourceItemRTFDFile:
		case MGSResourceItemMarkdownFile:
		case MGSResourceItemPlistFile:
			return YES;
			break;
			
		default:
			break;
	}
	
	return NO;
}


#pragma mark -
#pragma mark MGTemplateEngineDelegate

/*
 
 - templateEngine:blockStarted:
 
 */
- (void)templateEngine:(MGTemplateEngine *)engine blockStarted:(NSDictionary *)blockInfo
{
#pragma unused(engine)
#pragma unused(blockInfo)
	
	//NSLog(@"Started block %@", [blockInfo objectForKey:BLOCK_NAME_KEY]);
}

/*
 
 - templateEngine:blockEnded:
 
 */
- (void)templateEngine:(MGTemplateEngine *)engine blockEnded:(NSDictionary *)blockInfo
{
#pragma unused(engine)
#pragma unused(blockInfo)
	
	//NSLog(@"Ended block %@", [blockInfo objectForKey:BLOCK_NAME_KEY]);
}

/*
 
 - templateEngineFinishedProcessingTemplate:
 
 */
- (void)templateEngineFinishedProcessingTemplate:(MGTemplateEngine *)engine
{
#pragma unused(engine)
	
	//NSLog(@"Finished processing template.");
}

/*
 
 - templateEngine:encounteredError:isContinuing:
 
 */
- (void)templateEngine:(MGTemplateEngine *)engine encounteredError:(NSError *)error isContinuing:(BOOL)continuing;
{
#pragma unused(engine)
#pragma unused(continuing)
	
	NSLog(@"Template error: %@", error);
}


#pragma mark -
#pragma mark String resource

/*
 
 - stringResourceWithVariables:
 
 */
- (NSString *)stringResourceWithVariables:(NSDictionary *)variables
{
	MGTemplateEngine *engine = [MGTemplateEngine templateEngine];
	[engine setDelegate:self];
	[engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
	
	// Process the template and display the results.
	NSString *result = [engine processTemplate:[self stringResource] withVariables:variables];
	
	return result;	
}

#pragma mark -
#pragma mark Script

/*
 
 - scriptTemplate:withInsertion:
 
 */
- (NSString *)scriptTemplate:(MGSScript *)script withInsertion:(NSString *)insertion
{
#pragma unused(insertion)
#pragma unused(script)
	
	/*
	 // Set up some variables for this specific template.
	 NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys: [script author], @"author", nil];
	 
	 NSString *template = [self loadResourceFileWithName:script.templateName variables:variables];
	 if (!template) {
	 NSString *fmt = NSLocalizedString(@"Template \"%@\" not found", @"Script template not found");
	 template = [NSString stringWithFormat:fmt, script.templateName];
	 }
	 
	 return template;
	 */
	
	return @"";
}

/*
 
 - scriptSubroutineTemplate:
 
 */
- (NSString *)scriptSubroutineTemplate:(MGSScript *)script 
{
#pragma unused(script)
	
	return @"";
}

@end
