//
//  MGSScopeBarViewController.m
//  Mother
//
//  Created by Jonathan on 28/11/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSScopeBarViewController.h"
#import "MGScopeBar.h"
#import "MGSImageManager.h"
#import "MGSNotifications.h"
#import "MGSMotherModes.h"
#import "MGSNetClient.h"
#import "MGSNetClientManager.h"

// group IDs
#define SCOPE_SEARCH_GROUP_ID 0
#define SCOPE_ATTRIBUTE_GROUP_ID 1

// scope keys
#define GROUP_LABEL				@"Label"			// string
#define GROUP_SEPARATOR			@"HasSeparator"		// BOOL as NSNumber
#define GROUP_SELECTION_MODE	@"SelectionMode"	// MGScopeBarGroupSelectionMode (int) as NSNumber
#define GROUP_ITEMS				@"Items"			// array of dictionaries, each containing the following keys:
#define ITEM_IDENTIFIER			@"Identifier"		// string
#define ITEM_NAME				@"Name"				// string

NSString *MGSThisMacItemIdentifier = @"This Mac ID";
NSString *MGSSharedItemIdentifier = @"Shared Mac ID";
NSString *MGSAllItemIdentifier = @"All Mac ID";
//NSString *MGSAuthorItemIdentifier = @"Author";
NSString *MGSScriptItemIdentifier = @"Script";
NSString *MGSContentsItemIdentifier = @"Contents";

// class extension
@interface MGSScopeBarViewController()
@property (readwrite) NSInteger searchAttribute;		// override public declaration
@end

@interface MGSScopeBarViewController(Private)
- (void)netClientAvailable:(NSNotification *)notification;
- (void)netClientUnavailable:(NSNotification *)notification;
- (void)netClientSelected:(NSNotification *)notification;
- (void)reformScopeData;
@end

@implementation MGSScopeBarViewController

#pragma mark -
#pragma mark Accessors and properties

@synthesize groups;
@synthesize delegate = _delegate;
@synthesize searchTarget = _searchTarget;
@synthesize searchAttribute = _searchAttribute;
@synthesize searchTargetIdentifier = _searchTargetIdentifier;

#pragma mark -
#pragma mark Setup and teardown

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	scopeBar.delegate = self;
	[self reformScopeData];
	
	// radiotype groups autoselect item 0
	_searchTarget = MGSSearchThisMac;
	self.searchAttribute = MGSSearchContent;
	
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientAvailable:) name:MGSNoteClientAvailable object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientUnavailable:) name:MGSNoteClientUnavailable object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientSelected:) name:MGSNoteClientSelected object:nil];
}

/*
 
 dealloc
 
 */
- (void)dealloc
{
	self.groups = nil;
	[super dealloc];
}

/*
 
 set the search target net client
 
 */
- (void)setNetClient:(MGSNetClient * )netClient
{
	if (!netClient) return;
	
	NSAssert(netClient, @"netclient is nil");
	NSString *identifier = [netClient serviceName]; 

	// except for local host
	if ([netClient isLocalHost]) {
		identifier = MGSThisMacItemIdentifier;
	} 
	
	[scopeBar setSelected:YES forItem:identifier inGroup:SCOPE_SEARCH_GROUP_ID];
}
		  
#pragma mark -
#pragma mark MGScopeBarDelegate methods

/*
 
 number of groups in bar
 
 */
- (int)numberOfGroupsInScopeBar:(MGScopeBar *)theScopeBar
{
	#pragma unused(theScopeBar)
	
	return [self.groups count];
}


/*
 
 scope bar item identifiers
 
 */
- (NSArray *)scopeBar:(MGScopeBar *)theScopeBar itemIdentifiersForGroup:(int)groupNumber
{
	#pragma unused(theScopeBar)
	
	return [[self.groups objectAtIndex:groupNumber] valueForKeyPath:[NSString stringWithFormat:@"%@.%@", GROUP_ITEMS, ITEM_IDENTIFIER]];
}


/*
 
 scope bar label for group
 
 */
