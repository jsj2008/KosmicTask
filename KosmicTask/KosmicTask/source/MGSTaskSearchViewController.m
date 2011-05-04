//
//  MGSTaskSearchViewController.m
//  Mother
//
//  Created by Jonathan on 01/12/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSTaskSearchViewController.h"
#import "MGSMother.h"
#import "MGSNotifications.h"
#import "MGSClientRequestManager.h"
#import "MGSNetClientManager.h"
#import "MGSNetRequestPayload.h"
#import "MGSRequestProgress.h"
#import "MGSScriptPlist.h"
#import "MGSTaskSpecifierManager.h"
#import "MGSTaskSpecifier.h"
#import "MGSImageManager.h"
#import "MGSScopeBarViewController.h"
#import "MGSAttachedWindowController.h"

// class extension
@interface MGSTaskSearchViewController()
- (void)tableDoubleClickAction:(id)sender;
- (void)searchFilterChanged:(NSNotification *)note;
@end

@implementation MGSTaskSearchViewController

@synthesize delegate = _delegate;
@synthesize resultActionArray = _resultActionArray;
@synthesize searchInProgress = _searchInProgress;
@synthesize searchActivity = _searchActivity;
@synthesize searchTargetsQueried = _searchTargetsQueried;
@synthesize searchTargetsResponded = _searchTargetsResponded;
@synthesize numberOfItemsFound = _numberOfItemsFound;
@synthesize numberOfMatches = _numberOfMatches;

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	// empty result array
	self.resultActionArray = [NSArray array];
	self.searchTargetsQueried = 0;
	self.numberOfItemsFound = -1;
	self.numberOfMatches = 0;
	
	// register for notifcations
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchFilterChanged:) name:MGSNoteSearchFilterChanged object:nil];
	
	// configure search table
	[_searchTableView setTarget:self];
	[_searchTableView setDoubleAction:@selector(tableDoubleClickAction:)];
	[_searchTableView setAllowsEmptySelection:YES];
	
	// create an action specifier handler to hold actions returned as search results
	_taskSpecManager = [[MGSTaskSpecifierManager alloc] init];
	[_taskSpecManager setDelegate:self];
	[_taskSpecManager bind:NSContentBinding toObject:self withKeyPath:@"resultActionArray" options:nil];
	[_taskSpecManager setAvoidsEmptySelection:NO];
	[_taskSpecManager setSelectsInsertedObjects:NO];
	
	// table column image
	NSTableColumn *tableColumn = [_searchTableView tableColumnWithIdentifier: @"activeimage"];
	[[tableColumn headerCell] setImage:[[[MGSImageManager sharedManager] onlineStatusHeader] copy]];
	
	// table column image
	tableColumn = [_searchTableView tableColumnWithIdentifier: @"identifier"];
	[[tableColumn headerCell] setImage:[[[MGSImageManager sharedManager] dotTemplate] copy]];
	
	// bundled column
	tableColumn = [_searchTableView tableColumnWithIdentifier: @"bundled"];
	[[tableColumn headerCell] setImage:[NSImage imageNamed:@"GearSmall"]];

	// published column
	// published column
	tableColumn = [_searchTableView tableColumnWithIdentifier: @"published"];
	[[tableColumn headerCell] setImage: [[[MGSImageManager sharedManager] publishedActionTemplate] copy]];
	
	[[_searchTableView tableColumnWithIdentifier:@"identifier"] bind:@"value" toObject:_taskSpecManager withKeyPath:@"arrangedObjects.identifier" options:nil];
	[[_searchTableView tableColumnWithIdentifier:@"group"] bind:@"value" toObject:_taskSpecManager withKeyPath:@"arrangedObjects.script.group" options:nil];
	[[_searchTableView tableColumnWithIdentifier:@"type"] bind:@"value" toObject:_taskSpecManager withKeyPath:@"arrangedObjects.script.scriptType" options:nil];
	[[_searchTableView tableColumnWithIdentifier:@"action"] bind:@"value" toObject:_taskSpecManager withKeyPath:@"arrangedObjects.script.name" options:nil];
	[[_searchTableView tableColumnWithIdentifier:@"description"] bind:@"value" toObject:_taskSpecManager withKeyPath:@"arrangedObjects.script.description" options:nil];
	[[_searchTableView tableColumnWithIdentifier:@"UUID"] bind:@"value" toObject:_taskSpecManager withKeyPath:@"arrangedObjects.script.UUID" options:nil];
	[[_searchTableView tableColumnWithIdentifier:@"bundled"] bind:@"value" toObject:_taskSpecManager withKeyPath:@"arrangedObjects.script.bundledIcon" options:nil];
	[[_searchTableView tableColumnWithIdentifier:@"published"] bind:@"value" toObject:_taskSpecManager withKeyPath:@"arrangedObjects.script.publishedIcon" options:nil];
	
	[[_searchTableView tableColumnWithIdentifier:@"machine"] bind:@"value" toObject:_taskSpecManager withKeyPath:@"arrangedObjects.netClient.serviceShortName" options:nil];
	[[_searchTableView tableColumnWithIdentifier:@"activeimage"] bind:@"value" toObject:_taskSpecManager withKeyPath:@"arrangedObjects.netClient.hostIcon" options:nil];
	
	// establish scope bar aux view
	[_searchProgressIndicator bind:NSAnimateBinding toObject:self withKeyPath:@"searchInProgress" options:nil];
	[_foundTextField bind:NSValueBinding toObject:self withKeyPath:@"searchActivity" options:nil];
	
	_searchID = 0;
}

