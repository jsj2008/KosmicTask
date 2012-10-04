//
//  NSString_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 29/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSString_Mugginsoft.h"
#import "MGSTempStorage.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

/*
 
 all external class category methods should have name space prefix to guard
 against collisions
 
 also see runtime env var OBJC_PRINT_REPLACED_METHODS
 
 */
@implementation NSString (Mugginsoft)


/*
 
 code called by both garbage collected and ref counting environments
 
 running the clang static analyzer is the best way of finding memory leaks 
 in both GC and ref counting environments
 
 
 string with new UUID
 
 */
+ (NSString *)mgs_stringWithNewUUID
{
	//create a new UUID
	CFUUIDRef	uuidObj = CFUUIDCreate(nil);
	//get the string representation of the UUID
	NSString	*newUUID = NSMakeCollectable(CFUUIDCreateString(nil, uuidObj));	// GC env happy
	CFRelease(uuidObj);
	
	return [newUUID autorelease];	// ref count env happy
}

/*
 
 - mgs_occurrencesOfString:
 
 */
- (NSUInteger)mgs_occurrencesOfString:(NSString *)aString
{
	NSUInteger count = 0, len = [self length];
	NSRange range = NSMakeRange(0, len); 
	
	while(range.location != NSNotFound)
	{
		range = [self rangeOfString:aString options:0 range:range];
		if(range.location != NSNotFound)
		{
			range = NSMakeRange(range.location + range.length, len - (range.location + range.length));
			count++; 
		}
	}
	return count;
}

/*
 
 string with created temp file path
 
 */
+ (NSString *)mgs_stringWithCreatedTempFilePathSuffix:(NSString *)suffix
{
	if (!suffix) {
		suffix = @"";
	}
	
	return [[MGSTempStorage sharedController] storageFileWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
												suffix, MGSTempFileSuffix,
												nil]];
}

/*
 
 is temp file path containing substring
 
 */
- (BOOL)mgs_isTempFilePathContaining:(NSString *)subString
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
+ (NSString *)mgs_stringWithCreatedTempFilePath
{
	return [self mgs_stringWithCreatedTempFilePathSuffix:@""];
}

/*
 
 string from file size
 
 */
