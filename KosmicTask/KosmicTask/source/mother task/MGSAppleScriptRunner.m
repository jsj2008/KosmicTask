//
//  MGSAppleScriptRunner.m
//  Mother
//
//  Created by Jonathan on 01/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//
#import "MGSAppleScriptRunner.h"
#import "MGSAppleScriptData.h"
#import "MGSAppleScriptData.h"
#import "TaskRunner.h"
#import "MGSLanguagePropertyManager.h"
#import "MGSLanguage.h"
#import "MGSAppleScriptLanguage.h"

//#define RUN_USER_INTERACTION_TEST

OSErr MGSCustomSendProc( const AppleEvent *anAppleEvent, AppleEvent *aReply, AESendMode aSendMode, AESendPriority aSendPriority, long aTimeOutInTicks, AEIdleUPP anIdleProc, AEFilterUPP aFilterProc, long aSelf );

@interface MGSAppleScriptRunner()
- (void)handleLogEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent;
@end

@implementation MGSAppleScriptRunner

/*
 
 user info from AppleScript error dictionary
 
 */
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

/*
 
 init with dictionary
 
 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super initWithDictionary:dictionary])) {
		self.scriptExecutableExtension = @"scpt";
		self.scriptSourceExtension = @"applescript";

	}
	return self;
}

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSAppleScriptLanguage class];
}

/*
 
 execute the task
 
 */
- (BOOL) execute {

	// get script onRun mode
	NSNumber *onRunNumber = [self.taskDict objectForKey:MGSScriptOnRun];
	if (!onRunNumber) {
		self.error = NSLocalizedString(@"no onRun in task dictionary", @"Script task process error");
		return NO;
	}
	
	// determine script entry point
	NSString *subroutine = nil;
	eMGSOnRunTask onRun = [onRunNumber integerValue];
	switch (onRun) {
			
		case kMGSOnRunCallScript:
			break;
			
		case kMGSOnRunCallScriptFunction:;
			// get script subroutine
			subroutine = [self.taskDict objectForKey:MGSScriptSubroutine];
			if (!subroutine) {
				self.error = NSLocalizedString(@"no subroutine in task dictionary", @"Script task process error");
				return NO;
			}
			break;
			
		default:
			self.error = NSLocalizedString(@"invalid onRun mode requested", @"Script task process error");
			return NO;
			
	}
	
	
	// get script parameter array
	NSArray *paramArray = [self.taskDict objectForKey:MGSScriptParameters];
	if (!paramArray) {
		self.error = NSLocalizedString(@"no parameters in task dictionary", @"Script task process error");
		return NO;
	}
	
	// get executable script data
	NSData *compiledData = [self.taskDict objectForKey:MGSScriptExecutable];
	if (!compiledData) {
		self.error = NSLocalizedString(@"script executable data missing", @"Script task process error");
		return NO;
	}
	
	//
	// test if user interaction can occur.
	// it seems to be that user interaction cannot occurr in a simple foundation tool.
	// see MID: 613 http://projects.mugginsoft.net/view.php?id=613
	//
	// resolved: see [MGSAppleScriptRunner transformToForegroundApplication]
	//
#ifdef RUN_USER_INTERACTION_TEST
	
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:@"display dialog \"hello\""];
	NSDictionary *errorDict = nil;
	[as executeAndReturnError:&errorDict];
	if (errorDict) {
		self.error = NSLocalizedString(@"Test applescript failed", @"Script task process error");
		return NO;
	}
	