/*
 
 search notifcation
 
 */
- (void)searchFilterChanged:(NSNotification *)note 
{
	NSString *queryString = [[note userInfo] objectForKey:MGSNoteValueKey];

	// if current query equals the last then bail.
	// No. its useful tosend the same query if change search scope etc
	if (NO) {
		if ([queryString isEqualToString:_queryString]) {
			return;
		}
	}
	
	// inform delegate
	if (_delegate && [_delegate respondsToSelector:@selector(searchViewController:searchFilterChanged:)]) {
		[_delegate searchViewController:self searchFilterChanged:note];
	}
	
	// search
	[self search:queryString];
}

/*
 
 search
 
 */
- (void)search:(NSString *)queryString
{
	// if search is in progress stop it 
	if (self.searchInProgress) {
		[self clearSearchResults];
	}
		
	// retain
	_queryString = [queryString copy];
	
	// clear our search results
	[self clearSearchResults];

	// validate the query string
	queryString = [queryString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (!queryString || [queryString isEqualToString:@""]) {
		
		self.numberOfMatches = 0;
		self.numberOfItemsFound = -1;
		
		// we don't want to send an empty query string
		return;
	} 
	// increment our search ID
	_searchID++;

	// set our search scope
	NSString *searchScope = MGSScriptSearchScopeContent;	// default to search content
	switch (_scopeBarViewController.searchAttribute) {
		
		// search script only
		case MGSSearchScript:
			searchScope = MGSScriptSearchScopeScript;
			break;
			
	}
	
	// create our search dict
	NSDictionary *searchDict = [NSDictionary dictionaryWithObjectsAndKeys:queryString, MGSScriptKeySearchQuery, 
								searchScope, MGSScriptKeySearchScope,
								[NSNumber numberWithUnsignedInteger:_searchID], MGSScriptKeySearchID, nil];
	
	// search who?
	switch (_scopeBarViewController.searchTarget) {
			
			// search local client
		case MGSSearchThisMac:
			
			// net client handler will send a request to local client
			[[MGSNetClientManager sharedController] requestSearchLocal:searchDict withOwner:self];
			
			// retain number of targets queried
			self.searchTargetsQueried = 1;
			break;
			
			// search shared clients
		case MGSSearchShared:
			[self sendSearchQueryToSharedClients:searchDict];
			break;

			// search other mac
		case MGSSearchOtherMac:
			[self sendSearchQuery:searchDict toClientServiceName:_scopeBarViewController.searchTargetIdentifier];
			break;
			
		default:
			NSAssert(NO, @"invalid search target");
			break;
	}

}

/*
 
 send search query to client with service name
 
 */
- (void)sendSearchQuery:(NSDictionary *)searchDict toClientServiceName:(NSString *)serviceName
{
	// net client handler will send a request to each client
	if ([[MGSNetClientManager sharedController] requestSearch:searchDict clientServiceName:serviceName withOwner:self]) {
	
		// retain number of targets queried
		self.searchTargetsQueried = 1;
	}
}
/*
 
 send search query to shared clients
 
 */
- (void)sendSearchQueryToSharedClients:(NSDictionary *)searchDict
{
	// net client handler will send a request to each client
	[[MGSNetClientManager sharedController] requestSearchShared:searchDict withOwner:self];
	
	// retain number of targets queried
	self.searchTargetsQueried = [[MGSNetClientManager sharedController] clientsCount] - 1;
}


/*
 
 net request response for net client
 
 */
-(void)netRequestResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	// check if all targets had responded
	if (++(self.searchTargetsResponded) >= self.searchTargetsQueried) {
		self.searchTargetsQueried = 0;
	}
	
	// parse request errors
	if (netRequest.error) {
		MLog(RELEASELOG, @"a search error has occurred");
		return;
	} 
	
	// process the payload
	if (![payload dictionary]) {
		MLog(RELEASELOG, @"search payload dictionary not found");
		return;
	}
		
	// look for result dict
	NSDictionary *resultDict = [[payload dictionary] objectForKey:MGSScriptKeyResult];
	if (!resultDict) {
		MLog(RELEASELOG, @"search result dictionary not found");
		return;
	}
	
	// search ID
	NSNumber *searchID = [resultDict objectForKey:MGSScriptKeySearchID];
	if (!searchID) {
		MLog(RELEASELOG, @"search ID not found");
		return;
	}
	
	// if search ID does not match current ID then we have received a result for a previous search.
	// discard it.
	if (_searchID != [searchID unsignedIntegerValue]) {
		return;
	}
	
	// search result array
	NSArray *resultArray = [resultDict objectForKey:MGSScriptKeySearchResult];
	if (!resultArray) {
		MLog(RELEASELOG, @"search result array not found");
		return;
	}
	
	// number of matches.
	// may not match the number of results if searching in public mode and matches
	// were found for authenticated user.
	NSUInteger numberOfMatches = [[resultDict objectForKey:MGSScriptKeyMatchCount] unsignedIntegerValue];
	
	// index
	NSInteger idx = [self.resultActionArray count] + 1;
	
	// create actions based on search results
	NSMutableArray *actionArray = [NSMutableArray arrayWithCapacity:1];
	for (NSDictionary *aDict in resultArray) {
		
		// create new action spec
		// our search results contain a subset of the action dictionary
		MGSTaskSpecifier *actionSpec = [[MGSTaskSpecifier alloc] initWithMinimalPlistRepresentation:aDict];
				
		// set the net client
		actionSpec.netClient = netRequest.netClient;
		actionSpec.identifier = idx++;
		
		// add the action to our array
		[actionArray addObject:actionSpec];
	}
	
	// append our array to existing array.
	// set our bound result action array.
	self.resultActionArray = [self.resultActionArray arrayByAddingObjectsFromArray:actionArray];

	self.numberOfMatches += numberOfMatches;
	self.numberOfItemsFound = self.resultActionArray.count;
}

