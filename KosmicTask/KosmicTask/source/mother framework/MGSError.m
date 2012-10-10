//
//  MGSError.m
//  Mother
//
//  Created by Jonathan on 03/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSError.h"
#import "MGSErrorWindowController.h"
#import "NSString_Mugginsoft.h"

enum eMGSErrorFlags
{
	kLoggedToConsole      = 1 <<  0,  // If set, error has been logged to the console
	kLoggedToController   = 1 <<  1,  // If set, error has been logged to the controller
};


// NSError domains
NSString *MGSErrorDomainMotherServer = @"KosmicTask Server";
NSString *MGSErrorDomainMotherClient = @"KosmicTask";
NSString *MGSErrorDomainMotherFramework = @"KosmicTask Framework";
NSString *MGSErrorDomainMotherNetwork = @"Network";
NSString *MGSErrorDomainMotherScriptTask = @"KosmicTask Runner";

static MGSErrorWindowController *_controller;

@implementation MGSError

@synthesize date = _date, flags, machineName = _machineName;

#pragma mark -
#pragma mark Class methods

/*
 
 error with dictionary with log option
 
 */
+ (id)errorWithDictionary:(NSDictionary *)dict log:(BOOL)logIt
{
	NSString *domain = [dict objectForKey: MGSDomainErrorKey];
	if (nil == domain) {
		domain = @"unspecified error domain";	// domain must not be nil
	}
	NSInteger code = [[dict objectForKey: MGSCodeErrorKey] intValue];
	NSDictionary *userInfo = [dict objectForKey: MGSUserInfoErrorKey];
	
	return [self domain:domain code:code userInfo:userInfo log:logIt];
}

/*
 
 error with dictionary
 
 */
+ (id)errorWithDictionary:(NSDictionary *)dict
{
	return [self errorWithDictionary:dict log:YES];
}


/*
 
 set window controller
 
 */
+ (void)setWindowController:(MGSErrorWindowController *)controller
{
	_controller = controller;
}

+ (NSMutableDictionary *)userInfoFromAppleScriptErrorDict:(NSDictionary *)errorDict
{
	// unpack the NDAppleScriptObject error dict data into our userInfo dict
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
	id errorObj;
	if ((errorObj = [errorDict objectForKey:NSAppleScriptErrorMessage])) 
		[userInfo setObject:errorObj forKey:NSLocalizedFailureReasonErrorKey];
	
	if ((errorObj = [errorDict objectForKey:NSAppleScriptErrorNumber])) 
		[userInfo setObject:errorObj forKey:MGSAdditionalCodeErrorKey];
	
	// cannot pass native NSRange in plist
	if ((errorObj = [errorDict objectForKey:NSAppleScriptErrorRange])) {
		NSRange range =  [errorObj rangeValue];
		[userInfo setObject:NSStringFromRange(range) forKey:MGSRangeErrorKey];
	}
	
	return userInfo;
}
//=====================
// server domain
//=====================
// server domain error from code
+ (id)serverCode:(NSInteger)code
{
	return [self domain:MGSErrorDomainMotherServer code:code];
}

// server domain error from code and message
+ (id)serverCode:(NSInteger)code reason:(NSString *)message
{
	return [self domain:MGSErrorDomainMotherServer code:code reason:message log:YES];
}

// server domain error from code with user info
+ (id)serverCode:(NSInteger)code userInfo:(NSDictionary *)userDict
{
	return [self domain:MGSErrorDomainMotherServer code:code userInfo:userDict];
}

//=====================
// client domain
//=====================
// client domain error from code
+ (id)clientCode:(NSInteger)code
{
	return [self domain:MGSErrorDomainMotherClient code:code];
}

// client domain error from code and message
+ (id)clientCode:(NSInteger)code reason:(NSString *)message
{
	return [self domain:MGSErrorDomainMotherClient code:code reason:message log:YES];
}

// client domain error from code and message
+ (id)clientCode:(NSInteger)code reason:(NSString *)message log:(BOOL)logIt
{
	return [self domain:MGSErrorDomainMotherClient code:code reason:message log:logIt];
}

// client domain error from code with user info
+ (id)clientCode:(NSInteger)code userInfo:(NSDictionary *)userDict
{
	return [self domain:MGSErrorDomainMotherClient code:code userInfo:userDict];
}

//=====================
// framework domain
//=====================
// client domain error from code
+ (id)frameworkCode:(NSInteger)code
{
	return [self domain:MGSErrorDomainMotherFramework code:code];
}