- (NSString *)scopeBar:(MGScopeBar *)theScopeBar labelForGroup:(int)groupNumber
{
	#pragma unused(theScopeBar)
	
	return [[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_LABEL]; // might be nil, which is fine (nil means no label).
}


/*
 
 scope bar title of item in group
 
 */
- (NSString *)scopeBar:(MGScopeBar *)theScopeBar titleOfItem:(NSString *)identifier inGroup:(int)groupNumber
{
	#pragma unused(theScopeBar)
	
	NSArray *items = [[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_ITEMS];
	if (items) {
		// We'll iterate here, since this is just a demo. This avoids having to keep an NSDictionary of identifiers 
		// for each group as well as an array for ordering. In a more realistic scenario, you'd probably want to be 
		// able to look-up an item by its identifier in constant time.
		for (NSDictionary *item in items) {
			if ([[item objectForKey:ITEM_IDENTIFIER] isEqualToString:identifier]) {
				return [item objectForKey:ITEM_NAME];
				break;
			}
		}
	}
	return nil;
}

/*
 
 scope bar selection mode for group
 
 */
- (MGScopeBarGroupSelectionMode)scopeBar:(MGScopeBar *)theScopeBar selectionModeForGroup:(int)groupNumber
{
	#pragma unused(theScopeBar)

	return [[[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_SELECTION_MODE] intValue];
}

/*
 
 scope bar show separtor before group
 
 */
- (BOOL)scopeBar:(MGScopeBar *)theScopeBar showSeparatorBeforeGroup:(int)groupNumber
{
	#pragma unused(theScopeBar)
	
	// Optional method. If not implemented, all groups except the first will have a separator before them.
	return [[[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_SEPARATOR] boolValue];
}

/*
 
 scope bar image for item
 
 */
- (NSImage *)scopeBar:(MGScopeBar *)scopeBar imageForItem:(NSString *)identifier inGroup:(int)groupNumber
{
	#pragma unused(scopeBar)
	#pragma unused(identifier)
	#pragma unused(groupNumber)
	
	return nil;
	
}

/*
 
 accessory view for scope bar
 
 */
- (NSView *)accessoryViewForScopeBar:(MGScopeBar *)scopeBar
{
	#pragma unused(scopeBar)
	
	// Optional method. If not implemented (or if you return nil), the scope-bar will not have an accessory view.
	return accessoryView;
}


/*
 
 scope bar selected state changed for item
 
 */
- (void)scopeBar:(MGScopeBar *)theScopeBar selectedStateChanged:(BOOL)selected 
		 forItem:(NSString *)identifier inGroup:(int)groupNumber
{
	#pragma unused(theScopeBar)
	
	if (!selected) return;
	
	switch (groupNumber) {
			
			// search group
		case SCOPE_SEARCH_GROUP_ID:
			
			// identifier is MGSNetClient serviceName
			[self willChangeValueForKey:@"searchTargetIdentifier"];
			_searchTargetIdentifier = identifier;
			[self didChangeValueForKey:@"searchTargetIdentifier"];

			[self willChangeValueForKey:@"searchTarget"];
			if ([identifier isEqualToString:MGSThisMacItemIdentifier]) {
				_searchTarget = MGSSearchThisMac;
			} else if ([identifier isEqualToString:MGSSharedItemIdentifier]) {
				_searchTarget = MGSSearchShared;
			} else if ([identifier isEqualToString:MGSAllItemIdentifier]) {
				_searchTarget = MGSSearchAll;
			} else {
				_searchTarget = MGSSearchOtherMac;
			}
			[self didChangeValueForKey:@"searchTarget"];
		break;
			
			// attribute group
		case SCOPE_ATTRIBUTE_GROUP_ID:
			if ([identifier isEqualToString:MGSContentsItemIdentifier]) {
				self.searchAttribute = MGSSearchContent;
			} else if ([identifier isEqualToString:MGSScriptItemIdentifier]) {
				self.searchAttribute = MGSSearchScript;
			}
			break;
			
		default:
			NSAssert(NO, @"invalid group ID");
			break;
	}
	

	if (_delegate && [_delegate respondsToSelector:@selector(scopeBarControllerChanged:)]) {
		[_delegate scopeBarControllerChanged:self];
	}
}



@end

#pragma mark -
@implementation MGSScopeBarViewController(Private)

/*
 
 a net client has become available
 
 */
- (void)netClientAvailable:(NSNotification *)notification
{
	MGSNetClient *netClient = [notification object];
	NSAssert([netClient isKindOfClass:[MGSNetClient class]], @"net client is not notification object");
	
	[self reformScopeData];
}


/*
 
 net client is no longer available
 
 */
- (void)netClientUnavailable:(NSNotification *)notification
{
	MGSNetClient *netClient = [notification object];
	NSAssert([netClient isKindOfClass:[MGSNetClient class]], @"net client is not notification object");
	
	[self reformScopeData];
}

/*
 
 net client selected in browser
 
 */
- (void)netClientSelected:(NSNotification *)notification
{
	// ignore if we sent the notification
	if ([notification object] == self) {
		return;
	}
	
	NSDictionary *userInfo = [notification userInfo];
	NSString *clientName = [userInfo objectForKey:MGSNoteClientNameKey];
	NSAssert(clientName, @"client name is nil");
	
}

/*
 
 reform scope data
 
 */
- (void)reformScopeData
{
	@try {
		
		MGSNetClientManager *netClientHandler = [MGSNetClientManager sharedController];
		
		// In this method we basically just set up some sample data for the scope bar, 
		// so that we can respond to the MGScopeBarDelegate methods easily.
		
		self.groups = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray *items = [NSMutableArray arrayWithCapacity:1];
		
		// loop through net clients
		NSDictionary *dict = nil;
		for (int i = 0; i < [netClientHandler clientsCount]; i++ ) {
			
			// get our client
			MGSNetClient *netClient = [netClientHandler clientAtIndex:i]; 
			
			// we can only search connected clients.
			// eg: a manual client may not have been able to connect
			if (![netClient isConnected]) {
				continue;
			}
			
            // a client may hve connected but if we don't have
            //a task list for it then it will be flagged as invisible
            if (![netClient visible]) {
				continue;
			}

			// our first item is our local host
			if ([netClient isLocalHost]) {
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
						MGSThisMacItemIdentifier, ITEM_IDENTIFIER, 
						NSLocalizedString(@"This Mac", @"scope bar text"), ITEM_NAME, 
						nil]; 
				[items insertObject:dict atIndex:0];
			} else {
				// using service name here should make our key unique
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
						[netClient serviceName], ITEM_IDENTIFIER, 
						[netClient serviceShortName], ITEM_NAME, 
						nil]; 
				[items addObject:dict];
			}
		}

		// if have more than two clients then we want a shared item too
		if ([items count] > 2) {
			dict = [NSDictionary dictionaryWithObjectsAndKeys:
			 MGSSharedItemIdentifier, ITEM_IDENTIFIER, 
			 NSLocalizedString(@"Shared", @"scope bar text"), ITEM_NAME, 
					nil];
			[items addObject:dict];
		}
		
        // if have more than one client then we want an all item too
		if ([items count] > 1) {
			dict = [NSDictionary dictionaryWithObjectsAndKeys:
                    MGSAllItemIdentifier, ITEM_IDENTIFIER,
                    NSLocalizedString(@"All", @"scope bar text"), ITEM_NAME,
					nil];
			[items addObject:dict];
		}

		// SCOPE_SEARCH_GROUP_ID
		[self.groups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								NSLocalizedString(@"Search:", @"Scope bar group label text"), GROUP_LABEL, 
								[NSNumber numberWithBool:NO], GROUP_SEPARATOR, 
								[NSNumber numberWithInt:MGRadioSelectionMode], GROUP_SELECTION_MODE, // single selection group.
								items, GROUP_ITEMS, 
								nil]];
		
		// Add second group of items.
		items = [NSArray arrayWithObjects:
				 [NSDictionary dictionaryWithObjectsAndKeys:
				  MGSContentsItemIdentifier, ITEM_IDENTIFIER, 
				  NSLocalizedString(@"Contents", @"Item scope bar text"), ITEM_NAME, 
				  nil], 
				 [NSDictionary dictionaryWithObjectsAndKeys:
				  MGSScriptItemIdentifier, ITEM_IDENTIFIER, 
				  NSLocalizedString(@"Script", @"Item scope bar text"), ITEM_NAME, 
				  nil], 
				 nil];
		
		// SCOPE_ATTRIBUTE_GROUP_ID
		[self.groups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								// deliberately not specifying a label
								[NSNumber numberWithBool:YES], GROUP_SEPARATOR, 
								[NSNumber numberWithInt:MGRadioSelectionMode], GROUP_SELECTION_MODE, // multiple selection group.
								items, GROUP_ITEMS, 
								nil]];
		
		// reload it
		[scopeBar reloadData];
		
	} @catch (NSException *e) {
		MLog(RELEASELOG, @"Exception forming scope data: %@", [e reason]);
	}

}
@end

