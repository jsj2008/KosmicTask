//
//  MGSConfigurationAccessWindowController.m
//  Mother
//
//  Created by Jonathan on 24/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
/*
 
 This class displays a modal sheet indicating that the client is being contacted.
 
 Attempts to authenticate against the client.
 
 If authentication details are available and the authentication request suceeds then
 MGSNoteAuthenticateAccessSucceeded is posted.
 
 Otherwise the class calls upon the singleton MGSAuthenticateWindowController to 
 get user input and attempt authentication.
 
 If the authentication request suceeds then MGSNoteAuthenticateAccessSucceeded is posted. 
 If not MGSNoteAuthenticateAccessFailed is posted.
 
 */
#import "MGSMother.h"
#import "MGSConfigurationAccessWindowController.h"
#import "MGSClientRequestManager.h"
#import "MGSNetClient.h"
#import "MGSScriptPlist.h"
#import "MGSNetRequestPayload.h"
#import "MGSMotherModes.h"
#import "MGSNotifications.h"
#import "MGSError.h"
#import "MGSNetMessage.h"
#import "MGSKeyChain.h"
#import "MGSAuthentication.h"

#define ACCESS_DISPLAY_TIMEOUT 1.0
#define CANCEL_DISPLAY_TIMEOUT 3.0

// class extension
@interface MGSConfigurationAccessWindowController()
- (void)authDialogDisplay:(NSNotification *)notification;
- (void)displayTimerFired:(NSTimer *)theTimer;
- (void)cancelTimerFired:(NSTimer *)theTimer;
@end

@implementation MGSConfigurationAccessWindowController

@synthesize modalForWindow = _modalForWindow;

/*
 
 - init
 
 */
- (id)init
{
	if ((self = [super initWithWindowNibName:@"ConfigurationAccessWindow"])) {
	
	}
	
	return self;
}

#pragma mark -
#pragma mark Window handling
/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	//[[self window] setDelegate:self];
	[[self window] setExcludedFromWindowsMenu:YES];	// don't want this in the menu
	
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
 
 close window
 
 */
- (void)closeWindow
{	
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	if (_cancelTimer) {
		[_cancelTimer invalidate];
		_cancelTimer = nil;
	}
    
	if (_displayTimer) {
		[_displayTimer invalidate];
		_displayTimer = nil;
	}
	
	[progressIndicator stopAnimation:self];
    
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:1];
	
	if (_authenticationComplete) {
		
		NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_accessType], MGSNoteModeKey , nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAuthenticateAccessSucceeded object:nil userInfo:infoDict];
	}
    
    _netClient = nil;
    _modalForWindow = nil;
}


#pragma mark -
#pragma mark Authentication control
/*
 
 authenticate client
 
 */
- (void)authenticateNetClient:(MGSNetClient *)netClient forAccess:(NSUInteger)accessType
{
    [progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];
	_cancelTimer = nil;
	_displayTimer = nil;
	_authenticationComplete = NO;
	_netClient = netClient;
	_authenticationCancelled = NO;
	_accessType = accessType;
	
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authDialogDisplay:) name:MGSNoteAuthenticationDialogWillDisplay object:nil];

	NSAssert(netClient, @"net client is nil");
	NSString *message;
	
	switch (_accessType) { 
		case kMGSMotherRunModeConfigure:
			message = NSLocalizedString(@"Accessing KosmicTask configuration on %@.", @"Configuration access sheet text format");
			break;
			
		case kMGSMotherRunModeAuthenticatedUser:
		default:
			message = NSLocalizedString(@"Logging in to KosmicTask on %@.", @"Login access sheet text format");
			break;
	}

	// create keychain default session password for this client
	[[MGSAuthentication sharedController] createKeychainDefaultSessionPasswordForService:netClient.serviceName username:netClient.hostUserName];
	
	message = [NSString stringWithFormat:message, [_netClient serviceShortName]];
	
	[mainLabel setStringValue:message];
	[cancelButton setEnabled:NO];
	
	// show the configuration access sheet
	[NSApp beginSheet:[self window] modalForWindow:_modalForWindow 
		modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
	
	// authenticate the client.
	// if this authentication request fails then the MGSAuthenticateWindowController singleton instance
	// will be called upon to prompt the user for authentication details.
	// this operation is transparent to this request.
	// as owner of the original authentication request we will simply be informed of the success or failure of the
	// request regardless of the intervening process.
	[[MGSClientRequestManager sharedController] requestAuthenticationForNetClient:_netClient withOwner:self];
	
	// setup display timer to show window for minimum period of time
	_displayTimer = [NSTimer scheduledTimerWithTimeInterval:ACCESS_DISPLAY_TIMEOUT
							target:self 
							selector:@selector(displayTimerFired:) 
							userInfo:nil
							repeats:NO];
	
	// setup cancel timer
	_cancelTimer = [NSTimer scheduledTimerWithTimeInterval:CANCEL_DISPLAY_TIMEOUT
													 target:self 
												   selector:@selector(cancelTimerFired:) 
												   userInfo:nil
													repeats:NO];
}