// framework domain error from code and message
+ (id)frameworkCode:(NSInteger)code reason:(NSString *)message
{
	return [self domain:MGSErrorDomainMotherFramework code:code  reason:message log:YES];
}

// fromaework domain error from code with user info
+ (id)frameworkCode:(NSInteger)code userInfo:(NSDictionary *)userDict
{
	return [self domain:MGSErrorDomainMotherFramework code:code userInfo:userDict];
}



// domain error from code
+ (id)domain:(NSString *)domain code:(NSInteger)code
{
	return [self domain:domain code:code userInfo:nil];
}

/*
 
 domain error from code and reason
 
 */
+ (id)domain:(NSString *)domain code:(NSInteger)code reason:(NSString *)message log:(BOOL)logIt
{
	
	// message cannot be nil
	if (nil == message) {
		message = NSLocalizedString(@"Undefined reason for error.", @"Returned when reason for error cannot be identified");
	}
	
	NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  message,
							  NSLocalizedFailureReasonErrorKey,
							  nil];
	return [self domain:domain code:code userInfo:userDict log:logIt];
}

// domain error from code and user dict
+ (id)domain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)userDict
{
	return [self domain:domain code:code userInfo:userDict log:YES];
}
//====================================
//
// designated creator
//
// domain error with code and userinfo
// and logging
//====================================
+ (id)domain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)userDict log:(BOOL)logIt
{
	// create mutable dict and add user dict contents
	NSMutableDictionary *mutableUserDict = [NSMutableDictionary dictionaryWithCapacity:2];
	if (userDict) {
		[mutableUserDict addEntriesFromDictionary:userDict];
	}
	
	// get error message for code
	NSString *errorMessage = [self descriptionFromCode:code];
	
	// add error keys
	[mutableUserDict setObject:errorMessage forKey: NSLocalizedDescriptionKey];
	
	// create error object
	MGSError *error = [self errorWithDomain:domain code:code userInfo:mutableUserDict];
	
	// set additional properties
	error.date = [NSDate date];
    error.machineName = @"Localhost";
    
	BOOL logToConsole = logIt;
	
	// some errors we don't want to log
	if (logIt) {
		switch(code) {
				
			// don't log user space errors.
			case MGSErrorCodeScriptBuild:
				logIt = NO;
				logToConsole = NO;
				break;

			case MGSErrorCodeAuthenticationFailure:
				logIt = NO;
				logToConsole = NO;
				break;
				
			default:
				break;
				
		}
	}
	
	// log to controller
	if (logIt) {
		[error logToController];
	}
	
	// log to console
	if (logToConsole) {
		[error logToConsole];
	}
	
	return error;
}

