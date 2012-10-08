//
//  ConfigurationAccessWindowController.h
//  Mother
//
//  Created by Jonathan on 24/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSClientNetRequest.h"

//#define MGSAccessTypeLogin  0
//#define MGSAccessTypeConfiguration 1

@class MGSNetClient;

@interface MGSConfigurationAccessWindowController : NSWindowController <MGSNetRequestOwner> {
	IBOutlet NSTextField *mainLabel;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSProgressIndicator *progressIndicator;
	NSWindow *_modalForWindow;
	MGSNetClient *_netClient;
	
	NSTimer *_displayTimer;
	NSTimer *_cancelTimer;
	BOOL _authenticationComplete;
	BOOL _authenticationCancelled;
	NSUInteger _accessType;
}

@property NSWindow *modalForWindow;

- (void)authenticateNetClient:(MGSNetClient *)netClient forAccess:(NSUInteger)access;
- (void)closeWindow;

-(IBAction)cancelAuthentication:(id)sender;
@end
