//
//  MGSNetHeader.m
//  Mother
//
//  Created by Jonathan Mitchell on 04/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSNetHeader.h"
#import "NSScanner_Mugginsoft.h"
#import "MGSNetAttachments.h"

#define NETMESSAGE_MAX_HEADER 50000000

// first two lines of header are fixed size
NSString *MGSNetHeaderPrefix = @"MGSNetMessage 1.0\n";
NSString *MGSNetHeaderTagLength = @"Header-Length:";
NSString *MGSNetHeaderTagFormat = @"Header-Length: %08lu\n"; // see NETMESSAGE_MAX_HEADER
NSInteger MGSNetHeaderPrefixLength = 18;
NSInteger MGSNetHeaderLengthLength = 24;
NSInteger MGSNetHeaderLength = 42;

// header tags
NSString *MGSNetHeaderTagContentType = @"Content-Type:"; 	
NSString *MGSNetHeaderTagContentSubtype = @"Content-Subtype:"; 	
NSString *MGSNetHeaderTagContentEncoding = @"Content-Encoding:"; 
NSString *MGSNetHeaderTagContentLength = @"Content-Length:"; 
NSString *MGSNetHeaderTagAttachmentLength = @"Attachments-Length:"; 
NSString *MGSNetHeaderTagRequestTimeout = @"Request-Timeout:"; 	
NSString *MGSNetHeaderTagResponseTimeout = @"Response-Timeout:"; 

// tag parameters
NSString *MGSNetHeaderContentTypeXml = @"xml 1.0";
NSString *MGSNetHeaderContentSubtypePlist = @"plist 1.0";
NSString *MGSNetHeaderContentEncodingUTF8 =  @"UTF-8";


@implementation MGSNetHeader

@synthesize contentType = _contentType;
@synthesize contentSubtype = _contentSubtype;
@synthesize contentLength = _contentLength;
@synthesize requestTimeout = _requestTimeout;
@synthesize responseTimeout = _responseTimeout;
@synthesize contentEncoding = _contentEncoding;
@synthesize headerLength = _headerLength;
@synthesize headerValidated = _headerValidated;
@synthesize prefixValidated = _prefixValidated;
@synthesize attachments = _attachments;

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		_contentType = MGSNetHeaderContentTypeXml;
		_contentSubtype = MGSNetHeaderContentSubtypePlist;
		_contentEncoding = MGSNetHeaderContentEncodingUTF8;
		_contentLength = 0;
		_headerLength = 0;
		_requestTimeout = -1;	// no timeout
		_responseTimeout = -1;	// no timeout
		_prefixValidated = NO;
		_headerValidated = NO;
		_attachments = nil;
	}
	
	return self;
}

/*
 
 header data with payload size
 
 */
- (NSData *)headerDataWithPayloadSize:(NSInteger)size
{
	self.contentLength = size;
	return [self headerData];
}

/*
 
 header data
 
 */
- (NSData *)headerData
{
	// form the fixed length header prefix
	NSMutableString *header = [NSMutableString stringWithString:MGSNetHeaderPrefix];
	NSString *placeHolder = [NSString stringWithFormat:MGSNetHeaderTagFormat, (unsigned long)0]; // note cast to unsigned long - advised for 64 bit code
	[header appendString:placeHolder]; 	

	
	// append the remaining mandatory header info
	[header appendFormat:@"%@ %@\n", MGSNetHeaderTagContentType, _contentType]; 	
	[header appendFormat:@"%@ %@\n", MGSNetHeaderTagContentSubtype, _contentSubtype]; 	
	[header appendFormat:@"%@ %@\n", MGSNetHeaderTagContentEncoding, _contentEncoding]; 
	[header appendFormat:@"%@ %lu\n", MGSNetHeaderTagContentLength, (unsigned long)_contentLength]; 	// note cast to unsigned long - advised for 64 bit code
	[header appendFormat:@"%@ %i\n", MGSNetHeaderTagRequestTimeout, _requestTimeout]; 	// note cast to unsigned long - advised for 64 bit code
	[header appendFormat:@"%@ %i\n", MGSNetHeaderTagResponseTimeout, _responseTimeout]; 	// note cast to unsigned long - advised for 64 bit code

	// append discretionary header info
	
	// append attachments
	if (_attachments && [[_attachments array] count] > 0) {

		// may be of form len1;len2;...lenN 
		NSString *attachmentLengthString = [_attachments headerRepresentation];
		[header appendFormat:@"%@ %@\n", MGSNetHeaderTagAttachmentLength, attachmentLengthString]; 	
	}

	// conclude the header
	[header appendString:@"\n\n"];
	
	// get actual header length
	_headerLength = [header length];
	if (_headerLength > NETMESSAGE_MAX_HEADER) {
		MLog(RELEASELOG, @"header is too long: %i", _headerLength);
		return nil;
	}
	
	// replace placeholder string with actual header size
	NSString *headerSize= [NSString stringWithFormat:MGSNetHeaderTagFormat,  (unsigned long)_headerLength]; // note cast to unsigned long - advised for 64 bit code
	[header replaceOccurrencesOfString:placeHolder withString:headerSize options:0 range:NSMakeRange(0, [header length])];
	
	MLog(DEBUGLOG, @"MGSNetMessage header: %@", header);
	
	_prefixValidated = YES;
	_headerValidated = YES;
	
	return [header dataUsingEncoding:NSUTF8StringEncoding];
}