/*
 
 set search targets queried
 
 */
- (void)setSearchTargetsQueried:(NSInteger)value
{
	_searchTargetsQueried = value;
	if (_searchTargetsQueried <= 0) {
		self.searchTargetsResponded = 0;
		self.searchInProgress = NO;
	} else {
		self.searchTargetsResponded = 0;
		self.searchInProgress = YES;
		self.numberOfItemsFound = 0;
	}
}
/*
 
 set search targets responded
 
 */
- (void)setSearchTargetsResponded:(NSInteger)value
{
	_searchTargetsResponded = value;
}
/*
 
 set search in progress
 
 */
- (void)setSearchInProgress:(BOOL)value
{
	_searchInProgress = value;
}

/*
 
 set number of items found
 
 */
- (void)setNumberOfItemsFound:(NSInteger)value
{
	NSString *activity =  @"";
	
	_numberOfItemsFound = value;
	if (_numberOfItemsFound >= 0) {
		activity = [NSString stringWithFormat: NSLocalizedString(@"%i Found", @"Task scope bar searching user feedback"), self.numberOfItemsFound];
		
		// if more matches available then results then show
		if (self.numberOfMatches > 0 && self.numberOfMatches > (NSUInteger)self.numberOfItemsFound) {
			activity = [activity stringByAppendingString:@" +"];
		}
	} 	
	self.searchActivity = activity;
}
/*
 
 clear search results
 
 */
- (void)clearSearchResults
{
	self.searchInProgress = NO;
	self.resultActionArray = [NSArray array];
	self.numberOfMatches = 0;
	self.numberOfItemsFound = 0;
}
/*
 
 scope bar selected state changed for item
 
 */
