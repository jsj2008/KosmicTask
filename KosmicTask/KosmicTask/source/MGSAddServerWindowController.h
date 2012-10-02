//
//  MGSAddServerWindowController.h
//  Mother
//
//  Created by Jonathan on 01/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetRequest.h"

#define MGSAddFavorite 0
#define MGSRemoveFavorite 1

@class MGSNetClient;

@protocol MGSAddServerDelegate
- (void)addStaticClient:(MGSNetClient *)netClient;
@end

@interface MGSAddServerWindowController : NSWindowController <MGSNetRequestOwner> {
	NSString *_address;			// machine address to connect to
	NSString *_displayName;		// display name to use in GUI
	BOOL _secureConnection;		// secure SSL connection
	BOOL _keepConnected;		// YES to keep connected between restarts 
	//BOOL _tableRowSelected;
	NSInteger _portNumber;		// port number
	id <MGSAddServerDelegate, NSObject> _delegate;
	MGSNetClient *_netClient;
	id _selectedObject;
    BOOL _connectionIsValid;
    
    NSMutableArray *_connections;
	IBOutlet NSObjectController *objectController;
	IBOutlet NSViewController *viewController;
	IBOutlet NSArrayController *arrayController;
	IBOutlet NSSegmentedControl *favoritesSegment;
	IBOutlet NSTextField *addressTextField;
	IBOutlet NSTextField *displayNameTextField;
	IBOutlet NSButton *reconnectCheckBox;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSBox *failedBox;
}

- (void)closeWindow;
- (IBAction)cancel:(id)sender;
- (IBAction)connect:(id)sender;
- (IBAction)clearSelection:(id)sender;
- (IBAction)processFavorite:(id)sender;


@property (copy) NSString *address;
@property (copy) NSString *displayName;
@property BOOL keepConnected;
@property BOOL secureConnection;
@property NSInteger portNumber;
@property id delegate;
@property BOOL connectionIsValid;

@end
