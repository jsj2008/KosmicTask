//
//  MGSServerNetRequest.m
//  KosmicTask
//
//  Created by Jonathan on 08/10/2012.
//
//
#import "MGSServerNetRequest.h"
#import "MGSNetRequest.h"
#import "MGSMother.h"
#import "MGSNetMessage.h"
#import "MGSNetHeader.h"
#import "MGSNetRequest.h"
#import "MGSNetClient.h"
#import "MGSAsyncSocket.h"
#import "MGSNetSocket.h"
#import "MGSError.h"
#import "MGSAuthentication.h"
#import "MGSRequestProgress.h"
#import "MGSPreferences.h"
#import "MGSScriptPlist.h"
#import "MGSNetNegotiator.h"
#import "MGSNetServerHandler.h"
#import "MGSNetwork.h"
#import "NSString_Mugginsoft.h"

// class extension
@interface MGSServerNetRequest()
- (BOOL)canAuthenticate;
@end

@implementation MGSServerNetRequest

/*
 
 request with connected socket
 
 */
+ (id) requestWithConnectedSocket:(MGSNetSocket *)netSocket
{
	return [[self alloc] initWithConnectedSocket:netSocket];
}


/*
 
 SERVER SIDE - init with connected socket
 this request will reside on the server
 
 */
-(MGSServerNetRequest *)initWithConnectedSocket:(MGSNetSocket *)netSocket
{
	if ((self = [super init])) {
		
		if (![netSocket isConnected]) {
			MLog(DEBUGLOG, @"socket not connected");
			[self setErrorCode:0 description:NSLocalizedString(@"socket not connected", @"error on socket")];
			_status = kMGSStatusNotConnected;
		} else {
			_status = kMGSStatusConnected;
		}
		
		_netSocket = netSocket;
	}
	return self;
}

#pragma mark -
#pragma mark Response

/*
 
 send response on socket
 
 */
- (void)sendResponseOnSocket
{
	NSAssert(_netSocket, @"socket is nil");
    
	// the client will need to be informed of how timeouts are to be handled.
	// so pass the request timeout info in the header
	_responseMessage.header.requestTimeout = self.readTimeout;
	_responseMessage.header.responseTimeout = self.writeTimeout;
    
    // identify the request that matches the response
    [_responseMessage setMessageObject:[_requestMessage messageUUID] forKey:MGSMessageKeyRequestUUID];
    
	// send response message - raises on error
	[_netSocket sendResponse];
}
/*
 
 send response chunk on socket
 
 */
- (void)sendResponseChunkOnSocket:(NSData *)data
{
    // send response message - raises on error
	[_netSocket sendResponseChunk:data];
}

#pragma mark -
#pragma mark Authentication

/*
 
 authenticate with auto response on failure
 
 */
- (BOOL)authenticateWithAutoResponseOnFailure:(BOOL)autoResponse
{
	NSString *error = nil;
	NSInteger errorCode = MGSErrorCodeSecureConnectionRequired;
	MGSError *mgsError = nil;
	
	/*
	 
	 negotiation is mandatory for authentication requests
	 
	 */
	MGSNetNegotiator *requestNegotiator = self.requestMessage.negotiator;
	if (requestNegotiator) {
		
		// Always secure authentication requests regardless of the
		// content of the negotiate dictionary
		MGSNetNegotiator *responseNegotiator = nil;
		
		// local host does not require security
		if ([_netSocket isConnectedToLocalHost] && ![requestNegotiator TLSSecurityRequested]) {
			responseNegotiator = [[MGSNetNegotiator alloc] init];
		} else {
			responseNegotiator = [MGSNetNegotiator negotiatorWithTLSSecurity];
		}
		[self.responseMessage applyNegotiator:responseNegotiator];
		
		if (autoResponse) {
			[_delegate sendResponseOnSocket:self wasValid:YES];
			return NO;
		}
		
	} else {
		
		// if the connection is not secure then we refuse
		// the authentication request unless it is from the localhost
		if (!self.secure && ![_netSocket isConnectedToLocalHost]) {
			error =  NSLocalizedString(@"Request denied. Authentication required.", @"Error returned by server");
			goto error_exit;
		}
	}
	
	// authenticate
	if ([self authenticate]) {
		return YES;
	}
	
	//========================================
	//
	// authentication has failed
	//
	// if auto response defined then send response
	//========================================
	if (autoResponse) {
		
		// choose authentication algorithm
		NSString *algorithm = (NSString *)MGSAuthenticationClearText;
		
		// form the authenticate challenge reply and add to dict.
		// if using cleartext there will be no challenge
		NSDictionary *challengeDict = [[MGSAuthentication sharedController] authenticationChallenge:algorithm];
		if (challengeDict) {
			[self.responseMessage setMessageObject:challengeDict forKey:MGSNetMessageKeyChallenge];
		}
		
		// add authentication error to reply
		mgsError = [MGSError serverCode:MGSErrorCodeAuthenticationFailure];
		[self.responseMessage setErrorDictionary:[mgsError dictionary] ];
		
		// tell delegate that authentication has failed.
		// the delegate can send the appropriate response to the client
		if (_delegate && [_delegate respondsToSelector:@selector(requestAuthenticationFailed:)]) {
			[_delegate requestAuthenticationFailed:self];
		}
	}
	
	return NO;
    
error_exit:
	
	if (autoResponse) {
		mgsError = [MGSError serverCode:errorCode reason:error];
		[self.responseMessage setErrorDictionary:[mgsError dictionary]];
		[_delegate sendResponseOnSocket:self wasValid:NO];
	}
	
	return NO;
}

