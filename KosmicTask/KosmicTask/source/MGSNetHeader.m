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

NSString *const MGSNetHeaderException = @"MGSNetHeaderException";

/*
 
 the MSNetMessage protocol borrows from HTTP in many cases

 http://www.w3.org/Protocols/rfc2616/rfc2616.html
 
 */

// HTTP use CRLF as a terminator
NSString *MGSNetHeaderTerminator = @"\r\n";
NSString *MGSNetChunkTerminator = @"\r\n";

// first two lines of header are fixed size
NSString *MGSNetHeaderPrefix = @"MGSNetMessage 1.1\r\n";
NSString *MGSNetHeaderTagLength = @"Header-Length:";
NSString *MGSNetHeaderTagFormat = @"Header-Length: %08lu\r\n"; // see NETMESSAGE_MAX_HEADER
NSInteger MGSNetHeaderPrefixLength = 18;
NSInteger MGSNetHeaderLengthLength = 24;
NSInteger MGSNetHeaderLength = 42;

// header tags
NSString *MGSNetHeaderTagContentType = @"Content-Type:"; 	
NSString *MGSNetHeaderTagContentSubtype = @"Content-Subtype:"; 	
NSString *MGSNetHeaderTagContentEncoding = @"Content-Encoding:"; 
NSString *MGSNetHeaderTagContentLength = @"Content-Length:"; 
NSString *MGSNetHeaderTagRequestTimeout = @"Request-Timeout:"; 	
NSString *MGSNetHeaderTagResponseTimeout = @"Response-Timeout:"; 
NSString *MGSNetHeaderTagUserAgent = @"User-Agent:"; 
NSString *MGSNetHeaderTagDate = @"Date:"; 

// attachment tags
NSString *MGSNetHeaderTagAttachmentEncoding = @"Attachment-Encoding:"; 
NSString *MGSNetHeaderTagAttachmentLength = @"Attachment-Length:"; 
NSString *MGSNetHeaderTagAttachmentTransferEncoding = @"Attachment-Transfer-Encoding:"; 

// xml content types and sub types
/*
 note that we are using explicit types and subtypes rather than MIME 
 */
NSString *MGSNetHeaderContentTypeXml = @"xml 1.0";
NSString *MGSNetHeaderContentSubtypePlist = @"plist 1.0";

// content encoding
NSString *MGSNetHeaderContentEncodingUTF8 = @"UTF-8";

// attachment encoding
NSString *MGSNetHeaderAttachmentEncodingUTF8 = @"UTF-8";
NSString *MGSNetHeaderAttachmentEncodingBinary = @"binary";

// user agent
NSString *MGSNetHeaderUserAgentKosmicTaskOSX = @"KosmicTask OS-X";

// attachment transfer encoding
// for HTTP chunked encoding see http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html
/*
 OCTET = 8 bits
 
 Chunked-Body   = *chunk
 last-chunk
 trailer
 CRLF
 chunk          = chunk-size [ chunk-extension ] CRLF
 chunk-data CRLF
 chunk-size     = 1*HEX
 last-chunk     = 1*("0") [ chunk-extension ] CRLF
 chunk-extension= *( ";" chunk-ext-name [ "=" chunk-ext-val ] )
 chunk-ext-name = token
 chunk-ext-val  = token | quoted-string
 chunk-data     = chunk-size(OCTET)
 trailer        = *(entity-header CRLF)
 
 */
NSString *MGSNetHeaderAttachmentTransferEncodingIdentity = @"identity";
NSString *MGSNetHeaderAttachmentTransferEncodingChunked = @"chunked";

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
@synthesize attachmentTransferEncoding = _attachmentTransferEncoding;
@synthesize attachmentEncoding = _attachmentEncoding;
@synthesize date = _date;
@synthesize userAgent = _userAgent;

static NSDateFormatter *rfc3339DateFormatter = nil;

+ (void)initialize
{
    rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}
/*
 
 initWithContentType:subType:encoding
 
 designated initialiser
 
 */
- (id)initWithContentType:(NSString *)type subType:(NSString *)subType encoding:(NSString *)encoding
{
   if ((self = [super init])) {
		_contentType = type;
		_contentSubtype = subType;
		_contentEncoding = encoding;
		_requestTimeout = -1;	// no timeout
		_responseTimeout = -1;	// no timeout
		_prefixValidated = NO;
		_headerValidated = NO;
        _userAgent = MGSNetHeaderUserAgentKosmicTaskOSX;
	}
	
	return self; 
}
/*
 
 - init
 
 */
- (id)init
{
	return [self initWithXMLPlist];
}

/*
 
 - init
 
 */
