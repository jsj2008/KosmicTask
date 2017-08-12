//
//  MGSAuthenticateWindowController.h
//  Mother
//
//  Created by Jonathan on 23/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSNetClient;
@class MGSClientNetRequest;

@interface MGSAuthenticateWindowController : NSWindowController <NSWindowDelegate> {
	
	//MGSNetClient *_netClient;
	MGSClientNetRequest *__weak _netRequest;
	id _requestOwner;
	
	IBOutlet NSTextField *usernameTextField;
	IBOutlet NSSecureTextField *passwordTextField;
	IBOutlet NSObjectController *objectController;
	IBOutlet NSBox *authenticationFailedBox;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSTextField *errorTextField;
    IBOutlet NSProgressIndicator *progressIndicator;
    
	NSString *_username;
	NSString *_password;
	BOOL _savePasswordToKeychain;
	NSString *_windowText;
    NSString *_hostname;
	NSDictionary *_challenge;
	BOOL _sheetIsVisible;
	BOOL _keychainSearchedForCredentials;
	//BOOL _authenticationCancelled;
	//BOOL _awaitingAuthenticationResponse;
	NSModalSession _modalSession;
	NSWindow *__weak _modalForWindow;
    BOOL _canConnect;
    BOOL _authenticationInProgress;
}

@property (copy) NSString *username;
@property (copy) NSString *password;
@property BOOL savePasswordToKeychain;
@property (copy) NSString *windowText;
@property (copy) NSString *hostName;
@property (readonly) NSDictionary *challenge;
@property (weak) NSWindow *modalForWindow;
@property (weak, readonly) MGSClientNetRequest *netRequest;
@property BOOL canConnect;
@property BOOL authenticationInProgress;


+ (id)sharedController;
- (IBAction)cancel:(id)sender;
- (IBAction)connect:(id)sender;
//- (id)initWithNetClient:(MGSNetClient *)netClient;
//- (id)initWithNetRequest:(MGSNetRequest *)netRequest;
- (BOOL)authenticateRequest:(MGSClientNetRequest *)netRequest challenge:(NSDictionary *)challengeDict;
- (IBAction)closeWindow;
@end
