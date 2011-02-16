//
//  MGSAuthentication.m
//  Mother
//
//  Created by Jonathan on 22/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSAuthentication.h"
#include "CRAMMD5helper.h"
#include "serverauthenticate.h"
#include <DirectoryService/DirServicesTypes.h>
#include "MGSAuthenticateWindowController.h"
#include "MGSNetClient.h"
#import "NSString-Base64Extensions.h"
#import "NSData-Base64Extensions.h"
#import "MGSKeyChain.h"
#import "MGSSystem.h"

static MGSAuthentication *_sharedController = nil;

const NSString *MGSAuthenticationKeyChallenge = @"Challenge";
const NSString *MGSAuthenticationKeyAlgorithm = @"Algorithm";

const NSString *MGSAuthenticationKeyUsername = @"Username";
const NSString *MGSAuthenticationKeyResponse = @"Response";
const NSString *MGSAuthenticationKeyPassword = @"Password";

// algorithms
const NSString *MGSAuthenticationCRAM_MD5 = @"CRAM-MD5";
const NSString *MGSAuthenticationClearText = @"ClearText";

@implementation MGSAuthentication

+ (id)sharedController
{
	if (!_sharedController) {
		_sharedController = [[self alloc] init];
	}
	return _sharedController;
}

+ (NSString *)localHost
{
	return @"localhost";
}

- (BOOL)authenticateLocalHostWithDictionary:(NSDictionary *)authDict
{
	NSString *usernameBase64 = [authDict objectForKey:MGSAuthenticationKeyUsername];
	NSString *username = [[NSString alloc] initWithData:[usernameBase64 decodeBase64WithNewlines:NO] encoding:NSUTF8StringEncoding];
	NSString *passwordBase64 = [authDict objectForKey:MGSAuthenticationKeyPassword];
	NSString *password = [[NSString alloc] initWithData:[passwordBase64 decodeBase64WithNewlines:NO] encoding:NSUTF8StringEncoding];

	NSString *algorithm = [authDict objectForKey:MGSAuthenticationKeyAlgorithm];
	
	// validate
	if (!username || !algorithm || !password) { 
		return NO;
	}
	
	if (NSOrderedSame == [algorithm caseInsensitiveCompare:(NSString *)MGSAuthenticationClearText]) {
		if ([username isEqual:[MGSAuthentication localHost]] && [password isEqual:[MGSAuthentication localHost]]) {
			return YES;
		}
	}
	
	return [self authenticateWithDictionary: authDict];
}

// use dictionary to authenticate
- (BOOL)authenticateWithDictionary:(NSDictionary *)authDict
{
	NSString *usernameBase64 = [authDict objectForKey:MGSAuthenticationKeyUsername];
	NSString *algorithm = [authDict objectForKey:MGSAuthenticationKeyAlgorithm];
	NSString *username = [[NSString alloc] initWithData:[usernameBase64 decodeBase64WithNewlines:NO] encoding:NSUTF8StringEncoding];

	// validate
	if (!username || !algorithm) { 
		return NO;
	}
	
	// server will only validate for the current user
	if (NO == [username isEqualToString:NSUserName()]) {
		return NO;
	}
	
	
	// authenticate according to algorithm
	
	// CRAM-MD5
	// DUMMY! only works on OS X server
	// anyhow, easy to simply replay the encrypted password without HTTP nonce type augmentation
	if (NSOrderedSame == [algorithm caseInsensitiveCompare:(NSString *)MGSAuthenticationCRAM_MD5]) {		
		NSString *response = [authDict objectForKey:MGSAuthenticationKeyResponse];
		NSString *challenge = [authDict objectForKey:MGSAuthenticationKeyChallenge];
		
		// validate
		if (!response || !challenge) { 
			return NO;
		}
		return [self authenticateCRAMMD5ForUsername: username challenge:challenge response:response];
	
	// clear text
	} else if (NSOrderedSame == [algorithm caseInsensitiveCompare:(NSString *)MGSAuthenticationClearText]) {
		
		// get password
		NSString *passwordBase64 = [authDict objectForKey:MGSAuthenticationKeyPassword];
		
		// validate
		if (!passwordBase64) { 
			return NO;
		}
		
		// decode base64
		NSString *password = [[NSString alloc] initWithData:[passwordBase64 decodeBase64WithNewlines:NO] encoding:NSUTF8StringEncoding];
		
		return [self authenticateClearTextForUsername: username password:password];		
	}

	return NO;
}

