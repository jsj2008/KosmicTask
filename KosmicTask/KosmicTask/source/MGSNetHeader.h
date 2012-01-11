//
//  MGSNetHeader.h
//  Mother
//
//  Created by Jonathan Mitchell on 04/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSNetHeaderTerminator;
extern NSString *MGSNetHeaderPrefix;
extern NSString *MGSNetHeaderSizeFormat;
extern NSInteger MGSNetHeaderPrefixLength;
extern NSInteger MGSNetHeaderSizeLength;
extern NSInteger MGSNetHeaderLength;

extern NSString *MGSNetHeaderContentTypeXml;
extern NSString *MGSNetHeaderContentSubtypePlist;
extern NSString *MGSNetHeaderContentEncodingUTF8;
extern NSString *MGSNetHeaderAttachmentTransferEncodingIdentity;
extern NSString *MGSNetHeaderAttachmentTransferEncodingChunked;
extern NSString *MGSNetHeaderAttachmentEncodingUTF8;
extern NSString *MGSNetHeaderAttachmentEncodingBinary;

@class MGSNetAttachments;

@interface MGSNetHeader : NSObject {
	NSString *_contentEncoding;
	NSString *_contentType;
	NSString *_contentSubtype;
	NSInteger _contentLength;
	NSInteger _requestTimeout;
	NSInteger _responseTimeout;
	NSInteger _headerLength;
    NSString *_attachmentEncoding;
    NSString *_attachmentTransferEncoding;
    NSDate *_date;
    NSString *_userAgent;
    
	BOOL _prefixValidated;
	BOOL _headerValidated;
	MGSNetAttachments *_attachments;
}

- (id)initWithXMLPlist;
- (id)initWithContentType:(NSString *)type subType:(NSString *)subType encoding:(NSString *)encoding;
- (NSData *)headerDataWithPayloadSize:(NSInteger) size;
- (BOOL)validatePrefix:(NSString *)prefix;
- (BOOL)validateHeader:(NSString *)header;
- (NSData *)headerData;

@property (readonly) NSString *contentType;
@property NSInteger contentLength;
@property NSInteger headerLength;
@property NSInteger requestTimeout;
@property NSInteger responseTimeout;
@property (readonly) NSString *contentEncoding;
@property (readonly) NSString *contentSubtype;
@property (readonly) BOOL prefixValidated;
@property (readonly) BOOL headerValidated;
@property (assign) MGSNetAttachments *attachments;
@property (assign) NSString *attachmentTransferEncoding;
@property (assign) NSString *attachmentEncoding;
@property (readonly) NSDate *date;
@property (readonly) NSString *userAgent;
@end
