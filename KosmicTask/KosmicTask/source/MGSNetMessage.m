//
//  MGSNetMessage.m
//  Mother
//
//  Created by Jonathan Mitchell on 05/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSNetMessage.h"
#import "MGSNetHeader.h"
#import "MGSError.h"
#import "NSMutableDictionary_Mugginsoft.h"
#import "NSDictionary_Mugginsoft.h"
#import "NSString_Mugginsoft.h"
#import "MGSNetAttachments.h"
#import "MGSLM.h"
#import "MGSSystem.h"
#import "MGSNetNegotiator.h"

// message dictionary message keys
NSString *MGSNetMessageKeyCommand = @"Command";
NSString *MGSNetMessageKeyAttachments = @"Attachments";
NSString *MGSNetMessageKeyRequestWasValid = @"RequestWasValid";
NSString *MGSNetMessageKeyNull = @"Null";
NSString *MGSMessageKeyVersion = @"Version";
NSString *MGSMessageKeyUUID = @"UUID";
NSString *MGSMessageKeyRequestUUID = @"RequestUUID";
NSString *MGSMessageKeyOrigin = @"Origin";
NSString *MGSMessageKeyLicenceData = @"Validation";
static NSString *MGSNetMessageKeyAuthentication = @"Authentication";
NSString *MGSNetMessageKeyChallenge = @"Challenge";
NSString *MGSNetMessageKeyError = @"Error";
NSString *MGSNetMessageKeyPreferences = @"Preferences";
NSString *MGSNetMessageKeyApplication = @"Application";
NSString *MGSNetMessageKeyNegotiate = @"Negotiate";

// negotiate keys
//NSString *MGSNetMessageNegotiateKeyAuthentication = @"Authentication";
NSString *MGSNetMessageNegotiateKeySecurity = @"Security";
NSString *MGSNetMessageNegotiateSecurityTLS = @"TLS";

// origin keys
NSString *MGSNetMessageOriginKeyHostName = @"HostName";
NSString *MGSNetMessageOriginKeySystemID = @"SystemID";
NSString *MGSNetMessageOriginKeyIsLocalHost = @"IsLocalHost";

// messsage dictionary object strings
NSString *MGSMessageVersion = @"1.0.0";

// top level command strings
NSString *MGSNetMessageCommandParseKosmicTask = @"Parse KosmicTask";			// parse the KosmicTask dictionary object
NSString *MGSNetMessageCommandHeartbeat = @"Heartbeat";						// simple heartbeat
NSString *MGSNetMessageCommandAuthenticate = @"Authenticate";				// perform authentication
NSString *MGSNetMessageCommandNegotiate = @"Negotiate";				// perform negotiation

// application keys
NSString *MGSApplicationKeyUsername = @"Username";                  // current username or @"" if name not disclosed
NSString *MGSApplicationKeyRealTimeLogging = @"RealTimeLogging";

static unsigned long int messageSequenceCounter = 0;

@interface MGSNetMessage(Private)
- (void)setErrorCode:(NSInteger)code description:(NSString *)description;
- (void)addAttachmentsPropertyListRepresentation;
@end

@implementation MGSNetMessage

@synthesize expectedLength = _expectedLength;
@synthesize packetError = _packetError;
@synthesize header = _header;
@synthesize totalBytes = _totalBytes;
@synthesize bytesTransferred = _bytesTransferred;

#pragma mark -
#pragma mark Class methods

/*
 
 net origin
 
 uniquely identifies the origin of the request
 
 */
+ (NSMutableDictionary *)netOrigin
{
	NSString *machineSerialNumber = [[MGSSystem sharedInstance] machineSerialNumber];
	NSString *localHostName = [[MGSSystem sharedInstance] localHostName];

	if (!machineSerialNumber) machineSerialNumber = [NSString mgs_stringWithNewUUID];
	if (!localHostName) localHostName = [NSString mgs_stringWithNewUUID];
	
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
				machineSerialNumber, MGSNetMessageOriginKeySystemID, 
				localHostName, MGSNetMessageOriginKeyHostName, 
				nil];
}

/*
 
 + commands
 
 */
+ (NSArray *)commands
{
	static NSArray *commands = nil;
	
	if (!commands) {
		commands = [NSArray arrayWithObjects:
						 MGSNetMessageCommandNegotiate,
						 MGSNetMessageCommandHeartbeat,
						 MGSNetMessageCommandAuthenticate,
						 MGSNetMessageCommandParseKosmicTask,
						 nil];
	}
	
	return commands;
}

