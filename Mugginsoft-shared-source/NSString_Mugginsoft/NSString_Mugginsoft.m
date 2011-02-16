//
//  NSString_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 29/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSString_Mugginsoft.h"

@implementation NSString (Mugginsoft)

/*
 
 string with new UUID
 
 */
+ (NSString*) stringWithNewUUID
{
	//create a new UUID
	CFUUIDRef	uuidObj = CFUUIDCreate(nil);
	//get the string representation of the UUID
	NSString	*newUUID = (NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	return newUUID;
}

/*
 
 string with created temp file path
 
 */
+ (NSString *)stringWithCreatedTempFilePathSuffix:(NSString *)suffix
{
	if (!suffix) {
		suffix = @"";
	}
	
	// create template
	NSString *template = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [@"XXXXXXXXXX" stringByAppendingString:suffix]];
	char *buffer = (char *)[template fileSystemRepresentation];
	if (buffer == NULL) {
		NSLog(@"Cannot get representation of  temp file: %@", template);
		return nil;
	}
	
	// create the file
	int fd = mkstemps(buffer, [suffix length]);
	if (fd == -1) {
		NSLog(@"Cannot create temp file: %s", buffer);
		return nil;
	}
	close(fd);
	
	NSString *path = [NSString stringWithFormat:@"%s", buffer];
	return path;
	
}

/*
 
 is temp file path containing substring
 
 */
- (BOOL)isTempFilePathContaining:(NSString *)subString
{
	if (!subString) return NO;
	
	NSRange r = [self rangeOfString:NSTemporaryDirectory() options:NSCaseInsensitiveSearch];
	if (r.location == NSNotFound && r.length == 0) return NO;
	
	[self rangeOfString:subString options:NSCaseInsensitiveSearch];
	if (r.location == NSNotFound && r.length == 0) return NO;

	return YES;
}

/*
 
 string with created temp file path
 
 */
+ (NSString *)stringWithCreatedTempFilePath
{
	return [self stringWithCreatedTempFilePathSuffix:@""];
}

/*
 
 string from file size
 
 */
+ (NSString *)stringFromFileSize:(unsigned long long)theSize
{
	double floatSize = (double)theSize;
	
	if (theSize < 1023)
			return([NSString stringWithFormat:@"%1.0f bytes",floatSize]);
	
	floatSize = floatSize / 1024;
	if (floatSize<1023)
			return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
	
	floatSize = floatSize / 1024;
	if (floatSize<1023)
			return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
	
	floatSize = floatSize / 1024;
  
	// Add as many as you like
  
	return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}

/*
 
 string cr and lf removed
 
 */
- (NSString *)stringWithOccurrencesOfCrLfRemoved
{
	NSString *stringValue = [self stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	return [stringValue stringByReplacingOccurrencesOfString:@"\r" withString:@""];
}

/*
 
 string terminated with period
 
 */
- (NSString *)stringTerminatedWithPeriod
{
	NSString *lastChar = [self substringFromIndex:[self length]-1];
	if ([lastChar compare:@"."] != NSOrderedSame) {
		return [NSString stringWithFormat: @"%@.", self];
	}
	
	return self;
}

/*
 
 string in camel case
 
 based on code from http://rentzsch.com
 
 */
- (NSString*)camelCaseString {
	NSArray *lowerCasedWordArray = [[self lowercaseString] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	unsigned wordCount = [lowerCasedWordArray count];
	NSMutableArray *camelCasedWordArray = [NSMutableArray arrayWithCapacity:wordCount];
	if (wordCount > 0) {
		[camelCasedWordArray addObject:[lowerCasedWordArray objectAtIndex:0]];
	}
	
	for (NSUInteger wordIndex = 1; wordIndex < wordCount; wordIndex++) {
		NSString *word = [lowerCasedWordArray objectAtIndex:wordIndex];
		if ([word length] > 0) {
			[camelCasedWordArray addObject:[word capitalizedString]];
		}
	}
	return [camelCasedWordArray componentsJoinedByString:@""];
}

/*
 
 is UUID
 
 see http://www.stiefels.net/2007/01/24/regular-expressions-for-nsstring/
 
 */
- (BOOL)isUUID
{
	// see http://www.geekzilla.co.uk/View8AD536EF-BC0D-427F-9F15-3A1BC663848E.htm
	//NSString *regex = @"^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$";
	NSString *regex = @"^(([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12})$";
	
	// supported non standard regex format is at http://www.icu-project.org/userguide/regexp.html
	NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	return [regextest evaluateWithObject:self];
}
@end
