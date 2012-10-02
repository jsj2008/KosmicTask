//
//  MGSAddServerWindowController.m
//  Mother
//
//  Created by Jonathan on 01/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSMotherServer.h"
#import "MGSAddServerWindowController.h"
#import "MGSNetClient.h"
#import "MGSNetClientManager.h"
#import "MGSClientRequestManager.h"
#import "NSWindowController_Mugginsoft.h"
#import "MGSNetRequestPayload.h"
#import "NSString_Mugginsoft.h"

NSString *MGSDefaultFavoriteConnections = @"MGSFavoriteConnections";

const char MGSContextFavoritesSelectedObjects;
const char MGSContextFavoritesSelectionIndex;

// class interface extension
@interface MGSAddServerWindowController()
- (NSMutableDictionary *)connection;
- (void) validateConnectionValues;
@end

@implementation MGSAddServerWindowController

@synthesize address = _address;
@synthesize displayName = _displayName;
@synthesize keepConnected = _keepConnected;
@synthesize portNumber = _portNumber;
@synthesize delegate = _delegate;
@synthesize secureConnection = _secureConnection;
@synthesize connectionIsValid = _connectionIsValid;
/*
 
 init
 
 */
- (id)init
{
	self = [super initWithWindowNibName:@"ConnectToServer"];

    if (self) {
        
    }
    
	return self;
}

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
    // get default connections. an array of immutable dictionaries
    NSArray *defConnections = (id)[[NSUserDefaults standardUserDefaults] objectForKey:@"MGSFavoriteConnections"];
    
    // make a mutable array of mutable dictionaries
    _connections = [NSMutableArray arrayWithCapacity:10];
    
    // array controller content is the connections array
    arrayController.content = _connections;
    
    // we need an array of mutable dict so that bindings can update it in the table view
    for (NSDictionary *defConnection in defConnections) {
        NSMutableDictionary *connection = [[NSMutableDictionary alloc] initWithDictionary:defConnection];
        [arrayController addObject:connection];
    }
    
    // the content outlet of objectController references this object.
    // so when the object fields are updated the roperties on this object are updated.
    
	// defaults
    [self clearSelection:self];
	
	// KVO
	[arrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:(void *)&MGSContextFavoritesSelectedObjects];
}

/*
 
 - setAddress:
 
 */
- (void)setAddress:(NSString *)value
{
    
    _address = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self validateConnectionValues];
}

/*
 
 - validateConnectionValues
 
 */
- (void) validateConnectionValues
{
    BOOL valid = YES;
    
    if ([self.address length] == 0) {
        valid = NO;
    }
    
    self.connectionIsValid = valid;
}

/*
 
 - setConnectionIsValid:
 
 */
- (void)setConnectionIsValid:(BOOL)value
{
    _connectionIsValid = value;
    [favoritesSegment setEnabled:_connectionIsValid forSegment:MGSAddFavorite];
}
/*
 
 show window
 
 */
- (void)showWindow:(id)sender
{
	#pragma unused(sender)
	
	[super showWindow:self];
}

/*
 
 - clearSelection:
 
 */
- (IBAction)clearSelection:(id)sender
{
	#pragma unused(sender)
	
    self.address = @"";
    self.displayName = @"";
	self.portNumber = MOTHER_IANA_REGISTERED_PORT;
	self.secureConnection = YES;
	self.keepConnected = NO;

	[arrayController setSelectedObjects:nil];
}

/*
 
 - commitEditing
 
 */
- (void)commitEditing
{
	[objectController commitEditing];
    [arrayController commitEditing];
}

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(change)
	#pragma unused(context)
	#pragma unused(object)
	
	BOOL enableRemove = NO;
	
	// selected favorites changed
	if (context == &MGSContextFavoritesSelectedObjects) {
		
		NSArray *array = [arrayController selectedObjects];
		if ([array count] > 0) {
			
			NSDictionary *dict = [array objectAtIndex:0];
			self.address = [[dict objectForKey:@"address"] copy];
			self.displayName = [[dict objectForKey:@"displayName"] copy];
			self.portNumber = [[dict objectForKey:@"portNumber"] intValue];
			self.secureConnection = [[dict objectForKey:@"secureConnection"] boolValue];
			self.keepConnected = [[dict objectForKey:@"keepConnected"] boolValue];
			enableRemove = YES;
		}
        
		[favoritesSegment setEnabled:enableRemove forSegment:MGSRemoveFavorite];
	
	// favorites selection index
	} else if (context == &MGSContextFavoritesSelectionIndex) {
		
		
	}

}

/*
 
 connect
 
 */
