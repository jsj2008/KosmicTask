//
//  ConfigWindowController.m
//  mother
//
//  Created by Jonathan Mitchell on 20/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSConfigWindowController.h"
#import "MGSMotherServerController.h"
#import "MGSNetController.h"

static NSString *MGSStatusWaiting = @"waiting...";
static NSString *MGSStatusNoAddress = @"no address";
static NSString *MGSStatusConnecting = @"connecting...";
//static NSString *MGSStatusConnected = @"connected";
//static NSString *MGSStatusDisconnected = @"no connection";
static NSString *MGSStatusConnectTestOK = @"connection test OK";
static NSString *MGSStatusConnectTestFAIL = @"connection test FAILED";

@interface MGSConfigWindowController (Private)
- (void)testConnectToAddress:(NSData *)addressData;
@end

@implementation MGSConfigWindowController

@synthesize hostName = _hostName;
@synthesize serverConnected = _serverConnected;

- (void)setupToolbar
{
	[self addView:modeView label:@"Mode"];
	[self addView:sendView label:@"Send"];
	[self addView:receiveView label:@"Receive"];
	[self addView:configView label:@"Config"];
}

+ (NSString *)nibName
	// Subclasses can override this to use a nib with a different name.
{
	return @"Configuration";
}

- (MGSConfigWindowController *) initWithServerController: (MGSMotherServerController *)server
{
	// call the window controller designated initialiser
	self = [self initWithWindowNibName:[MGSConfigWindowController nibName]];
	
	//_server = server;

	
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	[self reset];
}
- (void)reset
{
	if (_server) {
		//[_server stop];
		_server = nil;
	}
	
	// set connection status
	_server = [[MGSMotherServerController alloc] init];
	//MGSMotherServerConnectionController *connection = [_server connection];
	
	//self.serverConnected = [connection connected];
	//self.hostName = [connection hostName];
	
	// start searching for services
	[_server searchForServices];
	
	// tell bonjour controller where to output services search results
	// the bonjour controller will initiate its own services search
	[[_server bonjour] setServicesControl:searchResults];
}

// display server connection status
/*- (void)setServerConnected:(BOOL)value
{
	_serverConnected = value;
	NSString *status;
	if (value) {
		status = MGSStatusConnected;
	} else {
		status = MGSStatusDisconnected;
	}
	[serverConnectedText setStringValue:status];
}
*/
/*
- (MGSConfigWindowController *) initWithNibName
{
	[self initWithWindowNibName:[MGSConfigWindowController nibName]];
	return self;
}
*/

- (IBAction)nextView:(id)sender
{
	[self displayNextView:true];
}

- (IBAction)prevView:(id)sender
{
	[self displayNextView:false];
}

// try and connect to the server
- (IBAction)connectToServer:(id)sender
{
	[serverConnectedText setStringValue:MGSStatusWaiting];

	// resolve address of selected server
	[[_server bonjour] setDelegate:self];
	[[_server bonjour] resolveServicesControlAddress:30.0];
}

@end

@implementation MGSConfigWindowController (MGSNetControllerDelegate)

// bonjour service address found
-(void)netControllerDidResolve:(MGSNetController *)sender address:(NSData *)address
{
	[sender setDelegate:nil];
	
	// validate the socket address
	if (!address) {
		MLog(DEBUGLOG, @"resolved service data is nil");
		[serverConnectedText setStringValue:MGSStatusNoAddress];
		return;
	}
	MLog(DEBUGLOG, @"bonjour service address resolved");
	
	// test connection
	[self testConnectToAddress: address];
}

//  bonjour service address not found
-(void)netControllerDidNotResolve:(MGSNetController *)sender
{
	[sender setDelegate:nil];
	MLog(DEBUGLOG, @"bonjour service address not resolved");
	[serverConnectedText setStringValue:MGSStatusNoAddress];
}

@end

@implementation MGSConfigWindowController (Private)

// test connection to address
- (void)testConnectToAddress:(NSData *)addressData
{
	// try and establish server connection using resolved address
	[serverConnectedText setStringValue:MGSStatusConnecting];
	MGSMotherServerConnectionController *connection = [_server connection];
	if([connection connectToAddress:addressData]) {
		[connection disconnect];
		[serverConnectedText setStringValue:MGSStatusConnectTestOK];
	} else {
		[serverConnectedText setStringValue:MGSStatusConnectTestFAIL];
	}
	[self reset];
}

@end

@implementation DBPrefsWindowController (Configuration)

- (void)displayNextView:(BOOL)displayNext
{
	NSToolbar *toolbar = [[self window] toolbar];
	NSString *currentIdentifier = [toolbar selectedItemIdentifier];
	int nItems = [toolbarIdentifiers count];
	int i, start, limit, offset;
	
	if (nItems < 2) {
		return;
	}
	
	// display next or previous view
	if (displayNext) {
		start = 0;
		limit = nItems-1;
		offset = 1;
	} else {
		start = 1;
		limit = nItems;
		offset = -1;
	}
	
	// display the reqd view
	for (i = start; i < limit; i++) {
		NSString *identifier = (NSString *)[toolbarIdentifiers objectAtIndex:i];
		if ([identifier isEqualToString:currentIdentifier]) {
			NSString *newIdentifier = (NSString *)[toolbarIdentifiers objectAtIndex:i+offset];
			[toolbar setSelectedItemIdentifier:newIdentifier];
			[self displayViewForIdentifier:newIdentifier animate:YES];
			return;
		}
	}
}

@end