#pragma mark -
#pragma mark Instance methods

/*
 
 - init
 
 */
- (MGSNetMessage *)init
{
	return [self initWithTemplate:nil];
}

/*
 
 init with template
 
 designated initialiser
 
 */
- (MGSNetMessage *) initWithTemplate:(NSString *)path
{
	if ((self = [super init])) {

		// load the message dict template if path supplied
		if (path) {
			_messageDict = [NSMutableDictionary dictionaryWithContentsOfFile:path];		
		} else {
			_messageDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:MGSMessageVersion, MGSMessageKeyVersion, nil];
		}

		NSAssert(_messageDict, @"message template dict not loaded");
		_expectedLength = -1;
		_messageID = messageSequenceCounter++;	// unique message int ID
		_totalBytes = 0;
		_bytesTransferred = 0;
		
		// unique message UUID
		[_messageDict setObject:[NSString mgs_stringWithNewUUID] forKey:MGSMessageKeyUUID];
		
		// origin
		[_messageDict setObject:[[self class] netOrigin] forKey:MGSMessageKeyOrigin];
		
		_header = [[MGSNetHeader alloc] init];	
        
        [self mgsMakeDisposable];
	}
	return self;
}


#pragma mark -
#pragma mark Origin
/*
 
 message origin
 
 */

- (NSDictionary *)messageOrigin
{
	return [_messageDict objectForKey:MGSMessageKeyOrigin];
}

/*
 
 message origin string
 
 */
- (NSString *)messageOriginString
{
	NSDictionary* orginDict = [_messageDict objectForKey:MGSMessageKeyOrigin];
	return [orginDict stringValueWithFormat:@"%@:%@ "];
}

/*
 
 message origin hostname
 
 */
- (NSString *)messageOriginHostName
{
	return [[self messageOrigin] objectForKey:MGSNetMessageOriginKeyHostName];
}

/*
 
 message origin compact string
 
 */
- (NSString *)messageOriginCompactString
{
	NSString *idString = [self messageOriginHostName];
	if (!idString) {
		idString = [self messageOriginString];
	}
	
	return idString;
}

/*
 
 set message origin is local host
 
 */
- (void)setMessageOriginIsLocalHost:(BOOL)aBool
{
	NSMutableDictionary *originDict = [_messageDict objectForKey:MGSMessageKeyOrigin];
	[originDict setObject:[NSNumber numberWithBool:aBool] forKey:MGSNetMessageOriginKeyIsLocalHost];
}

/*
 
 message origin is local host
 
 */
- (BOOL)messageOriginIsLocalHost
{
	return [[[self messageOrigin] objectForKey:MGSNetMessageOriginKeyIsLocalHost] boolValue];
}
/*
 
 message UUID
 
 */

- (NSString *)messageUUID
{
	return [_messageDict objectForKey:MGSMessageKeyUUID];
}

/*
 
 add licence data
 
 this will be used to validate whether the receivers seat limit has been exceeded.
 
 */
- (void)addAppData
{
//#warning licenceData acquisition is not thread safe
	NSArray *licenceData = [[MGSLM sharedController] allAppData];
	if (licenceData) {
		[_messageDict setObject:licenceData forKey:MGSMessageKeyLicenceData];
	}
}
/*
 
 licence data
 
 sensitive message name is not descriptive
 
 */

- (NSArray *)appData
{
	return [_messageDict objectForKey:MGSMessageKeyLicenceData];
}

/*
 
 message version
 
 */

- (NSString *)messageVersion
{
	return [_messageDict objectForKey:MGSMessageKeyVersion];
}


/*
 
 setCommand:
 
 */
- (void)setCommand:(NSString *)command
{
	[self setMessageObject:command forKey:MGSNetMessageKeyCommand];
}

/*
 
 - command
 
 */
- (NSString *)command
{
	return [_messageDict objectForKey:MGSNetMessageKeyCommand];
}

/*
 
 - negotiator
 
 */
- (MGSNetNegotiator *)negotiator
{
	NSDictionary *negotiate = [_messageDict objectForKey:MGSNetMessageKeyNegotiate];
	if (negotiate) {
		return [[MGSNetNegotiator alloc] initWithDictionary:negotiate];
	}
	
	return nil;
}

/*
 
 - isNegotiateMessage
 
 */
- (BOOL)isNegotiateMessage
{
	return [_messageDict objectForKey:MGSNetMessageKeyNegotiate] ? YES : NO;
}

/*
 
 - applyNegotiator:
 
 */
