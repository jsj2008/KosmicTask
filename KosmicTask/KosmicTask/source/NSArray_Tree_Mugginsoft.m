//
//  NSArray_Tree_Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 22/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "NSArray_Tree_Mugginsoft.h"
#import "NSArray_Mugginsoft.h"
#import "MGSResultFormat.h"
#import "MGSTaskSpecifier.h"
#import "MGSImageManager.h"
#import "MGSError.h"
#import "MGSScript.h"
#import "MGSKeyImageAndText.h"
#import "MGSNetAttachments.h"
#import "NSString_Mugginsoft.h"
#import "MLog.h"

@implementation NSArray(NSArray_Tree_Mugginsoft)

/*
 
 array tree with object
 
 */
+ (NSArray *)arrayTreeWithObject:(id)object
{
	return [self addToArrayTree:object withParent:nil];
}

/*
 
 add object to tree with given parent
 
 */
+ (NSArray *)addToArrayTree:(id)resultObject withParent:(NSTreeNode *)parentNode
{
	// make object into a dictionary
	NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithCapacity:2];
	NSString *resultString = NSLocalizedString(@"Result", @"Result");
	
	// simple result
	if ([resultObject isKindOfClass:[NSString class]] || [resultObject isKindOfClass:[NSNumber class]]) {
		[resultDict setObject:resultObject forKey:resultString];
	}
	
	// array
	else if ([resultObject isKindOfClass:[NSArray class]]) {
		int i = 1;
		for (id item in resultObject) {
			[resultDict setObject:item forKey:[NSNumber numberWithInt:i++]];
		}
	}
	
	// dictionary
	else if ([resultObject isKindOfClass:[NSDictionary class]]) {
		resultDict = resultObject;
	}
	
	// MGSError
	else if ([resultObject isKindOfClass:[MGSError class]]) {
		resultDict = [NSMutableDictionary dictionaryWithDictionary:[(MGSError *)resultObject resultDictionary]];
	}
	
	// default result
	else  {
		NSString *format = NSLocalizedString(@"Cannot display result of type %@", @"Cannot display result");
		[resultDict setObject:[NSString stringWithFormat:format, [resultObject className]] forKey:resultString];
	}
	
	// form tree array from dictionary
	NSMutableArray *treeArray = [NSMutableArray arrayWithCapacity:2];
	NSArray *dictKeys = [resultDict allKeys];
	dictKeys = [dictKeys mgs_sortedArrayUsingBestSelector];
	
	for (id key in dictKeys) {
		
		// apply depth zero key filter.
		// this prevents display of application specific keys such as KosmicTask and KosmicFile
		if (!parentNode && [key isKindOfClass:[NSString class]]) {
			
			// get the filter
			NSArray *keyFilter = [MGSResultFormat fileDataKeys];
			BOOL filterMatched = NO;
			
			// apply filter
			for (NSString *filterItem in keyFilter) {
				if ([(NSString *)key caseInsensitiveCompare:filterItem] == NSOrderedSame) {
					filterMatched = YES;
					break;
				}
			}
			
			// if filter matched then don't output this object
			if (filterMatched) {
				continue;
			}
		}
		
		id dictObject = [resultDict objectForKey:key];
		
		// form object to be represented by tree node
		MGSKeyImageAndText *keyObject = [[MGSKeyImageAndText alloc] init];
		keyObject.key = key;
		keyObject.value = dictObject;
		
		// set the indentation level
		NSInteger indentation = 0;
		if (parentNode) {
			indentation = 1 + [[parentNode representedObject] indentation];
		}
		keyObject.indentation = indentation;
		
		// form tree node
		NSTreeNode *node = [NSTreeNode treeNodeWithRepresentedObject:keyObject];
		
		// if our object is an array or a dictionary then add contents as child nodes
		if ([dictObject isKindOfClass:[NSArray class]] || [dictObject isKindOfClass:[NSDictionary class]]) {
			
			keyObject.count = [dictObject count];
			keyObject.hasCount = YES;
			keyObject.image = [[[MGSImageManager sharedManager] dotTemplate] copy];
			keyObject.countAlignment = MGSAlignRight;
			
			// create marker text for our group node
			NSFont *font = [NSFont controlContentFontOfSize:9.0f];
			NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,  NSFontAttributeName,
											 [NSColor colorWithCalibratedRed:0.545f green:0.004f blue:0.082f alpha:1.0f], NSForegroundColorAttributeName
											 , nil];
			keyObject.value = [[NSMutableAttributedString alloc] 
							   initWithString:NSLocalizedString(@"List", @"Result list") 
							   attributes:attrsDictionary];
			// add it
			[self addToArrayTree:dictObject withParent:node];
		}
		
		// if parent defined then add as child node
		if (parentNode) {
			[[parentNode mutableChildNodes] addObject:node];
		} else {
			// add to array of root nodes
			[treeArray addObject:node];
		}
	}
	
	return treeArray;
}

@end




