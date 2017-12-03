//
//  MGSAuthenticateWindowController.m
//  Mother
//
//  Created by Jonathan on 23/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
/*
 
 In this class the _requestOwner is the owner of the request that generated the
 authentication requirement (generally the original request will have failed to authenticate).
 
 _requestOwner is effectively the class delegate.
 
 This class does not issue notifications of success or failure but returns the result
 of the authentication request to _requestOwner.
 
 */
#import "MGSMother.h"
#import "MGSAuthenticateWindowController.h"
#import "MGSNetClient.h"
#import "NSView_Mugginsoft.h"
#import "MGSAuthentication.h"
#import "NSWindowController_Mugginsoft.h"
#import "MGSClientNetRequest.h"
#import "MGSNetMessage.h"
#import "MGSNotifications.h"
#import "MGSError.h"
#import "MGSNetRequestPayload.h"
#import "MGSNotifications.h"
#import "MGSKeyChain.h"
#import <QuartzCore/CoreAnimation.h>
#import "MGSClientRequestManager.h"

static int numberOfShakes = 4;
static float durationOfShake = 0.5f;
static float vigourOfShake = 0.03f;

//static int numberOfShakes = 4;
//static float durationOfShake = 0.5f;
//static float vigourOfShake = 0.05f;

static MGSAuthenticateWindowController *_sharedController = nil;

// class extension
@interface MGSAuthenticateWindowController ()
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@interface MGSAuthenticateWindowController (Private)
- (void)sendAuthenticatedRequest;
- (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame;
@end


@implementation MGSAuthenticateWindowController

@synthesize username = _username;
@synthesize password = _password;
@synthesize savePasswordToKeychain = _savePasswordToKeychain;
@synthesize windowText = _windowText;
@synthesize challenge = _challenge;
@synthesize modalForWindow = _modalForWindow;
@synthesize netRequest = _netRequest;
@synthesize canConnect = _canConnect;
@synthesize hostName = _hostname;
@synthesize authenticationInProgress = _authenticationInProgress;

#pragma mark class methods

/*
 
 shared controller singleton
 
 */
+ (id)sharedController 
{
	@synchronized(self) {
		if (nil == _sharedController) {
			(void)[[self alloc] init];  // assignment occurs below
		}
	}
	return _sharedController;
}

/*
 
 alloc with zone for singleton
 
 */
+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (_sharedController == nil) {
            _sharedController = [super allocWithZone:zone];
            return _sharedController;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
} 

#pragma mark instance methods

/*
 
 copy with zone for singleton
 
 */
- (id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
    return self;
}

/*
 
 init
 
 */
- (id)init
{
	// this will search in file's owner class bundle and in main app bundle.
	// so should locate the nib within the framework bundle okay.
	// note that this differs from NSViewController behaviour
	if (!(self = [super initWithWindowNibName:@"AuthenticateWindow"])) return nil;

    _canConnect = NO;
	_modalSession = nil;
	_modalForWindow = nil;
	_sheetIsVisible = NO;
	_keychainSearchedForCredentials = NO;
	//_awaitingAuthenticationResponse = NO;
	//_authenticationCancelled = NO;
	
	return self;
}

/*
 
 show window
 
 */
/*
- (void)showWindow:(id)sender
{
	[self window];	// force nib load
	[authenticationFailedBox setHidden:YES];
	_authenticationCancelled = NO;
	[super showWindow:self];
}
*/

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	[[self window] setDelegate:self];
	[[self window] setExcludedFromWindowsMenu:YES];	// don't want this in the menu
	self.username = @"";
	self.password = @"";
	self.savePasswordToKeychain = NO;
	[authenticationFailedBox setHidden:YES];
	
	// must authenticate as host user
	[[self window] makeFirstResponder:passwordTextField];	// if control is first responder then cannot change editable status
}

#pragma mark -
#pragma mark Accessors

/*
 
 - username
 
 */
- (void)setUsername:(NSString *)aString
{
    _username = aString;
    self.canConnect = ([_username length] > 0 ? YES : NO);
}

#pragma mark -
#pragma mark Actions
/*
 
 cancel the authentication attempt
 
 */
- (IBAction)cancel:(id)sender
{
	#pragma unused(sender)
	
	// authentication has been cancelled so don't allow another
	// authentication request to be accepted
	self.netRequest.allowUserToAuthenticate = NO;
	
	[objectController commitEditing];	// otherwise old passwords can remain
	
	// message request original owner
	if (_requestOwner && [_requestOwner respondsToSelector:@selector(netRequestResponse:payload:)]) {
		
		// create authenticate error payload
		MGSError *error = [MGSError clientCode:MGSErrorCodeAuthenticationFailure reason:nil log:NO];
		MGSNetRequestPayload *payload = [MGSNetRequestPayload payloadForRequest:_netRequest];
		payload.dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							  [error dictionary], MGSNetMessageKeyError, nil];
		
		[_requestOwner netRequestResponse:_netRequest payload:payload];
	}
	
	[self closeWindow];
	
}

/*
 
 close window
 
 */
