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

NSString *MGSDefaultFavoriteConnections = @"MGSFavoriteConnections";

const char MGSContextFavoritesSelectedObjects;
const char MGSContextFavoritesSelectionIndex;

// class interface extension
@interface MGSAddServerWindowController()
- (NSDictionary *)favoriteItem;
- (void)updateSelectedObject;
@end

@implementation MGSAddServerWindowController

@synthesize address = _address;
@synthesize displayName = _displayName;
@synthesize keepConnected = _keepConnected;
@synthesize portNumber = _portNumber;
@synthesize delegate = _delegate;
@synthesize secureConnection = _secureConnection;

/*
 
 init
 
 */
- (id)init
{
	self = [super initWithWindowNibName:@"ConnectToServer"];
	//_tableRowSelected = NO;
	_delegate = nil;
	_netClient = nil;
	_mutatingSelectedObjects = NO;
	
	return self;
}

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	//[self setRemoveSegmentEnabledState];
	
	// something wrong here - perhaps fact that addressTextFieldis already bound to
	//[addressTextField addObserver:self forKeyPath:@"stringValue" options:NSKeyValueObservingOptionNew context:nil];
	//[displayNameTextField addObserver:self forKeyPath:@"stringValue" options:NSKeyValueObservingOptionNew context:nil];
	//[reconnectCheckBox addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
	
	// defaults
	self.portNumber = MOTHER_IANA_REGISTERED_PORT;
	self.secureConnection = YES;
	self.keepConnected = NO;
	
	// KVO
	[arrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:(void *)&MGSContextFavoritesSelectedObjects];
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
	self.keepConnected = NO;
	[arrayController setSelectedObjects:nil];
}

/*
 
 update properties
 
 */
- (void)updatePropertes
{
	[objectController commitEditing];
	//[arrayController commitEditing];
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
	
	BOOL enableRemove;
	
	// selected favorites changed
	if (context == &MGSContextFavoritesSelectedObjects) {
					  
		if (_mutatingSelectedObjects) {
			return;
		}
		
		// update selected object
		_mutatingSelectedObjects = YES;
		[self updateSelectedObject];
		_mutatingSelectedObjects = NO;
		
		NSArray *array = [arrayController selectedObjects];
		if ([array count] > 0) {
			
			NSDictionary *dict = [array objectAtIndex:0];
			self.address = [[dict objectForKey:@"address"] copy];
			self.displayName = [[dict objectForKey:@"displayName"] copy];
			self.portNumber = [[dict objectForKey:@"portNumber"] intValue];
			self.secureConnection = [[dict objectForKey:@"secureConnection"] boolValue];
			self.keepConnected = [[dict objectForKey:@"keepConnected"] boolValue];
			enableRemove = YES;
			
			_selectedObject = dict;
		} else {
			enableRemove = NO;
			_selectedObject = nil;
		}
		[favoritesSegment setEnabled:enableRemove forSegment:MGSRemoveFavorite];
	
	// favorites selection index
	} else if (context == &MGSContextFavoritesSelectionIndex) {
		
		
	}

}

/*
- (void)setRemoveSegmentEnabledState
{
	BOOL enableRemove = ([[arrayController arrangedObjects] count] > 0 ? YES : NO);
	[favoritesSegment setEnabled:enableRemove forSegment:MGSRemoveFavorite];
}
*/

/*
 
 connect
 
 */
- (IBAction)connect:(id)sender
{
	#pragma unused(sender)
	
	//[viewController commitEditing];
	//[self closeWindow];

	[self updateSelectedObject];
	
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
	[self updateSelectedObject];
	
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
	
	[self updatePropertes];
	
	int selectedSegment = [favoritesSegment selectedSegment];
	
	switch (selectedSegment) {
			
		// add favorite
		case MGSAddFavorite:;
			NSDictionary *item = [self favoriteItem];
			if (!item) {
				return;
			}
			[arrayController insertObject:item atArrangedObjectIndex:0];
			
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
 
 - favoriteItem
 
 */
- (NSDictionary *)favoriteItem
{
	if (!_address) return nil;
	if (!_displayName) _displayName = @"";
	
	// trim
	_address = [_address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	_displayName = [_displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([_address length] == 0) return nil;
	
	NSDictionary *item = [NSMutableDictionary dictionaryWithObjectsAndKeys: [_address copy], @"address",
						  [_displayName copy], @"displayName", 
						  [NSNumber numberWithInteger:_portNumber], @"portNumber",
						  [NSNumber numberWithBool:_secureConnection], @"secureConnection",
						  [NSNumber numberWithBool:_keepConnected], @"keepConnected",
						  nil];
	
	return item;
}
/*
 
 - updateSelectedObject
 
 */
- (void)updateSelectedObject
{
	if (!_selectedObject) {
		return;
	}
	
	// update our properties
	[self updatePropertes];
	
	NSUInteger selectedIndex = [[arrayController arrangedObjects] indexOfObject:_selectedObject];
	if (selectedIndex == NSNotFound) {
		return;
	}
	
	// get current favorite item
	NSDictionary *item = [self favoriteItem];
	if (!item) {
		return;
	}

	// remove old item and insert new at same location.
	// this gets noticed by KVO. just updating the item content doesn't.
	[arrayController removeObject:_selectedObject];
	[arrayController insertObject:item atArrangedObjectIndex:selectedIndex];
	
	_selectedObject = nil;
}

@end