+ (NSString *)mgs_stringFromFileSize:(unsigned long long)theSize
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
- (NSString *)mgs_stringWithOccurrencesOfCrLfRemoved
{
	NSString *stringValue = [self stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	return [stringValue stringByReplacingOccurrencesOfString:@"\r" withString:@""];
}

/*
 
 string terminated with period
 
 */
- (NSString *)mgs_stringTerminatedWithPeriod
{
	if ([self length] > 0) {

		NSString *lastChar = [self substringFromIndex:[self length]-1];
		if ([lastChar compare:@"."] != NSOrderedSame) {
			return [NSString stringWithFormat: @"%@.", self];
		}
	}
	
	return self;
}

/*
 
 string in camel case
 
 based on code from http://rentzsch.com
 
 */
- (NSString*)mgs_camelCaseString {
	NSArray *lowerCasedWordArray = [[self lowercaseString] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSUInteger wordCount = [lowerCasedWordArray count];
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
- (BOOL)mgs_isUUID
{
	// see http://www.geekzilla.co.uk/View8AD536EF-BC0D-427F-9F15-3A1BC663848E.htm
	//NSString *regex = @"^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$";
	NSString *regex = @"^(([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12})$";
	
	// supported non standard regex format is at http://www.icu-project.org/userguide/regexp.html
	NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	return [regextest evaluateWithObject:self];
}

/*
 
 - mgs_isURL
 
 */
- (BOOL)mgs_isURL
{
    // http://stackoverflow.com/questions/8249420/alter-regex-to-allow-ip-address-when-checking-url
	NSString *regex = @"/^(http(s?):\\/\\/)?(www\\.)?+[a-zA-Z0-9\\.\\-\\_]+(\\.[a-zA-Z]{2,20})+(\\/[a-zA-Z0-9\\_\\-\\s\\.\\/\\?\\%\\#\\&\\=]*)?$/i";
	
	// supported non standard regex format is at http://www.icu-project.org/userguide/regexp.html
	NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	return [regextest evaluateWithObject:self];
}

/*
 
 - mgs_isURLorIP
 
 */
- (BOOL)mgs_isURLorIP
{
    // http://stackoverflow.com/questions/8249420/alter-regex-to-allow-ip-address-when-checking-url
	NSString *regex = @"^(http(s?):\\/\\/)?(((www\\.)?+[a-zA-Z0-9\\.\\-\\_]+(\\.[a-zA-Z]{2,20})+)|(\\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b))(\\/[a-zA-Z0-9\\_\\-\\s\\.\\/\\?\\%\\#\\&\\=]*)?$";
	
	// supported non standard regex format is at http://www.icu-project.org/userguide/regexp.html
	NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	return [regextest evaluateWithObject:self];
}
/*
 
 string by replacing characters in set
 
 the following exception was occurring when displaying app dictionaries.
 category namespace clash!
 
 renamed method accordingly.
 
 *** -[NSCFString rangeOfCharacterFromSet:options:range:]: Range or index out of bounds
 
 -[NSString rangeOfCharacterFromSet:options:range:] (in Foundation) 133
 -[NSMutableString(Mugginsoft) replaceCharactersInSet:withString:] (in MGSKosmicTask) (NSString_Mugginsoft.m:220)
 -[NSString(Mugginsoft) stringByReplacingCharactersInSet:withString:] (in MGSKosmicTask) (NSString_Mugginsoft.m:203)
 [OSADictionary(OSAPrivate) anchorFromName:] (in OSAKit) 53
 -[OSADictionary(OSAPrivate) parseData:error:] (in OSAKit) 1180
 
 ALL external class category methods really need to use a name space prefix.
 
 
 */
- (NSString *)mgs_StringByReplacingCharactersInSet:(NSCharacterSet *) set withString:(NSString *) string 
{
	NSRange range = [self rangeOfCharacterFromSet:set];
	if( range.location == NSNotFound )
		return self;
	
	NSMutableString *result = [self mutableCopyWithZone:nil];
	[result mgs_ReplaceCharactersInSet:set withString:string];
	return [result autorelease];
}

/*
 
 - mgs_stringByremovingNewLinesAndTabs
 
 */
- (NSString *)mgs_stringByRemovingNewLinesAndTabs
{
	// validate the string
	NSMutableString *string = [NSMutableString stringWithString:self];
	
	[string replaceOccurrencesOfString:@"\r\n" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@"\n" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@"\r" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@"\t" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [string length])];
	
	return [NSString stringWithString:string];
}

/*
 
 - mgs_StringWithSockAddrData:
 
 */
+ (NSString *)mgs_StringWithSockAddrData:(NSData *)addressData
{
    char addr[256];
    NSString *address = nil;
    BOOL addressIsValid = NO;
    
    struct sockaddr *sa = (struct sockaddr *)[addressData bytes];
    
    if(sa->sa_family == AF_INET6) {
        struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)sa;
        
        if(inet_ntop(AF_INET6, &sin6->sin6_addr, addr, sizeof(addr)))
        {
            addressIsValid = YES;
        }
    } else if(sa->sa_family == AF_INET) {
        struct sockaddr_in *sin = (struct sockaddr_in *)sa;
        
        if(inet_ntop(AF_INET, &sin->sin_addr, addr, sizeof(addr)))
        {
            addressIsValid = YES;
        }
    }
    
    if (addressIsValid) {
        address = [NSString stringWithCString:addr encoding:NSASCIIStringEncoding];
    }
    
    return address;
}

@end

@implementation NSMutableString (Mugginsoft)
/*
 
 replace characters in set
 
 */
- (void)mgs_ReplaceCharactersInSet:(NSCharacterSet *) set withString:(NSString *) string 
{
	NSRange range = NSMakeRange(0, [self length]);
	NSUInteger stringLength = [string length];
	
	NSRange replaceRange;
	while( ( replaceRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:range] ).location != NSNotFound ) {
		[self replaceCharactersInRange:replaceRange withString:string];
		
		range.location = replaceRange.location + stringLength;
		range.length = [self length] - replaceRange.location;
	}
}



@end