- (IBAction)closeWindow
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:1];
	
	_sheetIsVisible = NO;	// may have failed but complete none the less
	_keychainSearchedForCredentials = NO;	// reset
	self.savePasswordToKeychain = NO;
	_challenge = nil;
	
	// clear sensitive data
	self.username = nil;
	self.password = nil;
	
	// reset request ownership
	if (_requestOwner) {
		self.netRequest.owner = _requestOwner;
	}
	_netRequest = nil;
	_requestOwner = nil;
	
	// clean up for next call
	[authenticationFailedBox setHidden:YES];
	[self setControlsEnabled:YES];
}

/*
 
 try to connect using current credentials
 
 */
- (IBAction)connect:(id)sender
{
	#pragma unused(sender)
	
	[objectController commitEditing];
	
    if ([self canConnect]) {
        [self sendAuthenticatedRequest];
    }
}

/*
 
 authenticate the user

 1. try and retrieve service item from the key chain and authenticate
 2. if no service item found or authentication fails show window
 
 The message returns NO if the request cannot be accepted for authentication.
 
 */
-(BOOL)authenticateRequest:(MGSClientNetRequest *)netRequest challenge:(NSDictionary *)challengeDict
{
    
    self.authenticationInProgress = NO;
    
	// if we are currently handling another request authorisation then we cannot accept this request.
	// we can accept another authentication request from the current request.
	if (_netRequest != nil && _netRequest != netRequest) {
		return NO;
	}
	
	//
	if (!netRequest.allowUserToAuthenticate) {
		return NO;
	}
	
	_netRequest = netRequest;
	_challenge = [challengeDict copy];
	
	// this method is called repeatedly by the net request processing machinery until
	// a sucessful authentication occurs or the window is cancelled by the user.
	// if the user has already cancelled when we receive this message then it can be ignored.
	
	[self window];	// load the nib
	
	//[usernameTextField setEditable:NO];		// still no effect - set in IB
	//[usernameTextField setSelectable:NO]; 
	
	self.password = @"";	// ensure any previous password is cleared
	[self setControlsEnabled:YES];	// controls will be needed if sheet to be shown or already visible
	    
    MGSError *responseError = netRequest.responseMessage.error;

	// check for failed authentication
	//
	// if the sheet is already visible then a previous authentication has failed.
	//
	if (_sheetIsVisible == YES) {

        NSString *errorMesg = nil;
        switch (responseError.code) {
            case MGSErrorCodeServerAccessDenied:
                errorMesg = NSLocalizedString(@"Access denied", @"Access to server denied");
                break;
                
            case MGSErrorCodeAuthenticationFailure:
                errorMesg = NSLocalizedString(@"Authentication failed", @"Server authentication failed");
                break;
                
            default:
                errorMesg = NSLocalizedString(@"Bad authentication", @"Server authentication failed with unknown error");
                break;
        }
        
        [errorTextField setStringValue:errorMesg];
		[authenticationFailedBox setHidden:NO];
		[[self window] makeFirstResponder: passwordTextField]; // need to set after controls enabled
		
		// shake it
		[[self window] setAnimations:[NSDictionary dictionaryWithObject:[self shakeAnimation:[[self window] frame]] forKey:@"frameOrigin"]];
		[[[self window] animator] setFrameOrigin:[[self window] frame].origin];
		
		// we exit here, leaving the user to re-enter then auth details
		return YES;
	} else {
        
        switch (responseError.code) {
             case MGSErrorCodeAuthenticationFailure:
                break;
                
            case MGSErrorCodeServerAccessDenied:
            default:
                return NO;
        }

    }
	
	// validate the challenge if supplied
	if (_challenge) {
		
		NSString *algorithm = [_challenge objectForKey:MGSAuthenticationKeyAlgorithm];
		NSString *challenge = [_challenge objectForKey:MGSAuthenticationKeyChallenge];
		
		// validate
		if (!algorithm || !challenge) { 
			MLog(DEBUGLOG, @"invalid challenge dictionary");
			return NO;
		}
	}

	// try and authenticate using user credentials from keychain for this service.
	// if no credentials found then show sheet
	if (_keychainSearchedForCredentials == NO) {

		// this object will act as a proxy for the request owner.
		// we need to retain the original owner so that the final result of authentication attempts
		// can be communicated back to them.
		_requestOwner = _netRequest.owner;
		_netRequest.owner = self;
				
		_keychainSearchedForCredentials = YES;
		
        
		// get the username and password for this session
		NSString *password = nil;
		NSString *username = [[_netRequest netClient] hostUserName];
		[[MGSAuthentication sharedController] credentialsForSessionService:_netRequest.netClient.serviceName password:&password username:&username];
		
		if (password && username) {
			
			// try and authenticate with these credentials
			
			/*
			// crypt the password
			char salt[10] = { '_', '0','5','5', '5', 'A', 'B', 'Z', 'Z', 0 };
			char buffer[1024];
			if (![password getCString:buffer maxLength:sizeof(buffer) encoding:NSUTF8StringEncoding]) {
				MLog(RELEASELOG, @"could not get password c string");
				buffer[0] = 0;
			}
			
			char *cryptPassword = crypt(buffer, salt);
			NSString *cryptPasswordString = [NSString stringWithCString:cryptPassword encoding:NSUTF8StringEncoding];
			*/
			
			self.password = password;
			self.username = username;
			
			[self sendAuthenticatedRequest];
			return YES;
		}
	}
	

	// get host and user names from net client
	NSAssert(_netRequest, @"net request is nil");
	
	// if not disclosing username to any client then
	// username will be @"".
	// if we are authenticating against the local host then it will be
	// okay in this case to show the username.
	self.username = [[_netRequest netClient] hostUserName];
	if ([self.username isEqualToString: @""] && YES == [[_netRequest netClient] isLocalHost]) {
		self.username = NSUserName();
	}
	
	self.hostName = [[_netRequest netClient] serviceShortName];
	NSString *format = NSLocalizedString(@"Enter a valid OS X user name and password to gain secure access to KosmicTask on \"%@\".", @"Authentication window text");
	self.windowText = [NSString stringWithFormat:format, self.hostName];
    
	// if no username supplied then make it first responder
	if ([self.username isEqualToString:@""]) {
		[[self window] makeFirstResponder: usernameTextField];
	} else {
		[[self window] makeFirstResponder: passwordTextField];
	}
	
	if (nil == _modalForWindow) {
		_modalForWindow = [NSApp mainWindow]; 
	}
	
	_sheetIsVisible = YES;

	// notify that the authentication dialog will appear.
	// (this will allow the clearing of the authenticating sheet displayed when switching modes)
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAuthenticationDialogWillDisplay object:self userInfo:nil];
	
	// show the sheet
	[NSApp beginSheet:[self window] modalForWindow:_modalForWindow 
		modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
	
	return YES;
}