#endif

	//
	// allocate script context and initialise with compiled script data
	//
	NDScriptContext *appleScriptObject = [[[NDScriptContext alloc] initWithData:compiledData] autorelease];
	
	//
	// determine if request origin is the localhost
	//
	NSNumber *originIsLocalHostNumber = [self.taskDict objectForKey:MGSScriptOriginIsLocalHost];
	BOOL originIsLocal = [originIsLocalHostNumber boolValue];
	
	//
	// set user interaction mode
	//
	NSNumber *userInteractionNumber = [self.taskDict objectForKey:MGSScriptUserInteraction];
	if (userInteractionNumber) {
		
		NSInteger userInteractionMode = [userInteractionNumber integerValue];
		BOOL interactionAllowed = NO;
		
		switch (userInteractionMode) {
				
				// do not want any user interaction. 
				// if errors occur or app dictionaries cannot be found then
				// simply return an error
			case kMGSScriptUserModeNeverInteract:
				interactionAllowed = NO;
				break;
				
				// allow user interaction for script requests originating on localhost
			case kMGSScriptUserModeCanInteractIfLocal:
				if (originIsLocal) {
					interactionAllowed = YES;
				}
				break;
				
				// allow user interaction
			default:
			case kMGSScriptUserModeCanInteract:
				interactionAllowed = YES;
				break;
		}
		
		
		if (interactionAllowed) {
			//
			// we launch as a foundation tool.
			// if we require to interact with the user and display dialogs we required
			// 1. to become a foreforund app
			// 2. to connect to the window server
			//
			// even if we set kMGSScriptUserModeAlwaysInteract interaction is disallowed if
			// we are not connected to the window server.
			//
			// so if interaction is required we install a OSA component instance send proc handler.
			// this detects when interaction is disallowed, transforms the process as required
			// and then resends the event
			//
			[appleScriptObject setExecutionModeCanInteract:YES];
			//
			// send a custom send proc.
			// this will enable us to filter events as required
			//
			[[appleScriptObject componentInstance] setSendProc:(OSASendUPP)MGSCustomSendProc];
		} else {
			[appleScriptObject setExecutionModeNeverInteract:YES];
		}
			
	}

	
	// redirect stdout to stderr
	[self redirectStdOutToStdErr];
	
	// execute the script
	BOOL executeSuccess = NO;
	
	// register log handler for the log event.
	// AppleScript Editor handles the log event as does osascript.
	// in order to respond to it we just install a handler.
	[[NSAppleEventManager sharedAppleEventManager] 
	 setEventHandler:self andSelector:@selector(handleLogEvent:withReplyEvent:) 
	 forEventClass:'ascr' 
	 andEventID:'cmnt'];
	
	// if the subroutine is named run then the run handler is called
	if (subroutine == nil || [subroutine compare:MGSScriptSubroutineRun] == NSOrderedSame) {
		
		// calling the run handler is equivalent to sending the script an application open event
		executeSuccess = [appleScriptObject executeAppOpen:paramArray];
	} else {
		
		// call the named subroutine
		executeSuccess = [appleScriptObject executeSubroutineNamed:subroutine argumentsArray:paramArray];
	}
	
	// restore stdout
	[self restoreStdOut];

	//
	// handle failure
	//
	if (!executeSuccess) {
		NSMutableDictionary *userInfo = nil;
		
		// error for response
		self.error = NSLocalizedString(@"script execute error", @"Script task process error");
		
		// if the requested handler cannot be found in the event then errAEEventNotHandled is returned.
		// calling [appleScriptObject error] in this case returns no info as the event was not executed.
		if ([appleScriptObject resultError] == errAEEventNotHandled) {
			userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
			[userInfo setObject:[NSString stringWithFormat:NSLocalizedString(@"Could not find handler \"%@\"", @"Error message returned to user when script event handler not found"), subroutine]
						 forKey:NSLocalizedFailureReasonErrorKey];
		} else {
			
			// local error
			userInfo = [[self class] userInfoFromAppleScriptErrorDict:[appleScriptObject error]];
		}
		self.errorInfo = userInfo;
		
		return NO;
	}
	
	//
	// get script result.
	// the AppleEvent is coerced into a Cocoa object
	//
	id resultObject = [appleScriptObject aemResultObject];
	if (resultObject) {
		
		//MLog(DEBUGLOG, @"initial script result object =  %@", resultObject);
		NSAttributedString *resultScriptSource = nil;

		// if the result is an event descriptor then the result object
		// could not be translated to a cocoa object
		if ([resultObject isKindOfClass:[NSAppleEventDescriptor class]]) {
			self.error = NSLocalizedString(@"Cannot convert result for display", @"cannot convert AppleScript return value to cocoa type");
			return NO;
		} else {
			
			//
			// convert apple event codes
			//
			resultObject = [appleScriptObject resolveEventCodes:resultObject];
			
			//
			// dictionary MUST be serializable.
			// if it isn't then coerce it into a plist
			//
			if (![NSPropertyListSerialization propertyList:resultObject isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
				resultObject = [NSPropertyListSerialization coercePropertyList:resultObject];
			}
		}
		
		//MLog(DEBUGLOG, @"final script result object =  %@", resultObject);
		
		
		//
		// get script data representing the result.
		// this is the actual data returned by the script.
		// we want a textual representation of this.
		//
		NDScriptData *resultScriptData = [appleScriptObject resultScriptData];
		if (resultScriptData) {
			
			// if we compile the result we can get a better source representation of the data
			// especially if it contains event class info such as «class siav» etc
			NDComponentInstance *componentInstance = [NDComponentInstance findNextComponentInstance];
			NDScriptContext *resultContext = [[NDScriptContext alloc] initWithSource:[[resultScriptData attributedSource] string] modeFlags:(kOSAModeNeverInteract | kOSAModeCompileIntoContext) componentInstance:componentInstance];
			[resultContext autorelease];
			
			BOOL scriptCompiled = resultContext ? YES : NO;
			
			if (scriptCompiled) {
				
				// dont check if [resultContext data] exists here.
				// we can easily generate a result item that causes an error of the form
				// (errOSAInternalTableOverflow) A runtime internal data structure overflowed.
				// the attributed source remains valid though.
				resultScriptSource = (NSAttributedString *)[resultContext attributedSource];
			} else {
				
				// get result source
				resultScriptSource = (NSAttributedString *)[resultScriptData attributedSource];
			}
		}

		// get default result script source if reqd
		if (!resultScriptSource) {
			resultScriptSource = [[[NSAttributedString alloc] initWithString: 
							  NSLocalizedString(@"No result script available", @"default result script text")] autorelease];
		}

		// get result source RTF
		NSRange range = NSMakeRange(0, [resultScriptSource length]);
		NSData *resultSourceRTF = [resultScriptSource RTFFromRange:range documentAttributes:nil];
		
		// form result dict
		NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithCapacity:2];

		// add result source RTF
		if (resultSourceRTF) {
			[resultDict setObject:resultSourceRTF forKey:MGSScriptKeySourceRTFData];
		}
		
		// add result object
		if (resultObject) {
			[resultDict setObject:resultObject forKey:MGSScriptKeyResultObject];
		}
		
		// add result dict to reply
		[self.replyDict setObject:resultDict forKey:MGSScriptKeyResult];
	}
	
	return YES; 
	
}


