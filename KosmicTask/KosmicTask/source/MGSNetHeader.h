//
//  MGSNetHeader.h
//  Mother
//
//  Created by Jonathan Mitchell on 04/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSNetHeaderPrefix;
extern NSString *MGSNetHeaderSizeFormat;
extern NSInteger MGSNetHeaderPrefixLength;
extern NSInteger MGSNetHeaderSizeLength;
extern NSInteger MGSNetHeaderLength;

@class MGSNetAttachments;

@interface MGSNetHeader : NSObject {
	NSString *_contentEncoding;
	NSString *_contentType;
	NSString *_contentSubtype;
	NSInteger _contentLength;
	NSInteger _requestTimeout;
	NSInteger _responseTimeout;
	NSInteger _headerLength;
	BOOL _prefixValidated;
	BOOL _headerValidated;
	MGSNetAttachments *_attachments;
}

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
@end
