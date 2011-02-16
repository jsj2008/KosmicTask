/*
 *  MGSKosmicTaskQuicklook.m
 *  KosmicTask Quick Look Plugin
 *
 *  Created by Jonathan on 10/10/2009.
 *  Copyright 2009 mugginsoft.com. All rights reserved.
 *
 */

#include "MGSKosmicTaskQuicklook.h"

/*
 
 get script RTF for URL
 
 */
NSData *GetScriptRTFForURL(NSURL *url)
{
	// load the script dictionary
	NSDictionary *script = [NSDictionary dictionaryWithContentsOfURL:url];
	if (!script) {
		NSLog(@"Could not load task dictionary", nil);
		return nil;
	}
	
	// get source rtf data
	NSData *rtf = [script valueForKeyPath:@"Code.SourceRTFData"];
	if (!rtf) {
		NSLog(@"Could not load task rtf", nil);
		return nil;
	}
	
	// get other properties
	NSString *name = [script valueForKey:@"Name"];
	NSString *description = [script valueForKey:@"Description"];
	NSString *author = [script valueForKey:@"Author"];
	NSString *type = [script valueForKey:@"ScriptType"];
	NSString *origin = [script valueForKey:@"Origin"];
	
	// form header
	NSString *fmt = @"%@: \t%@\n";
	NSString *fmt2 = @"%@: \t\t%@\n";
	NSString *fmt3 = @"%@: \t\t\t%@\n";
	NSMutableString *prefix = [NSMutableString stringWithFormat:fmt3, @"Name", name];
	[prefix appendFormat:fmt, @"Description", description];
	[prefix appendFormat:fmt, @"ScriptType", type];
	[prefix appendFormat:fmt2, @"Author", author];
	[prefix appendFormat:fmt2, @"Origin", origin];
	[prefix appendString:@"\n"];
	
	// form final RTF data representation
	NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:prefix] autorelease];
	NSAttributedString *rtfString = [[[NSAttributedString alloc] initWithRTF:rtf documentAttributes:NULL] autorelease];
	[attrString appendAttributedString:rtfString];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont fontWithName:@"Menlo" size: 11], NSFontAttributeName, nil];
	[attrString addAttributes:attributes range:NSMakeRange(0, [attrString length])];
	return [attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:nil];
}