// get description string from code
+ (NSString *)descriptionFromCode:(NSInteger)code
{
	switch (code) {
		
		case MGSErrorCodeSocketCanceledError:
			return NSLocalizedString(@"Connect error", @"Network error message");
	
		case MGSErrorCodeSocketConnectError:
			return NSLocalizedString(@"Socket connect error", @"Network error message");
			
		case MGSErrorCodeSocketReadTimeoutError:
			return NSLocalizedString(@"Read timeout error", @"Network error message");
		
		case MGSErrorCodeSocketWriteTimeoutError:
			return NSLocalizedString(@"Write timeout error", @"Network error message");
			
		case MGSErrorCodeSocketError:
			return NSLocalizedString(@"Socket error", @"Network error message");
		
		case MGSErrorCodeSocketDisconnectError:
			return NSLocalizedString(@"Socket unexpectedly disconnected", @"Network error message");
	
		case MGSErrorCodeSocketSSLPropertyError:
			return NSLocalizedString(@"Error setting stream SSL property", @"Network error message");
			
		case MGSErrorCodeTaskLaunchException:
			return NSLocalizedString(@"Task launch error", @"Server error message");

		case MGSErrorCodeAttachment:
			return NSLocalizedString(@"Attachment error", @"Client error message");
			
		case MGSErrorCodeParseRequestScript:
			return NSLocalizedString(@"Request script parse error", @"Server error message");

		case MGSErrorCodeParseRequestMessage:
			return NSLocalizedString(@"Request message parse error", @"Server error message");
		
		case MGSErrorCodeRequestPreferenceError:
			return NSLocalizedString(@"Preference request message error", @"Server error message");
			
		case MGSErrorCodeSearchError:
			return NSLocalizedString(@"Search message error", @"Server error message");
		
		case MGSErrorCodeScriptRunner:
			return NSLocalizedString(@"Script runner error", @"Server error message");
			
		case MGSErrorCodeScriptBuild:
			return NSLocalizedString(@"Script build error", @"Server error message");			
			
		case MGSErrorCodeScriptExecute:
			return NSLocalizedString(@"Script execution error", @"Server error message");			
			
		case MGSErrorCodeGetCompiledScriptSource:
			return NSLocalizedString(@"Script source retrieval error", @"Server error message");			
			
		case MGSErrorCodeInvalidScriptRepresentation:
			return NSLocalizedString(@"Operation cannot be performed. Task has an invalid script representation.", @"Request error message");
		
		case MGSErrorCodeSecureConnectionRequired:
			return NSLocalizedString(@"Secure connection required.", @"Security error message");
		
		case MGSErrorCodeRequestedSecurityNotGranted:
			return NSLocalizedString(@"Requested connection security was not granted.", @"Security error message");

        case MGSErrorCodeRequestWriteConnectionTimeout:
			return NSLocalizedString(@"Connection request to server timed out.", @"Request timeout error message");

        case MGSErrorCodeRequestWriteTimeout:
			return NSLocalizedString(@"Request data write to server timed out.", @"Request timeout error message");

        case MGSErrorCodeRequestTimeout:
			return NSLocalizedString(@"Request timed out.", @"Request timeout error message");
            
		case MGSErrorCodeBadRequestFormat:
			return NSLocalizedString(@"Invalid request format.", @"Request format error");
			
		case MGSErrorCodeSaveScript:
			return NSLocalizedString(@"Script save error", @"Server error message");	

		case MGSErrorCodeGetScript:
			return NSLocalizedString(@"Script retrieval error", @"Server error message");	

		case MGSErrorCodeLoadScriptFromFile:
			return NSLocalizedString(@"Script load error", @"Server error message");	
		
		case MGSErrorCodeTrialRestrictionImposed:
			return NSLocalizedString(@"Trial restriction imposed", @"Server error message");	
			
		case MGSErrorCodeLicenceRestrictionImposed:
			return NSLocalizedString(@"Licence restriction imposed", @"Server error message");	

		case MGSErrorCodeCompiledScriptSourceRTFMissing:
			return NSLocalizedString(@"Compiled script source RTF missing", @"Server error message");	
	
		case MGSErrorCodeCompiledScriptDataMissing:
			return NSLocalizedString(@"Compiled script data missing", @"Server error message");	
			
		case MGSErrorCodeSendRequestMessage:
			return NSLocalizedString(@"Request message send error", @"Client error message");
			
		case MGSErrorCodeProcessMessage:
			return NSLocalizedString(@"Message processing error", @"Framework error message");
			
		case MGSErrorCodeAuthenticationFailure:
			return NSLocalizedString(@"Authentication failure", @"Framework error message");
			
		case MGSErrorCodeInvalidCommandReply:
			return NSLocalizedString(@"Reply does not match expected type for command", @"Error message");
		
		case MGSErrorCodeParseRequestPreferences:
			return NSLocalizedString(@"Request preference parse error", @"Server error message");
		
		case MGSErrorCodeDefaultRequestError:
			return NSLocalizedString(@"General request error", @"Request error message");
			
		case MGSErrorCodePlugin:
			return NSLocalizedString(@"Plugin error error", @"Plugin error message");	

		case MGSErrorCodeExportPlugin:
			return NSLocalizedString(@"Export plugin error error", @"Plugin error message");	
			
		case MGSErrorCodeSendPlugin:
			return NSLocalizedString(@"Send error error", @"Plugin error message");	
			
		case MGSLicenceCopyError:
			return NSLocalizedString(@"Could not copy licence", @"Licence error message");	
		
		case MGSLicenceRemovalError:
			return NSLocalizedString(@"Could not remove licence", @"Licence error message");
			
		case MGSErrorCodeParameterPlugin:
			return NSLocalizedString(@"Parameter plugin error", @"Licence error message");
		
		// message errors
		case MGSErrorCodeMessageBadData:
			return NSLocalizedString(@"Message data error", @"Message error message");
			
		// exceptions
		case MGSErrorCodeClientException:
			return NSLocalizedString(@"A client exception has occurred", @"Client exception has occurred");

		case MGSErrorCodeServerException:
			return NSLocalizedString(@"A server exception has occurred", @"Server exception has occurred");
			
		case MGSErrorCodeServerUnknown:
			return NSLocalizedString(@"An unidentified server error has occurred", @"Server unidentified error has occurred");

		// application errors
		case MGSErrorCodeCannotConnectToService:
			return NSLocalizedString(@"Cannot connect to published service.", @"Application error");
			
			
	}
			
	return NSLocalizedString(@"Undefined error", @"Returned when error cannot be identified");
}

