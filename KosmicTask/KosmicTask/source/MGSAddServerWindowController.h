//
//  MGSAddServerWindowController.h
//  Mother
//
//  Created by Jonathan on 01/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSClientNetRequest.h"

#define MGSAddFavorite 0
#define MGSRemoveFavorite 1

enum _MGSAddServerStatusID {
    kMGSAddServerNotConnected = 0,
    kMGSAddServerConnecting = 1,
    kMGSAddServerConnected = 2,
    
};
typedef NSInteger MGSAddServerStatusID;

@interface MGSAddServerArrayController : NSArrayController {
    
}
@end

@class MGSNetClient;

@protocol MGSAddServerDelegate
- (void)addStaticClient:(MGSNetClient *)netClient;
@end

@interface MGSAddServerWindowController : NSWindowController <MGSNetRequestOwner> {
	NSString *_address;			// machine address to connect to
	NSString *_displayName;		// display name to use in GUI
    NSString *_note;
	BOOL _secureConnection;		// secure SSL connection
	BOOL _keepConnected;		// YES to keep connected between restarts 
	//BOOL _tableRowSelected;
	NSInteger _portNumber;		// port number
	id <MGSAddServerDelegate, NSObject> _delegate;
	id _selectedObject;
    BOOL _selectedConnectionIsValid;
    NSResponder *_responder;
    NSInteger _outstandingRequestCount;
    BOOL _canConnect;
    
    NSMutableArray *_connections;
    IBOutlet NSTableView *tableView;
	IBOutlet NSObjectController *objectController;
	IBOutlet NSViewController *viewController;
	IBOutlet NSArrayController *arrayController;
	IBOutlet NSSegmentedControl *favoritesSegment;
	IBOutlet NSTextField *addressTextField;
	IBOutlet NSTextField *displayNameTextField;
	IBOutlet NSButton *reconnectCheckBox;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSBox *failedBox;
    IBOutlet NSTextField *failedLabel;
    IBOutlet NSTextField *noteTextField;
}

- (void)closeWindow;
- (IBAction)cancel:(id)sender;
- (IBAction)connect:(id)sender;
- (IBAction)clearSelection:(id)sender;
- (IBAction)processFavorite:(id)sender;
- (IBAction)checkboxClickAction:(id)sender;

@property (copy) NSString *note;
@property (copy) NSString *address;
@property (copy) NSString *displayName;
@property BOOL keepConnected;
@property BOOL secureConnection;
@property NSInteger portNumber;
@property id delegate;
@property BOOL selectedConnectionIsValid;
@property BOOL canConnect;
@end
