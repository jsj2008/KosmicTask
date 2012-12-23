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
const char MGSContextFirstResponder;

@implementation MGSAddServerArrayController

-(void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    [super setValue:value forKeyPath:keyPath];
}
- (BOOL)validateValue:(id *)ioValue forKeyPath:(NSString *)inKeyPath error:(NSError **)outError
{
    
#pragma unused(ioValue)
#pragma unused(inKeyPath)
#pragma unused(outError)
    
    BOOL isValid = YES;
    
    return isValid;
}
@end

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
@synthesize note = _note;
@synthesize canConnect = _canConnect;

#pragma mark -
#pragma mark Setup
/*
 
 init
 
 */
- (id)init
{
	self = [super initWithWindowNibName:@"ConnectToServer"];

    if (self) {
        _canConnect = YES;
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
 
 - setPortNumber:
 
 */
- (void)setPortNumber:(NSInteger)value
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
    #pragma mark NSMutableDictionary+KVCValidation protocol

    /*
     
     - validateValue:forKey:error:sender:
     
     */
    - (BOOL)validateValue:(id *)ioValue forKey:(NSString *)key error:(NSError **)outError sender:(NSMutableDictionary *)sender
    {
    #pragma unused(sender)
        
        BOOL isValid = YES;
        
        if ([key isEqualToString:MGSNetClientKeyPortNumber]) {
            
            if (![*ioValue isKindOfClass:[NSNumber class]] || [*ioValue integerValue] < 1025 || [*ioValue integerValue] > 65535) {
                *outError = [NSError errorWithDomain:@"Application"
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The entered port number is invalid.", @"comment"),
                                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Enter a number between 1025 and 65535.", @"comment")
                             }];
                isValid = NO;
            }
        } else if ([key isEqualToString:MGSNetClientKeyAddress]) {
            
            if (![*ioValue isKindOfClass:[NSString class]] || ![(NSString *)*ioValue mgs_isURLorIPAddress]) {
                
                isValid = NO;
                *outError = [NSError errorWithDomain:@"Application"
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The entered address is invalid.", @"comment"),
                                                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Enter a valid URL or IP address.", @"comment")
                                                    }];
            }
        }
        
        return isValid;
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
            self.note = [[dict objectForKey:MGSNetClientKeyNote] copy];
			enableRemove = YES;
            
            [self validateSelectedConnectionValues];
		}
        
		[favoritesSegment setEnabled:enableRemove forSegment:MGSRemoveFavorite];
	
	// favorites selection index
	} else if (context == &MGSContextFavoritesSelectionIndex) {
		
		
	} else if (context == &MGSContextFirstResponder) {
        NSResponder *firstResponder = self.window.firstResponder;
        
        if (![firstResponder isKindOfClass:[NSTableView class]]) {
            [arrayController setSelectedObjects:nil];
        }
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
        MGSAddServerStatusID statusId = [[connection objectForKey:@"statusID"] integerValue];
        
        // get net client instance if available
        MGSNetClient *netClient = [self netClientForConnection:connection];
        if (netClient) {
            isConnected = YES;
        }
        [connection setObject:[NSNumber numberWithBool:isConnected] forKey:@"isConnected"];
        
        // set connection image
        NSImage *isConnectedImage  = nil;
        if (isConnected || statusId == kMGSAddServerConnected) {
            isConnectedImage = [[[MGSImageManager sharedManager] greenDot] copy];
        } else {
            if (statusId == kMGSAddServerNotConnected) {
                isConnectedImage = [[[MGSImageManager sharedManager] redDot] copy];
            } else {
                isConnectedImage = [[[MGSImageManager sharedManager] yellowDot] copy];
            }
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
	_responder = [[self window] firstResponder];
    
	[self commitEditing];
	
    if (![self selectedConnectionIsValid]) {
        return;
    }
	    
    _outstandingRequestCount = 0;
    
    NSArray *connections = nil;
    if (arrayController.selectedObjects.count > 0) {
        connections = [arrayController selectedObjects];
        
    } else {
        NSMutableDictionary *connection = [NSMutableDictionary dictionaryWithObjectsAndKeys:_address, MGSNetClientKeyAddress,
						  [NSNumber numberWithInteger:_portNumber], MGSNetClientKeyPortNumber,
                          _displayName, MGSNetClientKeyDisplayName,
                          [NSNumber numberWithBool:_keepConnected], MGSNetClientKeyKeepConnected,
                          [NSNumber numberWithBool:_secureConnection], MGSNetClientKeySecureConnection,
						  nil];
        connections = @[connection];
    }
    
    // iterate over selected items
    for (NSDictionary *connection in connections) {
    
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[connection objectForKey:MGSNetClientKeyAddress], MGSNetClientKeyAddress,
                              [connection objectForKey:MGSNetClientKeyPortNumber], MGSNetClientKeyPortNumber,
                               [connection objectForKey:MGSNetClientKeyDisplayName], MGSNetClientKeyDisplayName,
                               [connection objectForKey:MGSNetClientKeyKeepConnected], MGSNetClientKeyKeepConnected,
                               [connection objectForKey:MGSNetClientKeySecureConnection], MGSNetClientKeySecureConnection,
                              nil];
        
        // does a netClient already exist for this connection
        if ([self netClientForConnection:dict]) {
            MLogInfo(@"net client already exists for connection");
            continue;
        }
        
        // create client for connection.
        MGSNetClient *netClient = [[MGSNetClient alloc] initWithDictionary:dict];
        netClient.delegate = self;
        if (!netClient) {
            MLogInfo(@"net client is nil");
            continue;
        }
        
        // send heartbeat to client.
        // the request will retain a ref to the netClient.
        MGSClientNetRequest *netRequest = [[MGSClientRequestManager sharedController] requestHeartbeatForNetClient:netClient withOwner:self];
        netRequest.tagObject = connection;
        
        [connection setValue:NSLocalizedString(@"Connecting...", @"comment") forKey:@"status"];
        [connection setValue:@(kMGSAddServerConnecting) forKey:@"statusID"];
        
        _outstandingRequestCount++;
    }
    
    // prepare user interface
    if (_outstandingRequestCount > 0) {
        //[self setControlsEnabled:NO];
        self.canConnect = NO;
        [failedBox setHidden:YES];
        [progressIndicator setHidden:NO];
        [progressIndicator startAnimation:self];
    }

    [self validateConnectionStatus];
    
    if (NO) {
        [arrayController setSelectedObjects:nil];
    }
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
    self.note = @"";
    
	[arrayController setSelectedObjects:nil];
}