/*
 
 validate the prefix
 
 the prefix is a fixed length segment at the start of the header
 
 */
- (BOOL)validatePrefix:(NSString *)prefix
{
	
	//NSCharacterSet *newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
	//NSCharacterSet *colonSet = [NSCharacterSet characterSetWithCharactersInString:@":"];
	
	NSScanner *scanner = [NSScanner scannerWithString:prefix];
	
	// prefix
	if (![scanner scanString:MGSNetHeaderPrefix intoString:NULL]) return NO;
	
	// header length
	if (![scanner scanString:MGSNetHeaderTagLength intoString:NULL]) return NO;
	if (![scanner scanInteger:&_headerLength]) return NO;

	if (_headerLength > NETMESSAGE_MAX_HEADER) return NO;
	
	_prefixValidated = YES;
	
	return YES;
}

/*
 
 validate the header
 
 prefix must be valid
 
 */
- (BOOL)validateHeader:(NSString *)header
{
	MLog(DEBUGLOG, @"Scanning header.");

	if (!_prefixValidated) return NO;
	
	//NSCharacterSet *newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
	//NSCharacterSet *colonSet = [NSCharacterSet characterSetWithCharactersInString:@":"];
	
	// content type
	NSScanner *scanner = [NSScanner scannerWithString:header];
	if (![scanner scanUpToStringAndOver:MGSNetHeaderTagContentType]) return NO;
	if (![scanner scanString:MGSNetHeaderContentTypeXml intoString:NULL]) return NO;	// only 1 acceptable value

	// reset our scanner as we do not want to depend upon a fixed header elemnt order
	[scanner setScanLocation:0];
	
	// content subtype
	if (![scanner scanUpToStringAndOver:MGSNetHeaderTagContentSubtype]) return NO;
	if (![scanner scanString:MGSNetHeaderContentSubtypePlist intoString:NULL]) return NO;	// only 1 acceptable value
	
	// content encoding
	[scanner setScanLocation:0];
	if (![scanner scanUpToStringAndOver:MGSNetHeaderTagContentEncoding]) return NO;
	if (![scanner scanString:MGSNetHeaderContentEncodingUTF8 intoString:NULL]) return NO;	// only 1 acceptable value

	// content length
	[scanner setScanLocation:0];
	if (![scanner scanUpToStringAndOver:MGSNetHeaderTagContentLength]) return NO;
	if (![scanner scanInteger:&_contentLength]) return NO;

	// request timeout
	[scanner setScanLocation:0];
	if (![scanner scanUpToStringAndOver:MGSNetHeaderTagRequestTimeout]) return NO;
	if (![scanner scanInteger:&_requestTimeout]) return NO;

	// response timeout
	[scanner setScanLocation:0];
	if (![scanner scanUpToStringAndOver:MGSNetHeaderTagResponseTimeout]) return NO;
	if (![scanner scanInteger:&_responseTimeout]) return NO;
	
	// discretionary header tags
	
	// attachments
	[scanner setScanLocation:0];
	if ([scanner scanUpToStringAndOver:MGSNetHeaderTagAttachmentLength]) {
		
		MLog(DEBUGLOG, @"Attachment header found.");
		
		NSString *headerRepresentation = nil;
		if (![scanner scanUpToString:@"\n" intoString:&headerRepresentation]) {
			MLog(DEBUGLOG, @"Could not scan header representation.");
			return NO;
		}
		
		_attachments = [[MGSNetAttachments alloc] initWithHeaderRepresentation:headerRepresentation];
		if (!_attachments) {
			return NO;
		}
	} else {
		MLog(DEBUGLOG, @"No attachment header found.");
	}
	
	MLog(DEBUGLOG, @"Header validated.");

	_headerValidated = YES;
	return _headerValidated;
}
@end
