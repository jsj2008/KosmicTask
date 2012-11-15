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
#import "MGSImageManager.h"

NSString *MGSDefaultFavoriteConnections = @"MGSFavoriteConnections";

const char MGSContextFavoritesSelectedObjects;
const char MGSContextFavoritesSelectionIndex;

// class interface extension
@interface MGSAddServerWindowController()
- (NSMutableDictionary *)selectedConnection;
- (void)validateSelectedConnectionValues;
- (void)validateConnectionStatus;
- (MGSNetClient *)netClientForConnection:(NSDictionary *)connection;
- (MGSNetClient *)netClientForAddress:(NSString *)address port:(NSInteger)port;
@end

@implementation MGSAddServerWindowController

@synthesize address = _address;
@synthesize displayName = _displayName;
@synthesize keepConnected = _keepConnected;
@synthesize portNumber = _portNumber;
@synthesize delegate = _delegate;
@synthesize secureConnection = _secureConnection;
@synthesize selectedConnectionIsValid = _selectedConnectionIsValid;

#pragma mark -
#pragma mark Setup
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


#pragma mark -
#pragma mark Accessors
/*
 
 - setAddress:
 
 */
- (void)setAddress:(NSString *)value
{
    _address = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self validateSelectedConnectionValues];
}

/*
 
 - setPortNnumber:
 
 */
- (void)setPortNnumber:(NSInteger)value
{
    _portNumber = value;
    [self validateSelectedConnectionValues];
}

#pragma mark -
#pragma mark NSEditor protocol
/*
 
 - commitEditing
 
 */
- (void)commitEditing
{
	[objectController commitEditing];
    [arrayController commitEditing];
}

#pragma mark -
#pragma mark KVO

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
			self.address = [[dict objectForKey:MGSNetClientKeyAddress] copy];
			self.displayName = [[dict objectForKey:MGSNetClientKeyDisplayName] copy];
			self.portNumber = [[dict objectForKey:MGSNetClientKeyPortNumber] intValue];
			self.secureConnection = [[dict objectForKey:MGSNetClientKeySecureConnection] boolValue];
			self.keepConnected = [[dict objectForKey:MGSNetClientKeyKeepConnected] boolValue];
			enableRemove = YES;
		}
        
		[favoritesSegment setEnabled:enableRemove forSegment:MGSRemoveFavorite];
	
	// favorites selection index
	} else if (context == &MGSContextFavoritesSelectionIndex) {
		
		
	}

}

#pragma mark -
#pragma mark Validation

/*
 
 - validateSelectedConnectionValues
 
 */
- (void) validateSelectedConnectionValues
{
    BOOL valid = YES;
    
    if ([self.address length] == 0) {
        valid = NO;
    }
    if (![self.address mgs_isURLorIPAddress]) {
        valid = NO;
    }
    if (self.portNumber <= 1024 || self.portNumber > 65535) {
        valid = NO;
    }
    
    // invalidate if connected
    if ([self netClientForAddress:self.address port:self.portNumber]) {
        valid = NO;
    }
    
    self.selectedConnectionIsValid = valid;
}

/*
 
 - setConnectionIsValid:
 
 */
- (void)setSelectedConnectionIsValid:(BOOL)value
{
    _selectedConnectionIsValid = value;
    [favoritesSegment setEnabled:_selectedConnectionIsValid forSegment:MGSAddFavorite];
}

/*
 
 - validateConnectionStatus
 
 */
- (void)validateConnectionStatus
{
    for (NSMutableDictionary *connection in _connections) {
        
        BOOL isConnected = NO;
        
        // get net client instance if available
        MGSNetClient *netClient = [self netClientForConnection:connection];
        if (netClient) {
            isConnected = YES;
        }
        [connection setObject:[NSNumber numberWithBool:isConnected] forKey:@"isConnected"];
        
        // set connection image
        NSImage *isConnectedImage  = nil;
        if (isConnected) {
            isConnectedImage = [[[MGSImageManager sharedManager] greenDot] copy];
        } else {
            isConnectedImage = [[[MGSImageManager sharedManager] redDot] copy];
        }
        [connection setObject:isConnectedImage forKey:@"isConnectedImage"];
    }
}

#pragma mark -
#pragma mark Actions
/*
 
 connect
 
 */
- (IBAction)connect:(id)sender
{
	#pragma unused(sender)
	
	[self commitEditing];
	
    if (![self selectedConnectionIsValid]) {
        return;
    }
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:_address, MGSNetClientKeyAddress,
						  [NSNumber numberWithInteger:_portNumber], MGSNetClientKeyPortNumber,
						   _displayName, MGSNetClientKeyDisplayName,
						   [NSNumber numberWithBool:_keepConnected], MGSNetClientKeyKeepConnected,
						   [NSNumber numberWithBool:_secureConnection], MGSNetClientKeySecureConnection,
						  nil];
	
    // does a netClient already exist for this connection
    if ([self netClientForConnection:dict]) {
		MLogInfo(@"net client already exists for connection");
        return;
    }
    
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
 
 cancel
 
 */