/*
 
 modal sheet did end
 
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	#pragma unused(sheet)
	#pragma unused(returnCode)
	#pragma unused(contextInfo)
}

/*
 
 sucessful authentication reply
 
 this message is only sent if the authentication request succeeds.
 if the request fails then this object will receive an authenticate messaage.
 
 */
-(void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{

    self.authenticationInProgress = NO;
    
	// we are only interested in responses that correspond to the current request
	if (netRequest != self.netRequest) {
		return;
	}
	
	// reset original owner
	netRequest.owner = _requestOwner;
	
	// authentication complete
	_sheetIsVisible = NO;
	
	MGSNetClient *netClient = netRequest.netClient;
	
	// save to keychain if required
	if (_savePasswordToKeychain) {
		[[MGSAuthentication sharedController] createKeychainPasswordForService:netClient.serviceName password:_password username:_username];
	} 
	
	// message request original owner
	if (_requestOwner && [_requestOwner respondsToSelector:@selector(netRequestResponse:payload:)]) {
		[_requestOwner netRequestResponse:netRequest payload:payload];
	}
	
	// close it down
	[self closeWindow];
}
@end

@implementation MGSAuthenticateWindowController (Private)

/*
 
 shake animation
 http://www.cimgf.com/2008/02/27/core-animation-tutorial-window-shake-effect/
 
 */
- (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame
{
	CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
	
	CGMutablePathRef shakePath = CGPathCreateMutable();
	CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
	int idx;
	for (idx = 0; idx < numberOfShakes; ++idx)
	{
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
	}
	CGPathCloseSubpath(shakePath);
	shakeAnimation.path = shakePath;
	shakeAnimation.duration = durationOfShake;
	return shakeAnimation;
}


/*
 
 add authentication credentials to request and send
 
 */
- (void)sendAuthenticatedRequest
{
    NSAssert(self.username, @"username is nil");
    NSAssert(self.password, @"password is nil");
    
	// disable all the window controls
	[self setControlsEnabled:NO];
	[cancelButton setEnabled:YES];
	[authenticationFailedBox setHidden:YES];
	
	NSDictionary *responseDict;
	
	//======================================================
	// Generate authentication dictionary.
	// If challenge supplied generate response to challenge.
	// Otherwise send in cleartext.
	//======================================================
	if (_challenge) {
		responseDict = [[MGSAuthentication sharedController] responseToChallenge:_challenge password:_password username:_username];
	} else {
		responseDict = [[MGSAuthentication sharedController] responseDictionaryforSessionService:_netRequest.netClient.serviceName password:_password username:_username ];
	}
	if (!responseDict) {
		goto errorExit;
	}

    // we want to resend the netrequest
	[_netRequest prepareToResend];
    
    // send a copy of the request
    _netRequest = [_netRequest copy];
	
	// add the response dict to the request
	[[_netRequest requestMessage] setAuthenticationDictionary:responseDict];
	
	// resend the request with self as owner
	[[MGSClientRequestManager sharedController] sendRequestOnClient:_netRequest];
	
    self.authenticationInProgress = YES;
    
	return;
	
errorExit:;
	[self setControlsEnabled:YES];
	return;	
}

@end