#pragma mark -
#pragma mark Instance methods

// string representation of error
- (NSString *)stringValue
{
	NSString *error = nil;
	NSString *format = nil;
	
	// prepend reason for failure if available
	NSString *failureReason = [[self localizedFailureReason] mgs_stringTerminatedWithPeriod];
	if (failureReason) {
		failureReason = [NSString stringWithFormat:@"%@ ", failureReason];
	} else {
		failureReason = @"";
	}
	
	// format error
	format = NSLocalizedString(@"%@Desc: %@ Code: %i. Source: %@", @"MGSError string value output format"); ;
	error = [NSString stringWithFormat:format, failureReason, [[self localizedDescription] mgs_stringTerminatedWithPeriod], [self code], [[self domain] mgs_stringTerminatedWithPeriod]];
	
	return error;
}

/*
 
 - stringValuePreview
 
 */
- (NSString *)stringValuePreview
{
	NSString *error = nil;
	NSString *format = nil;
	
	// prepend reason for failure if available
	NSString *failureReason = [self localizedFailureReasonPreview];
	failureReason = [[self localizedFailureReasonPreview] mgs_stringTerminatedWithPeriod];
	if (failureReason) {
		failureReason = [NSString stringWithFormat:@"%@ ", failureReason];
	} else {
		failureReason = @"";
	}
	
	// format error
	format = NSLocalizedString(@"%@Desc: %@ Code: %i. Source: %@", @"MGSError string value output format"); 
	error = [NSString stringWithFormat:format, failureReason, [[self localizedDescription] mgs_stringTerminatedWithPeriod], [self code], [[self domain] mgs_stringTerminatedWithPeriod]];
	
	return error;
}

/*
 
 - localizedFailureReason
 
 */
- (NSString *)localizedFailureReason
{
	if (![super localizedFailureReason]) {
		return NSLocalizedString(@"No localized failure reason available.", @"MGSError no localized failure reason available");
	}
	
	return [super localizedFailureReason];
}

/*
 
 - localizedFailureReasonPreview
 
 */
- (NSString *)localizedFailureReasonPreview
{
	NSString *reason = [self localizedFailureReason];
	reason = [reason mgs_stringByRemovingNewLinesAndTabs];
	
	return reason;
}

/*
 
 dictionary 
 
 */
- (NSDictionary *)dictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self domain], MGSDomainErrorKey,
			[NSNumber numberWithInt:[self code]], MGSCodeErrorKey,
			[self userInfo], MGSUserInfoErrorKey,
			nil];
}

/*
 
 resultDictionary
 
 Dictionary with objects and keys suitable for display.
 Useful when bound to an NSDictionaryController
 
 */
- (NSDictionary *)resultDictionary
{
	NSMutableDictionary *displayDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										NSLocalizedString(@"Error", @"Error"),  NSLocalizedString(@"Result", @"Result"),
										[self domain], NSLocalizedString(@"Source", @"Source of error"),
										[NSNumber numberWithInt:[self code]], NSLocalizedString(@"Code", @"Error code"),
										nil];
	
	id description = [[self userInfo] objectForKey:NSLocalizedDescriptionKey];
	id reason = [[self userInfo] objectForKey:NSLocalizedFailureReasonErrorKey];
	
	if (description) [displayDict setObject:description forKey:NSLocalizedString(@"Description", @"Error description")];
	if (reason) [displayDict setObject:reason forKey:NSLocalizedString(@"Reason", @"Error reason")];
	
	return displayDict;
}

#pragma mark -
#pragma mark Logging
/*
 
 - log
 
 */
- (void)log
{
	[self logToController];
	[self logToConsole];
}

/*
 
 - logToController
 
 */
- (void)logToController
{
	if (!_controller) return;
	if (self.flags & kLoggedToController) return;
		
	[_controller addError:self];
	self.flags |= kLoggedToController;
}

/*
 
 - logToConsole
 
 */
- (void)logToConsole
{
	if (self.flags & kLoggedToConsole) return;
	
	NSString *logErrorFormat = NSLocalizedString(@"ERROR: %@", @"Error log string format"); 
	NSString *logError = [NSString stringWithFormat:logErrorFormat, [self stringValue]];
	
	// log error can contain format specifiers, say as the result of a failed compilation
	// so make sure that we DON't do
	// MLog(RELEASELOG, logError);
	// as the unanticipated format specifiers will cause runtime failure as the va_list
	// looks for matching data
	MLogInfo(@"%@", logError);
	
	self.flags |= kLoggedToConsole;
}
@end