/*
 
 process favorite mother segment control action
 
 */
- (IBAction)processFavorite:(id)sender
{
#pragma unused(sender)
	
	[self commitEditing];
	
	NSInteger selectedSegment = [favoritesSegment selectedSegment];
	
	switch (selectedSegment) {
			
            // add favorite
		case MGSAddFavorite:;
			NSMutableDictionary *connection = [self selectedConnection];
			if (!connection) {
				return;
			}
            connection.validationDelegate = self;
			[arrayController addObject:connection];
			[arrayController setSelectedObjects:[NSArray arrayWithObject:connection]];
            
            [tableView scrollRowToVisible:[tableView selectedRow]];
			break;
            
            // remove favorite
		case MGSRemoveFavorite:;
			NSArray *selectedObjects = [arrayController selectedObjects];
			if ([selectedObjects count] > 0) {
				[arrayController removeObjects:selectedObjects];
			}
			break;
            
		default:
			return;
	}
	
    [self validateConnectionStatus];
    
	return;
}

/*
 
 - checkboxClickAction:
 
 */
- (IBAction)checkboxClickAction:(id)sender
{
#pragma unused(sender)    
    [arrayController setSelectedObjects:nil];
}
#pragma mark -
#pragma mark MGSNetRequestOwner protocol

/*
 
 net request response
 
 */
-(void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
#pragma unused(payload)

	MGSNetClient *netClient = netRequest.netClient;
	_outstandingRequestCount--;
    
    NSString *status = NSLocalizedString(@"Connected", @"Comment");
    NSMutableDictionary *connection = netRequest.tagObject;
    
	// if no error in payload then heartbeat reply was received.
	// assume host is valid and contactable
	if (!netRequest.error) {
	
		[netClient setHostStatus:MGSHostStatusAvailable];
		
		// send our connectable client to our delegate
		[[MGSNetClientManager sharedController] addStaticClient:netClient];

        [connection setValue:@(kMGSAddServerConnected) forKey:@"statusID"];

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
        errorString = [errorString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
        [failedLabel setStringValue:errorString];
		[failedBox setHidden:NO];
        status = errorString;
        [connection setValue:@(kMGSAddServerNotConnected) forKey:@"statusID"];
        
	}

    [connection setObject:status forKey:@"status"];

    if (_outstandingRequestCount == 0) {
        self.canConnect = YES;
        //[self setControlsEnabled:YES];
        //[failedBox setHidden:YES];
        [progressIndicator setHidden:YES];
        
        if (_responder) {
            [[self window] makeFirstResponder:_responder];
        }
    }

    [self validateConnectionStatus];

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
        connection.validationDelegate = self;
        [arrayController addObject:connection];
    }
    [self validateConnectionStatus];
    
    // the content outlet of objectController references this object.
    // so when the object fields are updated the roperties on this object are updated.
    
	// defaults
    [self clearSelection:self];
	
	// KVO
	[arrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:(void *)&MGSContextFavoritesSelectedObjects];
    [self.window addObserver:self forKeyPath:@"firstResponder" options:0 context:(void *)&MGSContextFirstResponder];
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
                              [dict objectForKey:MGSNetClientKeyNote], MGSNetClientKeyNote,
							  [NSNumber numberWithBool:YES], MGSNetClientKeyKeepConnected,
							  [dict objectForKey:MGSNetClientKeySecureConnection], MGSNetClientKeySecureConnection,
							  nil];
		
			[persistentClients addObject:netClientDict];
		}
        
        // remove transient objects
        [dict removeObjectForKey:@"isConnected"];
        [dict removeObjectForKey:@"isConnectedImage"];
        [dict removeObjectForKey:@"status"];
        [dict removeObjectForKey:@"statusID"];
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
                          _note, MGSNetClientKeyNote,
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