/*
 
 compile the task
 
 */
- (BOOL)build 
{
	// get the source
	NSString *source = [self.taskDict objectForKey:MGSScriptSource];
	if (source == nil || [source length] == 0) {
		self.error = NSLocalizedString(@"no source in task dictionary", @"Script task process error");
		return NO;
	}
	
	NDScriptContext *appleScriptObject = nil;	
	NDComponentInstance *componentInstance = nil;

	
	@try {
				
		// compile it
		
		//==============================================================================
		// compile the script
		//
		// the kOSAModeNeverInteract flag ensures that the OSA component will not try
		// to interact with the user by, say, showing the Choose Application dialog.
		//
		// without kOSAModeCompileIntoContext flag the compiled script does not seem to 
		// execute
		//===============================================================================
		BOOL scriptCompiled = NO;
		
		componentInstance = [NDComponentInstance findNextComponentInstance];
		if (!componentInstance) {
			self.error = NSLocalizedString(@"Cannot allocate AppleScript component instance", @"Component instance is invalid");
			return NO;
		}
		appleScriptObject = [[NDScriptContext alloc] initWithSource:source modeFlags:(kOSAModeNeverInteract | kOSAModeCompileIntoContext) componentInstance:componentInstance];	
		scriptCompiled = appleScriptObject ? YES : NO;
		
		if (scriptCompiled) {
			
			// get script compiled data
			NSData *scriptData = [appleScriptObject data];
			if (nil == scriptData) {
				self.error = NSLocalizedString(@"Compiled script data is invalid", @"Compiled script is nil");
				return NO;
			}
			
			// get script source.
			// compilation may have changed the source representation.
			NSAttributedString *attributedSource = (NSAttributedString *)[appleScriptObject attributedSource];

#define MGS_RETURN_SOURCE_AS_RTF
#ifdef MGS_RETURN_SOURCE_AS_RTF
			
			NSRange range = NSMakeRange(0, [attributedSource length]);
			NSData *rtfSource = [attributedSource RTFFromRange:range documentAttributes:nil];
			if (nil == rtfSource) {
				self.error = NSLocalizedString(@"Compiled script source is invalid", @"Compiled script source is nil");
				return NO;
			}

			// return the rtf source
			[self.replyDict setObject:rtfSource forKey:MGSScriptKeyCompiledScriptSourceRTF];
#else
			
			NSString *stringSource = [attributedSource string];
			if (nil == stringSource) {
				self.error = NSLocalizedString(@"Compiled script source is invalid", @"Compiled script source is nil");
				return NO;
			}
			
			// return the string source
			[self.replyDict setObject:stringSource forKey:MGSScriptKeyScriptSource];

#endif
			// script data
			[self.replyDict setObject:scriptData forKey:MGSScriptKeyCompiledScript];
			
		} else {
			
			NSMutableDictionary *userInfo = [[self class] userInfoFromAppleScriptErrorDict:[componentInstance error]];
						
			// get the error dict
			//self.mgsError = [MGSError serverCode:self.errorCode userInfo:userInfo];
			self.errorInfo = userInfo;
			
			return NO;
		}
				
	}
	@catch (NSException *e)
	{
		self.error = [e reason];
		return NO;
	}
	@finally
	{
	}
		
	return YES;
}

