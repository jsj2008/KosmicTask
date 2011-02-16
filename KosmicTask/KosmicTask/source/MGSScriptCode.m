//
//  MGSScriptCode.m
//  Mother
//
//  Created by Jonathan on 11/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSScriptCode.h" 
#import "MGSScriptPlist.h"

@implementation MGSScriptCode

/* 
 
 set dictionary
 
 */
- (void)setDict:(NSMutableDictionary *)dict
{
	// point to the code dict
	NSMutableDictionary *codeDict = [dict objectForKey:MGSScriptKeyCode];
	if (nil == codeDict) {
		codeDict = [NSMutableDictionary dictionaryWithCapacity:2];
		[dict setObject:codeDict forKey:MGSScriptKeyCode];
	}
	[super setDict: codeDict];
}

/*
 
 - rtfSource
 
 */
- (NSData *)rtfSource
{
	return [self objectForKey:MGSScriptKeySourceRTFData];
}

/*
 
 - setRtfSource
 
 source is ONLY persisted in the script as RTF.
 other representations are derived from this.
 
 */
- (void)setRtfSource:(NSData *)data
{
	// set RTF
	[self setObject:data forKey:MGSScriptKeySourceRTFData];	
}

/*
 
 - source 
 
 */
- (NSString *)source
{
	NSString *source = nil;
	NSAttributedString *attributedSource = [self attributedSource];
	if (attributedSource) {
		source = [attributedSource string];
	} else {
		
		// some representations may feature a transient source
		source = [self objectForKey:MGSScriptKeySource];
	}
	
	return source;
}

/*
 
 - setSource: 
 
 */
- (void)setSource:(NSString *)theSource
{
	NSAttributedString *attributedSource = nil;
	if (theSource) {
		attributedSource = [[NSAttributedString alloc] initWithString:theSource];
	}
	
	[self setAttributedSource:attributedSource];
}

/*
 
 - sourceData
 
 */
- (NSData *)sourceData
{
	NSString *source = [self source];
	return [source dataUsingEncoding:NSUTF8StringEncoding];
}

/*
 
 - attributedSource 
 
 */
- (NSAttributedString *)attributedSource
{
	NSAttributedString *attributedSource = nil;
	NSData *data = [self rtfSource];
	if (data) {
		attributedSource = [[NSAttributedString alloc] initWithRTF:data documentAttributes:nil];
	}
	
	return attributedSource;
}
/*
 
 - setAttributedSource: 
 
 */
- (void)setAttributedSource:(NSAttributedString *)attributedSource
{
	NSData * rtfSource = nil;
	if (attributedSource) {
		NSRange fullRange = NSMakeRange(0, [attributedSource length]);
		rtfSource = [attributedSource RTFFromRange:fullRange documentAttributes:nil];
		
	}
	[self setRtfSource:rtfSource];
}
		 
/*
 
 - compiledData
 
 */
- (NSData *)compiledData
{
	return [self objectForKey:MGSScriptKeyCompiled];
}

/*
 
 setCompiledData:withFormat:
 
 */
- (void)setCompiledData:(NSData *)data withFormat:(NSString *)format
{
	if (!format) {
		format = MGSScriptDataFormatRaw;
	}
	
	[self setObject:data forKey:MGSScriptKeyCompiled];
	[self setObject:format forKey:MGSScriptKeyCompiledFormat];
}

/*
 
 - compiledDataFormat
 
 */
- (NSString *)compiledDataFormat
{
	return [self objectForKey:MGSScriptKeyCompiledFormat];
}

/*
 
 - mutableCopyWithZone:
 
 */
- (id)mutableCopyWithZone:(NSZone *)zone
{
	id aCopy = [super mutableCopyWithZone:zone];
	
	// copy local instance variables here
	
	return aCopy;
}

/*
 
 - mutableDeepCopy
 
 */
- (id)mutableDeepCopy
{
	id aCopy = [super mutableDeepCopy];
	
	// copy local instance variables here
	
	return aCopy;
}

#pragma mark Representation

/*
 
 - setRepresentation:
 
 */
- (void)setRepresentation:(MGSScriptCodeRepresentation)value
{
	switch (value) {
		case MGSScriptCodeRepresentationUndefined:
		case MGSScriptCodeRepresentationStandard:
		case MGSScriptCodeRepresentationBuild:
		case MGSScriptCodeRepresentationSave:
			
			break;
			
		default:
			NSAssert(NO, @"invalid script representation");
	}
	
	[self setInteger:value forKey:MGSScriptKeyRepresentation];
}

/*
 
 - representation
 
 */
- (MGSScriptCodeRepresentation)representation
{
	return [self integerForKey:MGSScriptKeyRepresentation];
}

/*
 
 - conformToRepresentation:
 
 */
- (BOOL)conformToRepresentation:(MGSScriptCodeRepresentation)representation
{
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], @"conform",
							 nil];
	
	return [self conformToRepresentation:representation options:options];
}

/*
 
 - conformToRepresentation:options:
 
 */
- (BOOL)conformToRepresentation:(MGSScriptCodeRepresentation)representation options:(NSDictionary *)options
{
	BOOL success = YES;
	BOOL conform = [[options objectForKey:@"conform"] boolValue];
	
	// we can only conform to a representation that contains fewer
	// dictionary keys then we have presently
	switch ([self representation]) {
			
			// complete representation
		case MGSScriptCodeRepresentationStandard:
			
			switch (representation) {
					
					// we are here already
				case MGSScriptCodeRepresentationStandard:
					break;
					
					/*
					 
					 build a compile representation.
					 this discards the RTF data.
					 
					 */
				case MGSScriptCodeRepresentationBuild:
					if (conform) {
					
						// add source
						[self setObject:[self source] forKey:MGSScriptKeySource];
						
						// remove unwanted fields
						[self setCompiledData:nil withFormat:nil];
						[self setSource:nil];
					}
					
					break;
	
				case MGSScriptCodeRepresentationSave:
					if (conform) {
						[self removeObjectForKey: MGSScriptKeySource];	// ephemeral
					}
					break;
					
				default:
					success =  NO;
					break;
			}
			
			break;
			
		default:
			success =  NO;
			break;
			
	}

	if (conform) {

		if (success) {
			[self setRepresentation:representation];
		} else {
			MLogInfo(@"cannot conform to representation");
		}
	}

	
	return success;
}

@end
