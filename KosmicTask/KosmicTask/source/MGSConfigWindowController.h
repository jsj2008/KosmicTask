//
//  ConfigWindowController.h
//  mother
//
//  Created by Jonathan Mitchell on 20/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"

@class MGSMotherServerController;
@class MGSNetServerHandler;

@interface MGSConfigWindowController : DBPrefsWindowController {
	IBOutlet NSView *modeView;
	IBOutlet NSView *sendView;
	IBOutlet NSView *receiveView;
	IBOutlet NSView *configView; 
	IBOutlet NSTextField *serverConnectedText; 
	IBOutlet MGSNetServerHandler *netController; 
	IBOutlet NSComboBox *searchResults;
	
	MGSMotherServerController *_server;
	NSString *_hostName;
	BOOL _serverConnected;
}

@property (copy) NSString *hostName;
@property BOOL serverConnected;

- (MGSConfigWindowController *) initWithServerController:(MGSMotherServerController *)server;
//- (MGSConfigWindowController *) initWithNibName;
- (IBAction)nextView:(id)sender;
- (IBAction)prevView:(id)sender;

- (IBAction)connectToServer:(id)sender;

- (void)reset;

@end

@interface DBPrefsWindowController (Configuration) 

- (void)displayNextView:(BOOL)displayNext;

@end

// informal MGSNetController protocol
@interface MGSConfigWindowController (MGSNetControllerDelegate)

// bonjour service address found
-(void)netControllerDidResolve:(MGSNetServerHandler *)sender address:(NSData *)address;
-(void)netControllerDidNotResolve:(MGSNetServerHandler *)sender;

@end