// authenticate CRAM-MD5
- (BOOL)authenticateCRAMMD5ForUsername:(NSString *)username challenge:(NSString *)challenge response:(NSString *)response
{
	char *inUsername = (char *)[username UTF8String];
	char *inChallenge = (char *)[challenge UTF8String];
	char *inResponse = (char *)[response UTF8String];
	
	int authReturn = AuthCRAMMD5(inUsername, inChallenge, inResponse);
	if (eDSNoErr == authReturn) {
		return YES;
	}
	
	return NO;
}

// authenticate clear text
- (BOOL)authenticateClearTextForUsername:(NSString *)username password:(NSString *)password
{
	char *inUsername = (char *)[username UTF8String];
	char *inPassword = (char *)[password UTF8String];
	
	int authReturn = AuthCleartext(inUsername, inPassword);
	if (eDSNoErr == authReturn) {
		return YES;
	}
	
	return NO;
}

// form authentication challenge dictionary
- (NSDictionary *)authenticationChallenge:(NSString *)algorithm
{
	NSDictionary *authChallenge = nil;
	NSString *challenge;
	
	// CRAM-MD5 
	if (NSOrderedSame == [algorithm caseInsensitiveCompare:(NSString *)MGSAuthenticationCRAM_MD5]) {
			
		challenge = [self CRAM_MD5Challenge];
		
		NSAssert(challenge, @"challenge is nil");
		authChallenge = [NSDictionary dictionaryWithObjectsAndKeys:
									   MGSAuthenticationCRAM_MD5, MGSAuthenticationKeyAlgorithm,
									   challenge, MGSAuthenticationKeyChallenge,
									   nil];	
	}
	
	// clear text etc
	else {
		// no challenge generated
		;
	}
	
	return authChallenge;
}

// generate a challenge for use with CRAM-MD5
- (NSString *)CRAM_MD5Challenge
{
	// Since CRAM-MD5 was requested, let's generate a challenge and send it to the client
	// using example method in RFC 1460, page 12.
	//gethostname( pHostname, 127 );
	//gettimeofday( &stCurrentTime, NULL ); // assume no error occurred
	//snprintf( pChallenge, 255, "<%ld.%ld@%s>", (long) getpid(), stCurrentTime.tv_sec, pHostname );
	NSString *hostname = [[MGSSystem sharedInstance] localHostName];
	NSProcessInfo *pinfo = [NSProcessInfo processInfo];
	NSString *challenge = [NSString stringWithFormat:@"%@.%@.%@", [pinfo globallyUniqueString], [NSDate date], hostname];
	return challenge;
}