- (void)applyNegotiator:(MGSNetNegotiator *)negotiator
{
	NSAssert(negotiator, @"negotiator is nil");
	
	[self setMessageObject:[negotiator dictionary] forKey:MGSNetMessageKeyNegotiate];
}

/*
 
 - removeNegotiator
 
 */
- (void)removeNegotiator
{
	[self removeMessageObjectForKey:MGSNetMessageKeyNegotiate];
}

/*
 
 - errorDictionary
 
 */
- (NSDictionary *)errorDictionary
{
	return [_messageDict objectForKey:MGSNetMessageKeyError];
}

/*
 
 - setErrorDictionary:
 
 */
- (void)setErrorDictionary:(NSDictionary *)dict
{
	[self setMessageObject:dict forKey:MGSNetMessageKeyError];
}

/*
 
 - authenticationDictionary
 
 */
- (NSDictionary *)authenticationDictionary
{
	return [_messageDict objectForKey:MGSNetMessageKeyAuthentication];
}

/*
 
 - setAuthenticationDictionary:
 
 */
- (void)setAuthenticationDictionary:(NSDictionary *)dict
{
	[self setMessageObject:dict forKey:MGSNetMessageKeyAuthentication];
}
/*
 
 - error
 
 */
- (MGSError *)error
{
	MGSError *error = nil;
	NSDictionary *dict = [self errorDictionary];
	if (dict) {
		error = [MGSError errorWithDictionary:dict];
	}
	
	return error;
}

/*
 
 add request was valid to message
 
 */
- (void)addRequestWasValid:(bool)valid
{
	[self setMessageObject:[NSNumber numberWithBool:valid] forKey:MGSNetMessageKeyRequestWasValid];
}

/*
 
 set message dict object
 
 */
- (void)setMessageObject:(id)object forKey:(NSString *)key
{
	// exception occurs if object or key is nil
	//if (object == nil) object = [NSNull null];
	//if (key == nil) key = MGSNetMessageKeyNull;
	
	[_messageDict setObject:object forKey:key];
	//MLog(DEBUGLOG, @"message is %@", _messageDict);
}

/*
 
 set message dict object
 
 */
- (void)removeMessageObjectForKey:(NSString *)key
{
	if (key) {
		[_messageDict removeObjectForKey:key];
	}
}
/*
 
 -messageObjectForKey:
 
 */
- (id)messageObjectForKey:(NSString *)key
{
	// exception occurs if object or key is nil
	//if (object == nil) object = [NSNull null];
	//if (key == nil) key = MGSNetMessageKeyNull;
	
	return [_messageDict objectForKey:key];
	//MLog(DEBUGLOG, @"message is %@", _messageDict);
}

/*
 
 form the message packet from the underlying dictionary
 
 */
- (NSMutableData *)messagePacket
{
	//MLog(DEBUGLOG, @"message packet before conversion: %@", [_messageDict propertyListStringValue]);
		
	// serialize the message dict into XML
	NSString *error;
	NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:_messageDict
												format:NSPropertyListXMLFormat_v1_0
												errorDescription:&error];

	//NSString *xmlString = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
	//MLog(DEBUGLOG, @"message packet after conversion to xml property list: %@", xmlString);
	
	if(!xmlData)
	{
		MLog(RELEASELOG, @"error serializing message: %@", error);
		[self setErrorCode:MGSErrorCodeProcessMessage description:NSLocalizedString(@"error serializing message packet", @"error preparing message")];
		
		// form error packet
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys: [_packetError dictionary], MGSNetMessageKeyError, nil];
		xmlData = [NSPropertyListSerialization dataFromPropertyList:errorDict
															 format:NSPropertyListXMLFormat_v1_0
												   errorDescription:&error];
	}
	
	// unrecoverable error
	if(!xmlData)
	{
		MLog(RELEASELOG, @"unrecoverable error serializing message: %@", error);
		[self setErrorCode:MGSErrorCodeProcessMessage description:NSLocalizedString(@"unrecoverable serializing message packet", @"error preparing message")];
		return nil;
	}
	
	// get the message header data
	NSData *headerData = [_header headerDataWithPayloadSize:[xmlData length]];
	if (!headerData) {
		[self setErrorCode:MGSErrorCodeProcessMessage description:NSLocalizedString(@"message header is invalid", @"error preparing message")];
		return nil;
	}
	
	// message data = header + message
	// attachments will be sent in separate NSData blocks as required
	NSMutableData *messageData = [NSMutableData dataWithData:headerData];
	[messageData appendData:xmlData];
	
	return messageData;
}