- (id)initWithXMLPlist
{
	return [self initWithContentType:MGSNetHeaderContentTypeXml 
                             subType:MGSNetHeaderContentSubtypePlist
                            encoding:MGSNetHeaderContentEncodingUTF8];
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

    // get rfc3339 date
    NSString *rfc3339Date = nil;
	_date = [NSDate date];
    @synchronized(rfc3339DateFormatter) {
        rfc3339Date = [rfc3339DateFormatter stringFromDate:_date];
    }
    
	// append the remaining mandatory header info.
	[header appendFormat:@"%@ %@%@", MGSNetHeaderTagContentType, _contentType, MGSNetHeaderTerminator]; 	
	[header appendFormat:@"%@ %@%@", MGSNetHeaderTagContentSubtype, _contentSubtype, MGSNetHeaderTerminator]; 	
	[header appendFormat:@"%@ %@%@", MGSNetHeaderTagContentEncoding, _contentEncoding, MGSNetHeaderTerminator]; 
    [header appendFormat:@"%@ %@%@", MGSNetHeaderTagDate, rfc3339Date, MGSNetHeaderTerminator]; 
    [header appendFormat:@"%@ %@%@", MGSNetHeaderTagUserAgent, MGSNetHeaderUserAgentKosmicTaskOSX, MGSNetHeaderTerminator];
	[header appendFormat:@"%@ %lu%@", MGSNetHeaderTagContentLength, (unsigned long)_contentLength, MGSNetHeaderTerminator]; 	// note cast to unsigned long - advised for 64 bit code
	[header appendFormat:@"%@ %ld%@", MGSNetHeaderTagRequestTimeout, (long)_requestTimeout, MGSNetHeaderTerminator]; 	// note cast to unsigned long - advised for 64 bit code
	[header appendFormat:@"%@ %ld%@", MGSNetHeaderTagResponseTimeout, (long)_responseTimeout, MGSNetHeaderTerminator]; 	// note cast to unsigned long - advised for 64 bit code

	// append discretionary header info
	
	// append attachments
	if (_attachments && [[_attachments array] count] > 0) {

        self.attachmentEncoding = MGSNetHeaderAttachmentEncodingBinary;
        
        // set the attachment encoding as binary
        [header appendFormat:@"%@ %@%@", MGSNetHeaderTagAttachmentEncoding, self.attachmentEncoding, MGSNetHeaderTerminator];

        // set the attachment transfer encoding as identity
        [header appendFormat:@"%@ %@%@", MGSNetHeaderTagAttachmentTransferEncoding, MGSNetHeaderAttachmentTransferEncodingIdentity, MGSNetHeaderTerminator];
        
        // set the attachment length
		// may be of form len1;len2;...lenN 
		NSString *attachmentLengthString = [_attachments headerRepresentation];
		[header appendFormat:@"%@ %@%@", MGSNetHeaderTagAttachmentLength, attachmentLengthString, MGSNetHeaderTerminator]; 
        
	} else if (self.attachmentTransferEncoding) {
        
        self.attachmentEncoding = MGSNetHeaderAttachmentEncodingUTF8;
        
        // set the attachment encoding as UTF-8
        [header appendFormat:@"%@ %@%@", MGSNetHeaderTagAttachmentEncoding, self.attachmentEncoding, MGSNetHeaderTerminator];

        // set the transfer encoding as chunked
        [header appendFormat:@"%@ %@%@", MGSNetHeaderTagAttachmentTransferEncoding, MGSNetHeaderAttachmentTransferEncodingChunked, MGSNetHeaderTerminator];
    }

	// conclude the header
	[header appendString:MGSNetHeaderTerminator];
	
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
    _headerValidated = NO;
    
	MLog(DEBUGLOG, @"Scanning header.");
    NSString *scannedString = nil;
    
	if (!_prefixValidated) return NO;
	
	@try {	
        // content type
        NSScanner *scanner = [NSScanner scannerWithString:header];
        if (![scanner scanUpToStringAndOver:MGSNetHeaderTagContentType]) return NO;
        if (![scanner scanString:MGSNetHeaderContentTypeXml intoString:&_contentType]) return NO;	// only 1 acceptable value

        // content subtype
        [scanner setScanLocation:0];
        if (![scanner scanUpToStringAndOver:MGSNetHeaderTagContentSubtype]) return NO;
        if (![scanner scanString:MGSNetHeaderContentSubtypePlist intoString:&_contentSubtype]) return NO;	// only 1 acceptable value
        
        // content encoding
        [scanner setScanLocation:0];
        if (![scanner scanUpToStringAndOver:MGSNetHeaderTagContentEncoding]) return NO;
        if (![scanner scanString:MGSNetHeaderContentEncodingUTF8 intoString:&_contentEncoding]) return NO;	// only 1 acceptable value

        // date
        NSString *rfc3339Date = nil;
        [scanner setScanLocation:0];
        if (![scanner scanUpToStringAndOver:MGSNetHeaderTagDate]) return NO;
        if (![scanner scanUpToString:MGSNetHeaderTerminator intoString:&rfc3339Date]) return NO;	// a date is an acceptable value
        @synchronized(rfc3339DateFormatter) {
            _date = [rfc3339DateFormatter dateFromString:rfc3339Date];
        }
        
        // user agent
        [scanner setScanLocation:0];
        if (![scanner scanUpToStringAndOver:MGSNetHeaderTagUserAgent]) return NO;
        if (![scanner scanString:MGSNetHeaderUserAgentKosmicTaskOSX intoString:&_userAgent]) return NO;	// only 1 acceptable value

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
        
        //
        // discretionary header tags
        //
        
        // attachment transfer encoding
        scannedString = nil;
        [scanner setScanLocation:0];
        if ([scanner scanUpToStringAndOver:MGSNetHeaderTagAttachmentTransferEncoding]) {
            if (![scanner  scanUpToString:MGSNetHeaderTerminator intoString:&scannedString]) return NO;
            self.attachmentTransferEncoding = scannedString;
            
            // attachment encoding must also be defined
            scannedString = nil;
            [scanner setScanLocation:0];
            if (![scanner scanUpToStringAndOver:MGSNetHeaderTagAttachmentEncoding]) return NO;
            if (![scanner scanUpToString:MGSNetHeaderTerminator intoString:&scannedString]) return NO;
            self.attachmentEncoding = scannedString;
        }

        // attachments identified by length
        [scanner setScanLocation:0];
        if ([scanner scanUpToStringAndOver:MGSNetHeaderTagAttachmentLength]) {
            
            MLog(DEBUGLOG, @"Attachment header found.");
            
            NSString *headerRepresentation = nil;
            if (![scanner scanUpToString:MGSNetHeaderTerminator intoString:&headerRepresentation]) {
                [NSException raise:MGSNetHeaderException format:@"Invalid header representation: %@", headerRepresentation];
            }
            
            _attachments = [[MGSNetAttachments alloc] initWithHeaderRepresentation:headerRepresentation];
            if (!_attachments) {
                [NSException raise:MGSNetHeaderException format:@"Empty header representation: %@", headerRepresentation];
            }
            
            // attachment transfer encoding must be identity
            if (![self.attachmentTransferEncoding isEqualToString:MGSNetHeaderAttachmentTransferEncodingIdentity]) {
                [NSException raise:MGSNetHeaderException format:@"Invalid Attachment-Transfer-Encoding: %@", self.attachmentTransferEncoding];
            }

            // attachment encoding must be binary
            if (![self.attachmentEncoding isEqualToString:MGSNetHeaderAttachmentEncodingBinary]) {
                [NSException raise:MGSNetHeaderException format:@"Invalid Attachment-Transfer-Encoding: %@", self.attachmentEncoding];
            }

        } else if (self.attachmentTransferEncoding) {
        
            // if attachment transfer encoding defined it must be chunked
            if (![self.attachmentTransferEncoding isEqualToString:MGSNetHeaderAttachmentTransferEncodingChunked]) {
                [NSException raise:MGSNetHeaderException format:@"Invalid Attachment-Transfer-Encoding: %@", self.attachmentTransferEncoding];
            }
            
            // attachment encoding must be UTF*
            if (![self.attachmentEncoding isEqualToString:MGSNetHeaderAttachmentEncodingUTF8]) {
                [NSException raise:MGSNetHeaderException format:@"Invalid Attachment-Transfer-Encoding: %@", self.attachmentEncoding];
            }
        }
        
        MLog(DEBUGLOG, @"Header validated.");
        _headerValidated = YES;

    } @catch (NSException *e) {
        MLogException(e);
    }
        
	return _headerValidated;
}

/*
 
 - setAttachmentTransferEncoding
 
 */
- (void)setAttachmentTransferEncoding:(NSString *)value
{
    NSArray *values = [NSArray arrayWithObjects:MGSNetHeaderAttachmentTransferEncodingIdentity, 
                                                MGSNetHeaderAttachmentTransferEncodingChunked, 
                                                nil];
    _attachmentTransferEncoding = nil;
    
    if ([values containsObject:value]) {
        _attachmentTransferEncoding = value;
    } else {
        [NSException raise:MGSNetHeaderException format:@"Invalid Attachment-Transfer=Encoding: %@", value]; 
    }
}

/*
 
 - setAttachmentEncoding
 
 */
- (void)setAttachmentEncoding:(NSString *)value
{
    NSArray *values = [NSArray arrayWithObjects:MGSNetHeaderAttachmentEncodingBinary, 
                       MGSNetHeaderAttachmentEncodingUTF8, 
                       nil];
    _attachmentEncoding = nil;
    
    if ([values containsObject:value]) {
        _attachmentEncoding = value;
    } else {
        [NSException raise:MGSNetHeaderException format:@"Invalid Attachment-Encoding: %@", value]; 
    }
}

@end