- (void)scopeBarControllerChanged:(MGSScopeBarViewController *)scopeBarController 
{
	#pragma unused(scopeBarController)
	
	// reissue existing query
	[self search:_queryString];
}

#pragma mark -
#pragma mark Actions

/*
 
 - tableDoubleClickAction:
 
 */
- (void)tableDoubleClickAction:(id)sender
{
#pragma unused(sender)
	
	if ([_searchTableView clickedRow] == -1) {
		return;
	}

	// send open document selector up the responder chain
	[NSApp sendAction:@selector(openDocument:) to:nil from:self];
}

#pragma mark -
#pragma mark MGSViewDelegateProtocol methods

/*
 
 view did move to super view
 
 */
- (void)viewDidMoveToSuperview:(NSView *)view
{
	#pragma unused(view)

	// if no search results visible then change search target to
	// currently selected client
	if ([_taskSpecManager.arrangedObjects count] == 0) {
		
		[_scopeBarViewController setNetClient:[[MGSNetClientManager sharedController] selectedNetClient]];
	}
}
#pragma mark NSTableView delegate messageSequenceCounter

/*
 
 table view selection did change
 
 */

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	#pragma unused(aNotification)
	
	/*
	// ignore the table selection change
	// when adding rows programmotically
	if (_ignoreTableSelectionChange) {
		_ignoreTableSelectionChange = NO;
		return;
	}
	*/
	
	NSInteger selectedRow = [_searchTableView selectedRow];
	if (selectedRow == -1) {
		return;
	}
	
	// get the selected object from the history (this is bound to the table)
	NSArray *selection = [_taskSpecManager selectedObjects];
	NSAssert([selection count] == 1, @"more than one search item selected");
	
	// get the action
	MGSTaskSpecifier *taskSpec = [selection objectAtIndex:0]; 
	
	// is the action available (ie: net client service available)?
	// this may occur for a history action whose client has not yet become
	// available or has become unavailable
	MGSTaskAvailability availability = taskSpec.isAvailable;
	if (availability != MGSTaskAvailable) {
		
		// get image cell rect in window coordinate system
		NSWindow *window =[[self view] window];
		NSRect cellRect = [_searchTableView frameOfCellAtColumn:[_searchTableView columnWithIdentifier:@"activeimage"] row:selectedRow];
		cellRect = [_searchTableView convertRect:cellRect toView:[window contentView]];
		
		NSString *windowText;
		
		if (availability == MGSTaskClientNotAvailable) {
			windowText = NSLocalizedString(@"This KosmicTask server is currently unavailable", @"history task client not available");
		} else {
			windowText = NSLocalizedString(@"This task is not currently available", @"history task not currently available");
		}
		
		// show message pointing to centre of image cell
		[[MGSAttachedWindowController sharedController] 
		 showForWindow:window
		 atCentreOfRect:cellRect 
		 withText:windowText];
		
		// do not want to delegate this action
		return;
	} else {
		// hide any window
		[[MGSAttachedWindowController sharedController] hide];
	}
	
	// look for modifier keys in current event
	int actionDisplayType;
	unsigned int flags = [[NSApp currentEvent] modifierFlags];
	if ((flags & NSCommandKeyMask) || (flags & NSAlternateKeyMask) || (flags & NSControlKeyMask)) {
		actionDisplayType = MGSTaskDisplayInNewTab;
	} else {
		actionDisplayType = MGSTaskDisplayInSelectedTab;
	}
	
	// invert action display
	/*if (_showActionInNewTab) {
	 
	 switch (_actionDisplayType) {
	 
	 case MGSActionDisplayInNewTab:
	 _actionDisplayType = MGSActionDisplayInSelectedTab;
	 break;
	 
	 case MGSActionDisplayInSelectedTab:
	 _actionDisplayType = MGSActionDisplayInNewTab;
	 break;
	 }
	 }*/
	
	// copy the action for delegate
	_delegatedAction = nil;
	_delegatedAction = [taskSpec historyCopy];
	_delegatedAction.displayType = actionDisplayType;
	
	// call delegate with action
	if (_delegate && [_delegate respondsToSelector:@selector(taskSearchView:actionSelected:)]) {
		[_delegate taskSearchView:self actionSelected:_delegatedAction];
	}
	
}

@end