/*
 
 total message bytes from header
 
 */
- (unsigned long long)totalBytesFromHeader
{
	unsigned long long headerLength = _header.headerLength;
	unsigned long long contentLength = _header.contentLength;
	unsigned long long attachmentsLength = [_header.attachments requiredLength];	// required attachment length
	
	MLog(DEBUGLOG, @"header-length: %qu content-length: %qu attachment-length: %qu", headerLength, contentLength, attachmentsLength);
	
	unsigned long long messageLength = headerLength + contentLength + attachmentsLength;
	
	return messageLength;
}

/*
 
 total message bytes 
 
 */
- (unsigned long long)totalBytes
{
	unsigned long long headerLength = _header.headerLength;
	unsigned long long contentLength = _header.contentLength;
	unsigned long long attachmentsLength = [_header.attachments validatedLength];	// validated attachment length
	
	MLog(DEBUGLOG, @"header-length: %qu content-length: %qu attachment-length: %qu", headerLength, contentLength, attachmentsLength);
	
	unsigned long long messageLength = headerLength + contentLength + attachmentsLength;
	
	return messageLength;
}
/*
 
 form message dict from data
 
 */
- (BOOL)messageDictFromData:(NSData *)data
{
	NSString *error;
	NSPropertyListFormat format;
	id object = [NSPropertyListSerialization propertyListFromData:data 
								mutabilityOption:NSPropertyListMutableContainersAndLeaves 
								format:&format 
								errorDescription:&error];
	if (!object){
		MLog(RELEASELOG, @"error deserializing message: %@", error);
		[self setErrorCode:MGSErrorCodeProcessMessage description:NSLocalizedString(@"error deserializing message packet", @"error preparing message")];
		return NO;
	}
	NSAssert([object classForCoder] == [NSMutableDictionary class], @"dict is not mutable");
	_messageDict = object;
	return YES;
}

/*
 
 message dict
 
 */
- (NSMutableDictionary *)messageDict
{
	return _messageDict;
}

#pragma mark -
#pragma mark MGSDisposal category
/*
 
 - mgsDispose
 
 */
- (void)mgsDispose
{
    // check if we are already disposed
    if ([self isMgsDisposedWithLogIfTrue]) {
        return;
    }

#ifdef MGS_LOG_DISPOSE
	MLog(DEBUGLOG, @"MGSNetMessage disposed");
#endif
    
    // we no longer need to retain the attachments
    [self.attachments releaseDisposable];
    
    [super mgsDispose];
}

#pragma mark -
#pragma mark Memory management
/*
 
 - finalize
 
 */
- (void)finalize
{
    if (!_disposed) {
        MLogInfo(@"%@: -finalize received without prior -dispose.", self);
    }
    
#ifdef MGS_LOG_FINALIZE
	MLog(MEMORYLOG, @"MGSNetMessage finalized");
#endif
    
	[super finalize];
}

#pragma mark -
#pragma mark Attachment management
/*
 
 attachments
 
 */
- (MGSNetAttachments *)attachments
{
	return _header.attachments;
}

/*
 
 set attachments
 
 */
- (void)setAttachments:(MGSNetAttachments *)attachments
{
	// set the header attachments
	_header.attachments = attachments;
	
	// add attachments plist representation to the message
	[self addAttachmentsPropertyListRepresentation];
}


/*
 
 parse attachments
 
 */
- (void)parseAttachments
{
	// look in dict for attachments array
	NSArray *attachmentsList = [_messageDict objectForKey:MGSNetMessageKeyAttachments];
	if (!attachmentsList) {
		return;
	}
	
	// validate the list
	if (![attachmentsList isKindOfClass:[NSArray class]]) {
		MLog(RELEASELOG, @"bad attachment data in message");
		return;
	}
	
	// let the attachments do the work
	[self.attachments parsePropertyListRepresentation:attachmentsList];
}

@end

@implementation MGSNetMessage(Private)

/*
 
 add attachments property list reprtesentation to the message
 
 */
- (void)addAttachmentsPropertyListRepresentation
{
	// save property list representation within the message
	id attachmentList = [self.attachments propertyListRepresentation];
	if (attachmentList) {
		[self setMessageObject:attachmentList forKey:MGSNetMessageKeyAttachments];
	}
}
		
/*
 
 set error code and description
 
 */
- (void)setErrorCode:(NSInteger)code description:(NSString *)description
{
	_packetError = [MGSError frameworkCode:code reason:description];
}

@end