// form response to challenge
- (NSDictionary *)responseToChallenge:(NSDictionary *)challengeDict password:(NSString *)password username:(NSString *)username
{
	NSDictionary *authDict = nil;
	NSString *algorithm = [challengeDict objectForKey:MGSAuthenticationKeyAlgorithm];
	NSString *challenge = [challengeDict objectForKey:MGSAuthenticationKeyChallenge];
	
	// validate
	if (!algorithm || !challenge || !password || !username) { 
		return nil;
	}

	// CRAM-MD5
	if (NSOrderedSame == [algorithm caseInsensitiveCompare:(NSString *)MGSAuthenticationCRAM_MD5]) {		

		// calc the MD5 digest of the challenge using our password
		const char *inChallenge = [challenge UTF8String];
		long inChallengeLen = [challenge lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
		const char *inPassword = [password UTF8String];
		long inPasswordLen = [password lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

		// zero out the hash buffer in advance
		unsigned char	pHash[17]		= { 0, };
		unsigned char	pHashHex[33]	= { 0, };
		bzero( pHash, 17 );

		CalcMD5(inChallenge, inChallengeLen, inPassword, inPasswordLen, pHash);

		// Prepare a Hex string representation of the hash, grouping into 2-byte Hex values.
		bzero( pHashHex, 33 );
		int i;
		for( i=0; i < 16; i++ ) {
			sprintf( (char *)&pHashHex[i<<1], "%02x", pHash[i]);
		}

		// Add the NULL terminator
		pHashHex[32] = 0; 

		NSString *response = [NSString stringWithCString:(char *)pHashHex encoding:NSUTF8StringEncoding];
		
		// form the authentication dictionary 
		authDict = [NSDictionary dictionaryWithObjectsAndKeys:
								  username, MGSAuthenticationKeyUsername,
								  MGSAuthenticationCRAM_MD5, MGSAuthenticationKeyAlgorithm,
								  response, MGSAuthenticationKeyResponse,
								  challenge, MGSAuthenticationKeyChallenge,
								  nil];
	}

	return authDict;
}

/*
 
 response to authentication challenge
 
 the response dictionary only contains the username.
 in order to complete the dictionary for use during authentication the result of this message must
 be passed to authDictionaryforSessionService
 
 */
- (NSDictionary *)responseDictionaryforSessionService:(NSString *)service password:(NSString *)password username:(NSString *)username
{

	// validate
	if (!password || !username) { 
		return nil;
	}
	
	// save session username and password to keychain.
	// we will retrieve this later when required.
	// on occasion this call rather unpredicatbly returns nil when for
	// some reason a new item cannot be created in the keychain.
//#warning failure here on occasion
	if (![MGSKeyChain addService:[MGSKeyChain sessionService:service] withUsername:username password:password]) {
		NSAssert(NO, @"Cannot add session details to keychain.");
	}
	
	// we will restore the password from the keychain when required using -authDictionaryforService:withDictionary:
	NSString *usernameBase64 = [[username dataUsingEncoding:NSUTF8StringEncoding] encodeBase64WithNewlines:NO];
	
	// form the authentication dictionary 
	NSDictionary *authDict = [NSDictionary dictionaryWithObjectsAndKeys:
								usernameBase64, MGSAuthenticationKeyUsername,
								MGSAuthenticationClearText, MGSAuthenticationKeyAlgorithm,
								nil];
	
	return authDict;
}
/*
 
 auth dictionary for session service with dictionary
 
 */
- (NSDictionary *)authDictionaryforSessionService:(NSString *)service withDictionary:(NSDictionary *)authDict
{
	return [self authDictionaryforService:[MGSKeyChain sessionService:service] withDictionary:authDict];
}

/*
 
 auth dictionary for service with dictionary
 
 this methods retrieves a complete authentication dictionary using authDict as a template.
 
 in particular the user password is retrieved from the keychain and added to the authDict.
 
 */
- (NSDictionary *)authDictionaryforService:(NSString *)service withDictionary:(NSDictionary *)authDict
{
	NSString *usernameBase64 = [authDict objectForKey:MGSAuthenticationKeyUsername];
	if (!usernameBase64) {
		NSLog(@"Error: auth dictionary username is nil");
		return nil;
	}
	
	// decode username
	NSString *username = [[NSString alloc] initWithData:[usernameBase64 decodeBase64WithNewlines:NO] encoding:NSUTF8StringEncoding];

	// get password for service
	NSString *password = [MGSKeyChain passwordForService:service withUsername:username];
	if (!password) {
		NSLog(@"Error: auth dictionary validator is nil");
		return nil;
	}
	
	NSString *passwordBase64 = [[password dataUsingEncoding:NSUTF8StringEncoding] encodeBase64WithNewlines:NO];

	// add password to auth dictionary
	NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:authDict];
	[newDict setObject:passwordBase64 forKey:MGSAuthenticationKeyPassword];
	
	return [NSDictionary dictionaryWithDictionary:newDict];
}
/*
 
 delete the session password for the service
 
 */
- (BOOL)deleteKeychainSessionPasswordForService:(NSString *)service
{
	NSString *password = nil, *username = nil;
	NSString *sessionService = [MGSKeyChain sessionService:service];
	
	[self credentialsForService:sessionService password:&password username:&username];
	if (!username) return NO;
	
	// delete the password from the keychain
	return [MGSKeyChain deleteService:sessionService withUsername:username];
}

/*
 
 delete the session password for the authentication dictionary
 
 */
- (BOOL)deleteKeychainSessionPasswordForService:(NSString *)service withDictionary:(NSDictionary *)authDict
{
	return [self deleteKeychainPasswordForService:[MGSKeyChain sessionService:service] withDictionary:authDict];
}
/*
 
 delete the password for the authentication dictionary
 
 */
- (BOOL)deleteKeychainPasswordForService:(NSString *)service withDictionary:(NSDictionary *)authDict
{
	NSString *usernameBase64 = [authDict objectForKey:MGSAuthenticationKeyUsername];
	if (!usernameBase64) return NO;
	
	// decode username
	NSString *username = [[NSString alloc] initWithData:[usernameBase64 decodeBase64WithNewlines:NO] encoding:NSUTF8StringEncoding];
	
	// delete the password from the keychain
	return [MGSKeyChain deleteService:service withUsername:username];
}

/*
 
 create keychain session password for service
 
 */
- (BOOL)createKeychainSessionPasswordForService:(NSString *)service password:(NSString *)password username:(NSString *)username 
{
	// save session username and password to keychain
	return [self createKeychainPasswordForService:[MGSKeyChain sessionService:service] password:password username:username];
}
/*
 
 create keychain password for service
 
 */
- (BOOL)createKeychainPasswordForService:(NSString *)service password:(NSString *)password username:(NSString *)username 
{
	// save username and password to keychain
	return [MGSKeyChain addService:service withUsername:username password:password] == nil ? NO : YES;
}

/*
 
 create keychain default session password for service
 
 if the keychain contains a username and password for the service then generate the session
 keychain entry from it
 
 */
- (BOOL)createKeychainDefaultSessionPasswordForService:(NSString *)service username:(NSString *)username 
{
		
	NSString *password = nil;
	[self credentialsForService:service password:&password username:&username];
	
	// if user and password defined then create a session password for this service
	if (password && username) {
		return [[MGSAuthentication sharedController] createKeychainSessionPasswordForService:service password:password username:username];
	}
	
	return NO;
}

/*
 
 credentials for session service
 
 */
- (void)credentialsForSessionService:(NSString *)service password:(NSString **)outPassword username:(NSString **)inoutUsername
{
	[self credentialsForService:[MGSKeyChain sessionService:service] password:outPassword username:inoutUsername];
}

/*
 
 credentials for service
 
 */
- (void)credentialsForService:(NSString *)service password:(NSString **)outPassword username:(NSString **)inoutUsername
{
	// the username might be "" if the remote user is not advertising their host name.
	// in this case the keychain will not be able to retrieve the password even if the
	// keychain contains a record for the service.
	// so if username is nil then search for first matching service record and extract both
	// username and password from it
	NSString *password;
	NSString *username = *inoutUsername;
	
	if ([username length] == 0 || !username) {
		
		NSDictionary *dict = [MGSKeyChain passwordAndUsernameForService:service];
		password = [dict objectForKey:MGSKeyPassword];
		username = [dict objectForKey:MGSKeyUsername];
		
	} else {
		password = [MGSKeyChain passwordForService:service withUsername:username];
	}
	
	*outPassword = password;
	*inoutUsername = username;
}

@end