/*
 
 - handleLogEvent:withReplyEvent:
 
 */
- (void)handleLogEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
#pragma unused(replyEvent)
	/*
	 Applescript log command will send the log event to AppleScript.
	 Default implementation discards it.
	 Hence this handler.
	 
	 */
	// get the log value
    NSString* value = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	
	// output to stderr
	fputs([value cStringUsingEncoding:NSUTF8StringEncoding], stderr);
}
@end

/*
 * function MGSCustomSendProc
 */
OSErr MGSCustomSendProc( const AppleEvent *anAppleEvent, AppleEvent *aReply, AESendMode aSendMode, AESendPriority aSendPriority, long aTimeOutInTicks, AEIdleUPP anIdleProc, AEFilterUPP aFilterProc, long refCon )
{
	#pragma unused(refCon)
	
	OSErr result = noErr;
	
	// send the event as normal
	result = AESend(anAppleEvent, aReply, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc);

	//
	// look for no user interaction required.
	// if the user interaction was disallowed then transform the process
	// into a foreground application
	//
	if (result == errAENoUserInteraction && ![MGSAppleScriptRunner isForegroundApplication]) {

		// transform to foreground application to allow for user interaction
		if ([MGSAppleScriptRunner transformToForegroundApplication]) {
		
			// resend the event 
			result = AESend(anAppleEvent, aReply, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc);
		}
	}
	
	return result;
}
