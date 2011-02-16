//
//  MGSNetRequest+KosmicTask.m
//  KosmicTask
//
//  Created by Jonathan on 26/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSNetRequest+KosmicTask.h"
#import "MGSScript.h"
#import "MGSNetNegotiator.h"
#import "MGSNetMessage.h"
#import "MGSNetClient.h"
#import "MGSNetMessage+KosmicTask.h"

@implementation MGSNetRequest (KosmicTask)

#pragma mark -
#pragma mark Negotiation

/*
 
 - prepareConnectionNegotiation
 
 */
- (BOOL)prepareConnectionNegotiation
{
	// if we already have a negotiate request
	if ([self queuedNegotiateRequest]) {
		return YES;
	}
	
	// validate the request - raises on error.
	[self.requestMessage validate];
	
	NSString *command = self.requestCommand;
	
	/*
	 
	 no negotiation required for some commands
	 
	 */
	if ([command isEqualToString:MGSNetMessageCommandHeartbeat]) {
		return YES;
	}
	
	/*
	 
	 Prepare the negotitate request.
	 This will be sent before the main request to negotitate terms for the exchange.
	 
	 */
	
	// allocate negotiate request
	MGSNetRequest *negotiateRequest = [self enqueueNegotiateRequest]; 
	NSAssert(negotiateRequest, @"could not allocate negotiate request");
	
	/*
	 
	 If command based negotiation is to be used then we may need
	 to send additional command data
	 
	 */
	if ([self commandBasedNegotiation]) {

		// KosmicTask dictionary processing
		if ([command isEqualToString:MGSNetMessageCommandParseKosmicTask]) {
			
			// get the task dictionary from the request
			NSDictionary *taskDict = [self.requestMessage messageObjectForKey:MGSScriptKeyKosmicTask];
			
			// the script object is discretionary
			MGSScript *script = nil, *negoScript = nil;
			NSDictionary *scriptDict = [taskDict objectForKey:MGSScriptKeyScript];
			if (scriptDict) {
				NSMutableDictionary *scriptDictMutable = [NSMutableDictionary dictionaryWithDictionary:scriptDict];
				script = [MGSScript scriptWithDictionary:scriptDictMutable];		
			}
			
			// if we have a script then get a negotiate representation
			if (script) {
				
				// copy the script?
				negoScript = [script mutableDeepCopy];
				
				// get a negotiate representation of the script 
				if (![negoScript conformToRepresentation:MGSScriptRepresentationNegotiate]) {
					NSAssert(NO, @"cannot build script negotiate representation");
				}
			} 
			
			// copy taskDict to negotiate task dictionary
			NSMutableDictionary *negoTaskDict = [NSMutableDictionary dictionaryWithDictionary:taskDict];
			if (negoScript) {
				
				// replace the script object with negotiate script representation
				[negoTaskDict setObject:[negoScript dict] forKey:MGSScriptKeyScript];
			}
			[negotiateRequest.requestMessage setMessageObject:negoTaskDict forKey:MGSScriptKeyKosmicTask];
			
		} 
	}
	
	// build negotiator
	MGSNetNegotiator *negotiator = [[MGSNetNegotiator alloc] init];
	
	BOOL secure = NO;
	
	// if we are sending an authentication dictionary then 
	// we request security
	if ([self.requestMessage authenticationDictionary] || 
		[command isEqualToString:MGSNetMessageCommandAuthenticate]) {
		
		// we do not encrypt the localhost traffic by default
		if (![self.netClient isLocalHost]) {
			secure = YES;
		}
	} 

	// use security if requested by client
	if ([self.netClient useSSL] && ![self.netClient isLocalHost]) {
		secure = YES;
	}
	
	if (secure) {
		[negotiator setSecurityType:MGSNetMessageNegotiateSecurityTLS];
	}
	
	// apply negotiator to request message
	[negotiateRequest.requestMessage applyNegotiator:negotiator];
	
	return YES;
	
}

@end
