//
//  MGSNetMessage.h
//  Mother
//
//  Created by Jonathan Mitchell on 05/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetMessageDictionary.h"
#import "MGSDisposableObject.h"

@class MGSError;
@class MGSNetHeader;
@class MGSNetAttachments;
@class MGSNetNegotiator;

// message dictionary keys
extern NSString *MGSMessageKeyVersion;
extern NSString *MGSMessageKeyUUID;
extern NSString *MGSMessageKeyRequestUUID;
extern NSString *MGSMessageKeyLicenceData;
extern NSString *MGSMessageKeyOrigin;
extern NSString *MGSNetMessageKeyCommand;
extern NSString *MGSNetMessageKeyChallenge;
extern NSString *MGSNetMessageKeyError;
extern NSString *MGSNetMessageKeyPreferences;
extern NSString *MGSNetMessageKeyApplication;
extern NSString *MGSNetMessageKeyNegotiate;

//extern NSString *MGSNetMessageNegotiateKeyAuthentication;
extern NSString *MGSNetMessageNegotiateKeySecurity;
extern NSString *MGSNetMessageNegotiateSecurityTLS;

extern NSString *MGSNetMessageOriginKeyHostName;
extern NSString *MGSNetMessageOriginKeySystemID;
extern NSString *MGSNetMessageOriginKeyIsLocalHost;


// message dictionary objects

// command strings
extern NSString *MGSNetMessageCommandParseKosmicTask;
extern NSString *MGSNetMessageCommandHeartbeat;
extern NSString *MGSNetMessageCommandAuthenticate;
extern NSString *MGSNetMessageCommandNegotiate;

// application keys
extern NSString *MGSApplicationKeyUsername;
extern NSString *MGSApplicationKeyRealTimeLogging;

@interface MGSNetMessage : MGSDisposableObject {
	NSMutableDictionary *_messageDict;		// message content is this dictionary
	NSInteger _expectedLength;				// expected length of the dictionary
	MGSError *_packetError;						// error
	unsigned long int _messageID;			// message sequence counter
	MGSNetHeader *_header;					// header
	unsigned long long _totalBytes;			// message length including attachments
	unsigned long long _bytesTransferred;	// the number of bytes that have been transferred over the network
}

@property NSInteger expectedLength;
@property (readonly) MGSError *packetError;
@property (readonly) MGSNetHeader *header;
@property (readonly) unsigned long long totalBytes;
@property unsigned long long bytesTransferred;

//+ (id)messageFromTemplate;

+ (NSMutableDictionary *)netOrigin;
+ (NSArray *)commands;

- (MGSNetMessage *) initWithTemplate:(NSString *)path;
- (BOOL)isNegotiateMessage;
- (void)setMessageObject:(id)object forKey:(NSString *)key;
- (id)messageObjectForKey:(NSString *)key;
- (void)removeMessageObjectForKey:(NSString *)key;
- (NSMutableData *)messagePacket;
- (BOOL)messageDictFromData:(NSData *)data;
- (NSMutableDictionary *)messageDict;
- (void)addRequestWasValid:(bool)valid;
- (void)setCommand:(NSString *)command;

- (NSString *)messageUUID;

// message origin
- (NSDictionary *)messageOrigin;
- (NSString *)messageOriginString;
- (NSString *)messageOriginHostName;
- (NSString *)messageOriginCompactString;
- (BOOL)messageOriginIsLocalHost;
- (void)setMessageOriginIsLocalHost:(BOOL)aBool;

- (NSString *)messageVersion;
- (NSString *)command;

// negotiator
- (void)applyNegotiator:(MGSNetNegotiator *)negotiator;
- (MGSNetNegotiator *)negotiator;
- (void)removeNegotiator;

- (MGSError *)error;
- (NSDictionary *)errorDictionary;
- (void)setErrorDictionary:(NSDictionary *)dict;
- (NSArray *)appData;
- (void)addAppData;

- (MGSNetAttachments *)attachments;
- (void)setAttachments:(MGSNetAttachments *)attachments;
- (void)parseAttachments;
- (unsigned long long)totalBytesFromHeader;

- (NSDictionary *)authenticationDictionary;
- (void)setAuthenticationDictionary:(NSDictionary *)dict;

@end