- (IBAction)connect:(id)sender
{
	#pragma unused(sender)
	
	[self commitEditing];
	
	if (!_address || [_address length] == 0) {
		return;
	}
    
	if (!_displayName || [_displayName length] == 0) {
		_displayName = [_address copy];
	}
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:_address, MGSNetClientKeyAddress,
						  [NSNumber numberWithInteger:_portNumber], MGSNetClientKeyPortNumber,
						   _displayName, MGSNetClientKeyDisplayName,
						   [NSNumber numberWithBool:_keepConnected], MGSNetClientKeyKeepConnected,
						   [NSNumber numberWithBool:_secureConnection], MGSNetClientKeySecureConnection,
						  nil];
	
	// create client for connection.
	_netClient = [[MGSNetClient alloc] initWithDictionary:dict];
	_netClient.delegate = self;
	if (!_netClient) {
		MLog(DEBUGLOG, @"net client is nil");
		return;
	}
	
	// prepare user interface
	[self setControlsEnabled:NO];
	[failedBox setHidden:YES];
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];
	
	// send heartbeat to client
	[[MGSClientRequestManager sharedController] requestHeartbeatForNetClient:_netClient withOwner:self];
}

/*
 
 net request response
 
 */
-(void)netRequestResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	[self setControlsEnabled:YES];

	[progressIndicator setHidden:YES];
	[progressIndicator stopAnimation:self];

	MGSNetClient *netClient = netRequest.netClient;
	
	// if no error in payload then heartbeat reply was received.
	// assume host is valid and contactable
	if (nil == payload.requestError) {
	
		[netClient setHostStatus:MGSHostStatusAvailable];
		
		// send our connectable client to our delegate
		[[MGSNetClientManager sharedController] addStaticClient:netClient];
		
		[self closeWindow];
	} else {
		[failedBox setHidden:NO];
	}
	
	_netClient = nil;
}

/*
 
 cancel
 
 */
- (IBAction)cancel:(id)sender
{
	#pragma unused(sender)
	
	[self closeWindow];
}

/*
 
 close window
 
 */
- (void)closeWindow
{
    // commit editing
	[self commitEditing];
	
    // persist our connections
    [[NSUserDefaults standardUserDefaults] setObject:arrayController.arrangedObjects forKey:@"MGSFavoriteConnections"];
    
	// save persistent clients.
	// this data will be used to instantiate MGSNetClient instances
	NSMutableArray *persistentClients = [NSMutableArray arrayWithCapacity:2];
	for (NSDictionary *dict in [arrayController content]) {
		
		if ([[dict objectForKey:@"keepConnected"] boolValue]) {
			NSDictionary *netClientDict = [NSDictionary dictionaryWithObjectsAndKeys:[dict objectForKey:@"address"], MGSNetClientKeyAddress,
							  [dict objectForKey:@"portNumber"], MGSNetClientKeyPortNumber,
							  [dict objectForKey:@"displayName"], MGSNetClientKeyDisplayName,
							  [NSNumber numberWithBool:YES], MGSNetClientKeyKeepConnected,
							  [dict objectForKey:@"secureConnection"], MGSNetClientKeySecureConnection,
							  nil];
		
			[persistentClients addObject:netClientDict];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:persistentClients forKey:MGSDefaultPersistentConnections];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[failedBox setHidden:YES];
	[progressIndicator setHidden:YES];
	[progressIndicator stopAnimation:self];
	
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:1];
}

/*
 
 process favorite mother segment control action
 
 */
- (IBAction)processFavorite:(id)sender
{
	#pragma unused(sender)
	
	[self commitEditing];
	
	int selectedSegment = [favoritesSegment selectedSegment];
	
	switch (selectedSegment) {
			
		// add favorite
		case MGSAddFavorite:;
			NSDictionary *item = [self connection];
			if (!item) {
				return;
			}
			[arrayController addObject:item];
			[arrayController setSelectedObjects:[NSArray arrayWithObject:item]];
			break;
		
		// remove favorite
		case MGSRemoveFavorite:;
			NSArray *selectedObjects = [arrayController selectedObjects];
			if ([selectedObjects count] > 0) {
				[arrayController removeObject:[selectedObjects objectAtIndex:0]];
			}
			break;

		default:
			return;
	}
	
	return;
}

/*
 
 - connection
 
 */
- (NSMutableDictionary *)connection
{
	if (!_address) return nil;
	if (!_displayName) _displayName = @"";
	
	// trim
	_address = [_address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	_displayName = [_displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([_address length] == 0) return nil;
	
	NSMutableDictionary *item = [NSMutableDictionary dictionaryWithObjectsAndKeys: [_address copy], @"address",
						  [_displayName copy], @"displayName", 
						  [NSNumber numberWithInteger:_portNumber], @"portNumber",
						  [NSNumber numberWithBool:_secureConnection], @"secureConnection",
						  [NSNumber numberWithBool:_keepConnected], @"keepConnected",
                          [NSString mgs_stringWithNewUUID], @"uuid", // make our dict unique
						  nil];
	
	return item;
}
@end