//========================================
// returns YES if request authenticates
// against the host
//========================================
- (BOOL)authenticate
{
	BOOL success = NO;
	
    if (![self canAuthenticate]) {
        return NO;
    }
    
	// get the authentication dictionary
	NSDictionary *authDict = [_requestMessage authenticationDictionary];
	if ([authDict isKindOfClass:[NSDictionary class]]) {
		
		// authenticate localhost
		if ([_netSocket isConnectedToLocalHost]) {
			success = [[MGSAuthentication sharedController] authenticateLocalHostWithDictionary:authDict];
		} else {
			success = [[MGSAuthentication sharedController] authenticateWithDictionary:authDict];
		}
	}
    
	return success;
}

/*
 
 - canAuthenticate
 
 */
- (BOOL)canAuthenticate
{
    // what is the socket connected address
    NSString *requestIPAddress = [NSString mgs_StringWithSockAddrData:[self.netSocket.socket connectedAddress]];

    // check if remote network authentication is allowed
    BOOL allowRemoteAuthentication = [[MGSPreferences standardUserDefaults] boolForKey:MGSAllowRemoteUsersToAuthenticate];
    if (!allowRemoteAuthentication) {
        NSSet *allowedIPAddresses = [[MGSNetServerHandler sharedController] localNetworkIPAddresses];
        
        // we only allow local IP addresses to authenticate
        if (![allowedIPAddresses containsObject:requestIPAddress]) {
            
            MLogInfo(@"Authentication not allowed for remote network user on: %@", requestIPAddress);
            
            return NO;
        }
    }
    
    // check if local network authentication is allowed
    BOOL allowLocalAuthentication = [[MGSPreferences standardUserDefaults] boolForKey:MGSAllowLocalUsersToAuthenticate];
    if (!allowLocalAuthentication) {
        
        // we only allow local host to authenticate
        //if (![self.netSocket isConnectedToLocalHost]) {
        if (![[MGSNetwork localHostAddressesSet] containsObject:requestIPAddress]) {
            MLogInfo(@"Authentication not allowed for local network user on: %@", requestIPAddress);
            
            return NO;
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark Timeout handling
/*
 
 - setTimeout:
 
 */
- (void)setTimeout:(NSInteger)value
{
    [super setTimeout:value];
    
    // apply server timeout
    BOOL applyServerTimeout = [[MGSPreferences standardUserDefaults] boolForKey:MGSApplyTimeoutToMachineTasks];
    
    if (applyServerTimeout) {
        
        // get the server timeout
        NSInteger serverTimeout = [[MGSPreferences standardUserDefaults] integerForKey:MGSMachineTaskTimeout];
        
        if (serverTimeout > 0) {
            mgsTimeoutUnits timeoutUnits = [[MGSPreferences standardUserDefaults] integerForKey:MGSMachineTaskTimeoutUnits];
            NSInteger mul = 0;
            
            switch (timeoutUnits) {
                case kMGSTimeoutMinutes:
                    mul = 60;
                break;

                case kMGSTimeoutHours:
                    mul = 60 * 60;
                break;

                default:
                    mul = 1;
                break;
            }
            serverTimeout *= mul;
            [super setTimeout:serverTimeout];
        }
    }
}

#pragma mark -
#pragma mark Socket handling

/*
 
 - netServerSocket
 
 */
- (MGSNetServerSocket *)netServerSocket
{
    return (MGSNetServerSocket *)_netSocket;
}
@end