/*
 
 cancel the authentication
 
 */
-(void)cancelAuthentication:(id)sender
{
#pragma unused(sender)
	
    if (!_authenticationCancelled) {
        _authenticationCancelled = YES;
    
        [self closeWindow];
    }
}

/*
 
 authentication dialog display notification
 this notification is sent before the authentication dialog appears
 
 */
- (void)authDialogDisplay:(NSNotification *)notification
{
#pragma unused(notification)
	
	[self closeWindow];
}

#pragma mark -
#pragma mark MGSNetRequestOwner protocol

/*
 
 request authentication reply
 
 */
-(void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
#pragma unused(netRequest)
	
	// if have cancelled out of this sheet then ignore reply
    // if authentication complete then ignore reply.
	if (_authenticationCancelled || _authenticationComplete) {
		return;
	}
	
    if (netRequest.owner == self) {
        netRequest.owner = nil;
    }
    
    // get request error
    NSDictionary *errorDict = netRequest.error.dictionary;
    
    // get payload error
    //
	// if error in reply then authentication was cancelled by user
	// within the object which sent this message
	if (!errorDict){
        errorDict = [payload.dictionary objectForKey:MGSNetMessageKeyError];
    }
    
	if (errorDict) {
		
        BOOL cancel = NO;
		MGSError *error = [MGSError errorWithDictionary:errorDict];
        NSString *errorString = @"Error";
        
        switch ([error code]) {
                
            case MGSErrorCodeAuthenticationFailure:
                cancel = YES;
                break;

            case MGSErrorCodeServerAccessDenied:
                errorString = error.localizedDescription;
                break;

            default:
                errorString = error.localizedDescription;
                break;
		}

        if (cancel) {
            [self cancelAuthentication:self];
        } else {
            label.stringValue = errorString;
            [cancelButton setEnabled:YES];
            [cancelButton setTitle:NSLocalizedString(@"Close", @"Button text")];
            [progressIndicator stopAnimation:self];
            [progressIndicator setHidden:YES];
        }
		return;
	}
	
	_authenticationComplete = YES;
	
	// close window if display timer already expired
	if (!_displayTimer) {
		[self closeWindow];
	}
}

#pragma mark -
#pragma mark Timer callbacks

/*
 
 display timer fired
 
 */
- (void)displayTimerFired:(NSTimer *)theTimer
{
	#pragma unused(theTimer)
	
    // invalidate the display timer
	[_displayTimer invalidate];
	_displayTimer = nil;
	
    // if authentication complete then close the window
	if (_authenticationComplete) {
		[self closeWindow];
	}
}

/*
 
 cancel timer fired
 
 */
- (void)cancelTimerFired:(NSTimer *)theTimer
{
	#pragma unused(theTimer)
	
    // invalidate the cancel timer
	[_cancelTimer invalidate];
	_cancelTimer = nil;
	
    // enable cancel button
	[cancelButton setEnabled:YES];
}



@end