- (IBAction)cancel:(id)sender
{
#pragma unused(sender)
	
	[self closeWindow];
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
			NSDictionary *item = [self selectedConnection];
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
	
    [self validateConnectionStatus];
    
	return;
}

#pragma mark -
#pragma mark MGSNetRequestOwner protocol

/*
 
 net request response
 
 */
-(void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
#pragma unused(payload)
	[self setControlsEnabled:YES];

	[progressIndicator setHidden:YES];
	[progressIndicator stopAnimation:self];

	MGSNetClient *netClient = netRequest.netClient;
	
	// if no error in payload then heartbeat reply was received.
	// assume host is valid and contactable
	if (!netRequest.error) {
	
		[netClient setHostStatus:MGSHostStatusAvailable];
		
		// send our connectable client to our delegate
		[[MGSNetClientManager sharedController] addStaticClient:netClient];
		
		[self closeWindow];
	} else {
        NSString *errorString = nil;
        switch (netRequest.error.code) {
            case MGSErrorCodeServerAccessDenied:
                errorString = netRequest.error.localizedDescription;
                break;
                
            default:
                errorString = NSLocalizedString(@"Connection failed.", @"Remote connection failed");
                break;
        }
        [failedLabel setStringValue:errorString];
		[failedBox setHidden:NO];
	}
	
    [self validateConnectionStatus];
    
	_netClient = nil;
}

#pragma mark -
#pragma mark NSWindowController

/*
 
 show window
 
 */
- (void)showWindow:(id)sender
{
#pragma unused(sender)
	
	[super showWindow:self];
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
    [self validateConnectionStatus];
    
    // the content outlet of objectController references this object.
    // so when the object fields are updated the roperties on this object are updated.
    
	// defaults
    [self clearSelection:self];
	
	// KVO
	[arrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:(void *)&MGSContextFavoritesSelectedObjects];
}
/*
 
 close window
 
 */
- (void)closeWindow
{
    // commit editing
	[self commitEditing];
	
    arrayController.content = nil;
    
	// save persistent clients.
	// this data will be used to instantiate MGSNetClient instances
	NSMutableArray *persistentClients = [NSMutableArray arrayWithCapacity:2];
	for (NSMutableDictionary *dict in _connections) {
		
		if ([[dict objectForKey:MGSNetClientKeyKeepConnected] boolValue]) {
            NSDictionary *netClientDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [dict objectForKey:MGSNetClientKeyAddress], MGSNetClientKeyAddress,
							  [dict objectForKey:MGSNetClientKeyPortNumber], MGSNetClientKeyPortNumber,
							  [dict objectForKey:MGSNetClientKeyDisplayName], MGSNetClientKeyDisplayName,
							  [NSNumber numberWithBool:YES], MGSNetClientKeyKeepConnected,
							  [dict objectForKey:MGSNetClientKeySecureConnection], MGSNetClientKeySecureConnection,
							  nil];
		
			[persistentClients addObject:netClientDict];
		}
        
        // remove transient objects
        [dict removeObjectForKey:@"isConnected"];
        [dict removeObjectForKey:@"isConnectedImage"];
	}
	[[NSUserDefaults standardUserDefaults] setObject:persistentClients forKey:MGSDefaultPersistentConnections];
    [[NSUserDefaults standardUserDefaults] setObject:_connections forKey:@"MGSFavoriteConnections"];
    

	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[failedBox setHidden:YES];
	[progressIndicator setHidden:YES];
	[progressIndicator stopAnimation:self];
	
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:1];
}

#pragma mark -
#pragma mark Connection management
/*
 
 - selectedConnection
 
 */
- (NSMutableDictionary *)selectedConnection
{
	if (!_address) return nil;
	if (!_displayName) _displayName = @"";
	
	// trim
	_address = [_address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	_displayName = [_displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([_address length] == 0) return nil;
	
	NSMutableDictionary *item = [NSMutableDictionary dictionaryWithObjectsAndKeys: [_address copy], MGSNetClientKeyAddress,
						  [_displayName copy], MGSNetClientKeyDisplayName, 
						  [NSNumber numberWithInteger:_portNumber], MGSNetClientKeyPortNumber,
						  [NSNumber numberWithBool:_secureConnection], MGSNetClientKeySecureConnection,
						  [NSNumber numberWithBool:_keepConnected], MGSNetClientKeyKeepConnected,
                          [NSNumber numberWithBool:NO], @"isConnected",
                          [NSString mgs_stringWithNewUUID], @"uuid", // make our dict unique
						  nil];
	
	return item;
}

/*
 
 - netClientForConnection:
 
 */
- (MGSNetClient *)netClientForConnection:(NSDictionary *)connection
{
    NSString *address = [connection objectForKey:MGSNetClientKeyAddress];
    NSInteger port = [[connection objectForKey:MGSNetClientKeyPortNumber] integerValue];
    
    MGSNetClient *netClient = [self netClientForAddress:address port:port];
    
    return netClient;
}

/*
 
 - netClientForAddress:port:
 
 */
- (MGSNetClient *)netClientForAddress:(NSString *)address port:(NSInteger)port
{
    MGSNetClient *netClient = [[MGSNetClientManager sharedController] clientForServiceName:address port:port];
    
    return netClient;
}

@end
