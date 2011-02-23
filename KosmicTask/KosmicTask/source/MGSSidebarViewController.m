//
//  MGSSidebarViewController.m
//  Mother
//
//  Created by Jonathan on 14/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSSidebarViewController.h"
#import "MGSOutlineViewNode.h"
#import "MGSImageManager.h"
#import "MGSPath.h"
#import "MGSNotifications.h"
#import "MGSNetClient.h"
#import "MGSNetClientContext.h"
#import "MGSClientScriptManager.h"
#import "MGSScriptManager.h"
#import "MGSMotherModes.h"
#import "MGSImageAndTextCell.h"
#import "MGSClientTaskController.h"
#import "NSTreeController-DMExtensions.h"
#import "MGSTaskSpecifier.h"
#import "MGSSidebarOutlineView.h"
#include <sys/time.h>

#define HOME_NODE_INDEX 0
#define SHARED_NODE_INDEX 1

NSString * const MGSNodeKeyPrefixScriptGroupAll = @"$SCRIPT-ALL$";
NSString * const MGSNodeKeyPrefixScriptGroup = @"$SCRIPT-GRP$";
NSString * const MGSNodeKeyGroupPrefix = @"$GROUP$";

NSString *MGSNodeTypeScript = @"script";
NSString *MGSNodeTypeGroup = @"group";

char MGSScriptDictContext;

// class extension
@interface MGSSidebarViewController()

- (void)netClientAvailable:(NSNotification *)notification;
- (void)netClientUnavailable:(NSNotification *)notification;
- (void)netClientSelected:(NSNotification *)notification;
- (void)netClientItemSelected:(NSNotification *)notification;
- (void)buildClientTree:(MGSNetClient *)netClient atNode:(MGSOutlineViewNode *)clientNode;
- (void)processOutlineNode:(MGSOutlineViewNode *)node options:(NSSet *)options;
- (void)expandNode:(MGSOutlineViewNode *)node;
- (void)selectNode:(MGSOutlineViewNode *)node;
- (MGSOutlineViewNode *)rootNodeForNetClient:(MGSNetClient *)netClient;
- (int)nodeIndex:(int)index selectChildName:(NSString *)name;
- (void)addClientObservations:(MGSNetClient *)netClient;
- (void)removeClientObservations:(MGSNetClient *)netClient;
- (NSTreeNode *)nodeIndex:(int)index findChildName:(NSString *)name;
- (void)selectedNodeDidChange:(MGSOutlineViewNode *)node;
- (IBAction)outlineDoubleAction:(id)sender;
- (void)taskSaved:(NSNotification *)notification;
- (MGSOutlineViewNode *)newTreeNodeWithObject:(id)object type:(NSString *)type options:(NSDictionary *)options;
- (MGSOutlineViewNode *)newGroupTreeNodeWithObject:(id)object netClient:(MGSNetClient *)netClient;
- (MGSOutlineViewNode *)newScriptTreeNodeWithObject:(MGSScript *)script keyPrefix:(NSString *)keyPrefix netClient:(MGSNetClient *)netClient;
- (NSString *)nodeKeyForGroup:(NSString *)groupName;
- (NSMutableDictionary *)nodeCacheForNetClient:(MGSNetClient *)netClient;
- (void)scriptScheduledForDelete:(NSNotification *)notification;
- (void)willUndoConfigurationChanges:(NSNotification *)notification;
- (void)updateNodeForNetClient:(MGSNetClient *)netClient script:(MGSScript *)script;
- (void)removeNode:(MGSOutlineViewNode *)node netClient:(MGSNetClient *)netClient;
- (void)removeNodeWithKey:(id)key netClient:(MGSNetClient *)netClient;
- (MGSOutlineViewNode *)nodeWithKey:(id)key netClient:(MGSNetClient *)netClient;
- (void)cacheNode:(MGSOutlineViewNode *)node withKey:(id)key netClient:(MGSNetClient *)netClient;
@property MGSNetClient *selectedNetClient;
@property id selectedObject;
@end

@implementation MGSSidebarViewController

@synthesize clientTree;
@synthesize selectedNetClient, selectedObject;

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	_selectionIndexPaths = nil;
	_selectionGroupNode = nil;
	_netClients = [NSMutableArray arrayWithCapacity:10];
	NSMutableArray *tree = [NSMutableArray arrayWithCapacity:10];
	_postNetClientSelectionNotifications = YES;
	outlineNodeCache = [NSMutableDictionary dictionaryWithCapacity:10];
	
	[outlineView setIndentationPerLevel:10];
	[outlineView setDoubleAction:@selector(outlineDoubleAction:)];
	[outlineView setTarget:self];
	
	// create a NSTreeController
	clientTreeController = [[NSTreeController alloc] init];
	[clientTreeController setSelectsInsertedObjects:NO];
	[clientTreeController setChildrenKeyPath:@"childNodes"];	// NSTreeNode method
	[clientTreeController bind:NSContentBinding toObject:self withKeyPath:@"clientTree" options:nil];
		
	// setup the bindings
	//
	// so the low down here is that outline view content needs arrangedobjects
	// while each column needs to be bound to an arranged object.
	// the column's value path is bound to an object.
	// that object is sent to a column's cell (normally and NSTextFieldCell) with the setObject:(id)value message.
	// so:
	//    	[[outlineView tableColumnWithIdentifier:@"main"] bind:@"value" toObject:_outlineController withKeyPath:@"arrangedObjects.representedObject.name" options:nil];
	// would pass the represented objects name value (NSString) to an NSTextFieldCells setObjectValue.
	// In this case however the tablecolumn cell has been subclassed to ImageAndTextCell.h.
	// We need to pass in more than just a string (ie: the text and the image).
	// So pass in the represented object itself.
	// And in the subclassed cell set override - (void)setObjectValue:(id)value to parse
	// the value object from the text and image properties which are then set within the cell.
	//
	[outlineView bind:NSContentBinding toObject:clientTreeController withKeyPath:@"arrangedObjects" options:nil];
	[outlineView bind:NSSelectionIndexPathsBinding toObject:clientTreeController withKeyPath:@"selectionIndexPaths" options:nil];
	[[outlineView tableColumnWithIdentifier:@"main"] bind:@"value" toObject:clientTreeController withKeyPath:@"arrangedObjects.bindingObject" options:nil];

	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientAvailable:) name:MGSNoteClientAvailable object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientUnavailable:) name:MGSNoteClientUnavailable object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientSelected:) name:MGSNoteClientSelected object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientItemSelected:) name:MGSNoteClientItemSelected object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskSaved:) name:MGSNoteActionSaved object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptScheduledForDelete:) name:MGSNoteScriptScheduledForDelete object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willUndoConfigurationChanges:) name:MGSNoteWillUndoConfigurationChanges object:nil];

	
	// build the initial client tree
	
	// home root
	NSString *rootName =  NSLocalizedString(@"HOME", @"sidebar home folder name");
	_homeNode = [[MGSOutlineViewNode alloc] initWithRepresentedObject:rootName];
	[tree addObject:_homeNode];

	// shared root
	rootName =  NSLocalizedString(@"SHARED", @"sidebar shared folder name");
	_sharedNode = [[MGSOutlineViewNode alloc] initWithRepresentedObject:rootName];	
	[tree addObject: _sharedNode];
	
	self.clientTree = tree;
	
}


#pragma mark -
#pragma mark OutlineView node handling 
/*
 
 - expandNode:
 
 */
- (void)expandNode:(MGSOutlineViewNode *)node
{
	[self processOutlineNode:node options:[NSSet setWithObjects:@"expand", nil]];
}
/*
 
 - expandNode:
 
 */
- (void)selectNode:(MGSOutlineViewNode *)node
{
	[self processOutlineNode:node options:[NSSet setWithObjects:@"select", nil]];
}
/*
 
 - processOutlineNode:options:
 
 */
- (void)processOutlineNode:(MGSOutlineViewNode *)node options:(NSSet *)options
{
	NSAssert([node isKindOfClass:[MGSOutlineViewNode class]], @"bad node class");
	[clientTreeController mgs_processOutlineView:outlineView node:node options:options];
}



/*
 
 select child with matching name
 
 */
- (int)nodeIndex:(int)idx selectChildName:(NSString *)name
{
	int childIndex = 0;
	NSArray *childNodes = [[clientTreeController arrangedObjects] childNodes];
	NSTreeNode *parentNode = [childNodes objectAtIndex:idx];
	for (NSTreeNode *childNode in [parentNode childNodes]) {
		MGSOutlineViewNode *node =  [childNode representedObject];
		if ([name isEqualToString:[node name]]) {
			NSUInteger indexes[2];
			indexes[0] = idx;
			indexes[1] = childIndex;
			[clientTreeController setSelectionIndexPath:[NSIndexPath indexPathWithIndexes:indexes length:2]];
			return childIndex;
		}
		childIndex++;
	}
	
	return -1;
}

/*
 
 find child treenode with matching name
 
 */
- (NSTreeNode *)nodeIndex:(int)idx findChildName:(NSString *)name
{
	NSArray *childNodes = [[clientTreeController arrangedObjects] childNodes];
	NSTreeNode *parentNode = [childNodes objectAtIndex:idx];
	for (NSTreeNode *childNode in [parentNode childNodes]) {
		MGSOutlineViewNode *node =  [childNode representedObject];
		if ([name isEqualToString:[node name]]) {
			return childNode;
		}
	}
	
	return nil;
}

/*
 
 root node for net client
 
 */
- (MGSOutlineViewNode *)rootNodeForNetClient:(MGSNetClient *)netClient
{
	// home or shared 
	if ([netClient isLocalHost]) {
		return _homeNode;
	} else {
		return _sharedNode;
	}
}

#pragma mark -
#pragma mark Tree model

/*
 
 - buildClientTree:atNode:
 
 */
- (void)buildClientTree:(MGSNetClient *)netClient atNode:(MGSOutlineViewNode *)clientNode
{
	/*get current scroll position
	NSPoint currentScrollPosition = [[myScrollView contentView] bounds].origin;
	
	//reload OutlineView/ScrollView	
	
	//restore scroll position
	[[myScrollView documentView] scrollPoint:currentScrollPosition];
	*/
	
	[[clientNode mutableChildNodes] removeAllObjects];

	// get the script manager for the client
	MGSClientScriptManager *scriptManager = [netClient.taskController scriptManager];		
	NSAssert(scriptManager, @"script controller is nil");
	
	clientNode.count = 0;
	
	// create a cache to hold node references keyed by the netclient service name.
	// we replace any existing object.
	/*
	 
	 the cache provides a convenient way to lookup any node based on its key.
	 the key will normally bederived wither from the node name or the represented object.
	 
	 */
	NSMutableDictionary *clientNodeCache = [NSMutableDictionary dictionaryWithCapacity:300];
	[outlineNodeCache setObject:clientNodeCache forKey:[netClient serviceName]];
	
	NSMutableArray *clientChildeNodes = [NSMutableArray arrayWithCapacity:100];
	
	// build task group tree
	NSArray *groupNames = [scriptManager groupNames];
	NSString *scriptKeyPrefix = nil;
	for (NSString *groupName in groupNames) {
		
		// make a group node
		MGSOutlineViewNode *groupNode = [self newGroupTreeNodeWithObject:groupName netClient:netClient];
		
		// get script handler for group name
		MGSScriptManager *groupScriptManager = [scriptManager groupWithName:groupName];
		if (groupScriptManager.hasAllScripts) {
			// it should be possible to get the count from the script controller
			// but count always represents the publish group
			clientNode.count = [groupScriptManager count];
			
			// script object will appear twice.
			// once in the all group and once in their named group
			scriptKeyPrefix = MGSNodeKeyPrefixScriptGroupAll;
		} else {
			scriptKeyPrefix = MGSNodeKeyPrefixScriptGroup;
		}
		
		// add the group node
		//[[clientNode mutableChildNodes] addObject:groupNode];
		[clientChildeNodes addObject:groupNode];
		
		// add tasks
		for (int i = 0; i < [groupScriptManager count]; i ++) {
			MGSScript *script = [groupScriptManager itemAtIndex:i];
			
			// make a script node.
			// at present we do not observe the script properties directly as when the scrip is eduted and then updated
			// the internal dictionary representation is replaced rather than individual properties being updated
			// via KVC compliant methods.			
			// we could, of course, define dependent keys but they are rather numerous.
			MGSOutlineViewNode *scriptNode = [self newScriptTreeNodeWithObject:script 
																	 keyPrefix:scriptKeyPrefix
																	 netClient:netClient];
			
			// add the script node to the group
			[[groupNode mutableChildNodes] addObject:scriptNode];
			
		}
		
		[groupNode sortNameRecursively:NO];
	}
	
	[[clientNode mutableChildNodes] setArray:clientChildeNodes];
	
}

/*
 
 - newTreeNodeWithObject:type:options:
 
 */
- (MGSOutlineViewNode *)newTreeNodeWithObject:(id)object type:(NSString *)type options:(NSDictionary *)options
{
	
	MGSOutlineViewNode *node = [[MGSOutlineViewNode alloc] initWithRepresentedObject:object];
	node.type = type;
	node.options = options;
	
	return node;
}

/*
 
 - newGroupTreeNodeWithObject:netClient:
 
 */
- (MGSOutlineViewNode *)newGroupTreeNodeWithObject:(id)object netClient:(MGSNetClient *)netClient
{
	NSAssert([object isKindOfClass:[NSString class]], @"bad object class");
	
	// get the script manager for the client
	MGSClientScriptManager *scriptManager = [netClient.taskController scriptManager];		
	NSAssert(scriptManager, @"script controller is nil");

	// make a group node
	MGSOutlineViewNode *node = [self newTreeNodeWithObject:object type:MGSNodeTypeGroup options:nil];
	
	// get script handler for group name
	MGSScriptManager *groupScriptManager = [scriptManager groupWithName:object];
	
	// get image for the group
	node.image = [[groupScriptManager displayObject] image];
	node.hasCount = YES;
	node.countChildNodes = YES;

	// add to the node map
	NSString *nodeKey = [self nodeKeyForGroup:object];
	[self cacheNode:node withKey:nodeKey netClient:netClient];
	
	return node;
}
/*
 
 - newScriptTreeNodeWithObject:
 
 */
- (MGSOutlineViewNode *)newScriptTreeNodeWithObject:(MGSScript *)script keyPrefix:(NSString *)keyPrefix netClient:(MGSNetClient *)netClient
{
	MGSOutlineViewNode *node = [self newTreeNodeWithObject:script
															type:MGSNodeTypeScript 
														 options:nil];
	node.image = [[[MGSImageManager sharedManager] scriptOutline] copy];
	
	// we can observe the script dict being updated
	// [script addObserver:self forKeyPath:@"dict" options:0 context:(void *)netClient];			
	
	// in order to track the relation ship between the script node and the represented object
	// we maintain a map of the outline nodes.
	//
	// we could use the script itself as the key but this has selveral problems.
	// 1. keys get copied, which is too resource intensive.
	// 2. the scripts may appear in multiple nodes, each of which will require separate keys.
	//
	// we could use the UUID as the key, except that it is not unique across all machines
	// for application tasks and it would only provide one key (unless prefixed).
	// the above is true if a global node map is maintained.
	// infact a separate node map is maintained for each netclient subtree
	//
	// the solution is to provide a globally unique master key (call MGSScript -keyWithString:nil) to which
	// we prefix any number of additional characters
	//
	// when the script is selected for editing a mutable deep copy is created.
	// this copy includes the master and derived keys.
	// when the script is saved the original object internal dict representation is discarded and replaced by the new, edited, copy
	NSString *nodeKey = [script keyWithString:keyPrefix];
	[self cacheNode:node withKey:nodeKey netClient:netClient];
	
	return node;
}

/*
 
 - removeNode:netClient:
 
 */
- (void)removeNode:(MGSOutlineViewNode *)node netClient:(MGSNetClient *)netClient
{
	NSMutableDictionary *clientNodeCache = [self nodeCacheForNetClient:netClient];
	for (id key in [clientNodeCache allKeysForObject:node]) {
		[self removeNodeWithKey:key netClient:netClient];
	}
}

/*
 
 - removeNodeWithKey:netClient:
 
 */
- (void)removeNodeWithKey:(id)key netClient:(MGSNetClient *)netClient
{
	// get node from client node dictionary
	NSMutableDictionary *clientNodeCache = [self nodeCacheForNetClient:netClient];
	MGSOutlineViewNode *node = [clientNodeCache objectForKey:key];	

	NSAssert(node, @"node to remove is nil");
	
	// remove node from dictionary
	[clientNodeCache removeObjectForKey:key];
	
	// remove from parent
	[node removeFromParent];
}


#pragma mark -
#pragma mark Node cache

/*
 
 - cacheNode:withKey:netClient:
 
 */
- (void)cacheNode:(MGSOutlineViewNode *)node withKey:(id)key netClient:(MGSNetClient *)netClient
{
	NSMutableDictionary *clientNodeCache = [self nodeCacheForNetClient:netClient];
	[clientNodeCache setObject:node forKey:key];
}

/*
 
 - nodeWithKey:netClient:
 
 */
- (MGSOutlineViewNode *)nodeWithKey:(id)key netClient:(MGSNetClient *)netClient
{
	NSMutableDictionary *clientNodeCache = [self nodeCacheForNetClient:netClient];
	return [clientNodeCache objectForKey:key];
}

/*
 
 - nodeKeyForGroup:
 
 */
- (NSString *)nodeKeyForGroup:(NSString *)groupName
{
	return [NSString stringWithFormat:@"%@%@", MGSNodeKeyGroupPrefix, groupName];
}

/*
 
 - nodeCacheForNetClient
 
 */
- (NSMutableDictionary *)nodeCacheForNetClient:(MGSNetClient *)netClient
{
	return [outlineNodeCache objectForKey:[netClient serviceName]];
}

#pragma mark -
#pragma mark Task notifications
/*
 
 - taskSaved:
 
 */
- (void)taskSaved:(NSNotification *)notification
{
	// get saved task info
	MGSTaskSpecifier *task = [notification object];
	MGSNetClient *netClient = [task netClient];
	NSString *scriptUUID = [[task script] UUID];

	/*
	 
	 the saved task will have been operating upon a deep copy of the script with scriptUUID.
	 we want to retrieve the updated original from the client scriptManager.
	 
	 */
	MGSScript *script = [[netClient.taskController scriptManager] scriptForUUID:scriptUUID];
	NSAssert(script, @"cannot retrieve saved script using given UUID");
	
	[self updateNodeForNetClient:netClient script:script];
}

/*
 
 - updateNodeForNetClient:script:
 
 */
- (void)updateNodeForNetClient:(MGSNetClient *)netClient script:(MGSScript *)script
{

	MGSClientScriptManager *scriptManager = [netClient.taskController scriptManager];
	NSMutableDictionary *clientNodeCache = [self nodeCacheForNetClient:netClient];

	/* look for relevant node.
	   if not found, we add a new node.
	   note we use the mapTable as our node represented object may occur on multiple nodes
	
	   for tasks we do not simply observe the name property as the internal script dictionary
	   rep is updated in one operation using setDict.
	   we can observe -dict and update on it but it only applies for edits not for new tasks.
	   hence it is easier to handle both additions and updates together here.
	 
	 */
	// get nodes
	MGSOutlineViewNode *rootNode = [self rootNodeForNetClient:netClient];
	MGSOutlineViewNode *clientNode = [rootNode descendantNodeWithRepresentedObject:netClient];
	NSAssert(clientNode, @"net client node is nil");
	
	// get all group script node
	NSString *nodeKey = [script keyWithString:MGSNodeKeyPrefixScriptGroupAll];
	MGSOutlineViewNode *scriptNode = [clientNodeCache objectForKey:nodeKey];
	if (scriptNode) {
		[scriptNode representedObjectDidChange];
	}
	
	// get script group node
	nodeKey = [script keyWithString:MGSNodeKeyPrefixScriptGroup];
	scriptNode = [clientNodeCache objectForKey:nodeKey];
	BOOL isNewTask = NO;
	
	// if node esists we are saving edits to an existing script
	if (scriptNode) {
		[scriptNode representedObjectDidChange];
		
		// check for change of group
		NSString *group = [script group];
		MGSOutlineViewNode *groupNode = (MGSOutlineViewNode *)[scriptNode parentNode];
		if (![group isEqualToString:[groupNode name]]) {
			
			// remove child from parent 
			[self removeNode:scriptNode netClient:netClient];
			
			// remove empty group
			if ([[groupNode mutableChildNodes] count] == 0) {
				[self removeNode:groupNode netClient:netClient];
			}
			
			// leave scriptNode defined so that it gets moved to its new group
		} else {
			
			// node processing is done
			scriptNode = nil;
		}
	
	} else {
		// we are saving edits to a new script 
		isNewTask = YES;
		
		// update the client script count
		MGSScriptManager *groupScriptManager = [scriptManager groupWithName:[scriptManager groupNameAll]];
		clientNode.count = [groupScriptManager count];
		
		// create new node and add to the all group 
		scriptNode = [self newScriptTreeNodeWithObject:script keyPrefix:MGSNodeKeyPrefixScriptGroupAll netClient:netClient];
		
		// get all group node from node map
		nodeKey = [self nodeKeyForGroup:[MGSClientScriptManager groupNameAll]];
		MGSOutlineViewNode *allGroupNode = [clientNodeCache objectForKey:nodeKey];
		if (!allGroupNode) {
			allGroupNode = [self newGroupTreeNodeWithObject:[MGSClientScriptManager groupNameAll] netClient:netClient];
			[clientNode insertObject:allGroupNode sortedBy:@"name"];
		}
		NSAssert(allGroupNode.type == MGSNodeTypeGroup, @"invalid all group node type");
		[allGroupNode insertObject:scriptNode sortedBy:@"name"];
		
		// create new node to be added to the script group 
		scriptNode = [self newScriptTreeNodeWithObject:script keyPrefix:MGSNodeKeyPrefixScriptGroup netClient:netClient];
		
	}

	// insert script in correct group
	if (scriptNode) {
		
		// get group, create and add to tree if missing
		nodeKey = [self nodeKeyForGroup:[script group]];
		MGSOutlineViewNode *groupNode = [clientNodeCache objectForKey:nodeKey];
		if (!groupNode) {
			groupNode = [self newGroupTreeNodeWithObject:[script group] netClient:netClient];
			
			[clientNode insertObject:groupNode sortedBy:@"name"];
			
			// we can sort here but it disrupts the outlineview expansion state
			//[clientNode sortNameRecursively:NO];
		}
		NSAssert(groupNode.type == MGSNodeTypeGroup, @"invalid group node type");
		
		// add script node to group
		[[groupNode mutableChildNodes] addObject:scriptNode];
//#warning this may cause loss of expansion state
		[groupNode sortNameRecursively:NO];
		
		// select new task
		if (isNewTask) {			
			[clientTreeController dm_setSelectedObjects:[NSArray arrayWithObject:scriptNode]];
		}
	}
}


/*
 
 - scriptScheduledForDelete:
 
 */
- (void)scriptScheduledForDelete:(NSNotification *)notification
{
	MGSNetClient *netClient = [notification object];
	NSString *scriptUUID = [[notification userInfo] objectForKey:MGSNoteClientScriptUUIDKey];
	MGSClientScriptManager *scriptManager = [netClient.taskController scriptManager];
	MGSScript *script = [scriptManager scriptForUUID:scriptUUID];

	NSAssert(script, @"cannot retrieve script scheduled for deletion using given UUID");
	NSAssert([script scheduleDelete] , @"script is not scheduled for deletion");
	
	// remove the script node from the all group
	NSString *nodeKey = [script keyWithString:MGSNodeKeyPrefixScriptGroupAll];
	[self removeNodeWithKey:nodeKey netClient:netClient];
	
	// remove the script node from the script group
	nodeKey = [script keyWithString:MGSNodeKeyPrefixScriptGroup];
	[self removeNodeWithKey:nodeKey netClient:netClient];

	// get the script group node
	nodeKey = [self nodeKeyForGroup:[script group]];
	MGSOutlineViewNode *groupNode = [self nodeWithKey:nodeKey netClient:netClient];
	
	// if the group is now empty remove it
	if ([[groupNode childNodes] count] == 0) {
		[self removeNodeWithKey:nodeKey netClient:netClient];
	}
}

/*
 
 - willUndoConfigurationChanges:
 
 the configuration changes are about to be undone.
 we have to process this before the undo otherwise the pending
 configuration change states will be lost
 
 */
- (void)willUndoConfigurationChanges:(NSNotification *)notification
{
	MGSNetClient *netClient = [notification object];
	NSArray *scriptsScheduledForDeletion = [[notification userInfo] objectForKey:MGSNoteClientScriptArrayKey];
	
	/*
	 
	 iterate over the scripts scheduled for delete and add to the tree
	 
	 */
	for (MGSScript *script in scriptsScheduledForDeletion) {
		[self updateNodeForNetClient:netClient script:script];
	}
}

#pragma mark -
#pragma mark MGSNetClient notifications
/*
 
 a net client has become available
 
 */
- (void)netClientAvailable:(NSNotification *)notification
{
	MGSNetClient *netClient = [notification object];
	NSAssert([netClient isKindOfClass:[MGSNetClient class]], @"net client is not notification object");
	
	// get the root node to add the client to
	MGSOutlineViewNode *rootNode = [self rootNodeForNetClient:netClient];
		
	// add client node to tree and set properties
	MGSOutlineViewNode *clientNode = [rootNode createChildNodeWithRepresentedObject:netClient];	
	clientNode.image = netClient.hostIcon;
	clientNode.hasCount = YES;
	
	// build client tree
	[self buildClientTree:netClient atNode:clientNode];
	
	// observe the client
	[self addClientObservations:netClient];
	
	// save client ref
	[_netClients addObject:netClient];
	
	// expand client root
	[self expandNode:rootNode];
	
	// expand client
	// we need to delay this for it to work correctly.
	// explanation unknown
	if (rootNode == _homeNode) {
		[self performSelector:@selector(expandNode:) withObject:clientNode afterDelay:0];
		[self performSelector:@selector(selectNode:) withObject:clientNode afterDelay:0];
	}
	
}

/*
 
 - netClientUnavailable:
 
 net client is no longer available
 
 */
- (void)netClientUnavailable:(NSNotification *)notification
{
	MGSNetClient *netClient = [notification object];
	NSAssert([netClient isKindOfClass:[MGSNetClient class]], @"net client is not notification object");
	
	MGSOutlineViewNode *rootNode = [self rootNodeForNetClient:netClient];
	[rootNode removeChildNodeWithRepresentedObject:netClient];
	
	[self removeClientObservations:netClient];
	
	// remove client ref
	[_netClients removeObject:netClient];
	
	// remove client node map
	[outlineNodeCache removeObjectForKey:[netClient serviceName]];
}

/*
 
 - netClientSelected:
 
 net client selected notification
 we sync our selection to the client identified by the notification
 
 */
- (void)netClientSelected:(NSNotification *)notification
{	
	// ignore notifications sent by self
	if ([notification object] == self) {
		return;
	}
	
	NSDictionary *userInfo = [notification userInfo];
	MGSNetClient *netClient = [userInfo objectForKey:MGSNoteNetClientKey];
	
	// get the client node.
	// ignore notification if netClient not supplied or the required client is already selected
	if (!netClient || self.selectedNetClient == netClient) {
		return;
	}
	
	self.selectedNetClient = netClient;

	if ([userInfo objectForKey:MGSNoteClientGroupKey] || [userInfo objectForKey:MGSNoteClientScriptKey]) {
		[self netClientItemSelected:notification];
	}
	
}

/*
 
 - netClientItemSelected:
 
 an item within the current net client has been selected
 
 */
- (void)netClientItemSelected:(NSNotification *)notification
{	
	// ignore notifications sent by self
	if ([notification object] == self) {
		return;
	}
	
	NSDictionary *userInfo = [notification userInfo];
	MGSNetClient *netClient = [userInfo objectForKey:MGSNoteNetClientKey];
	
	// get the client node.
	// ignore notification if netClient not supplied 
	if (!netClient) {
		return;
	}
	
	// we can only process this notification if it is for the selected client
	if (netClient != self.selectedNetClient) {
		[self netClientSelected:notification];
		return;
	}
	
	// get nodes
	MGSOutlineViewNode *rootNode = [self rootNodeForNetClient:netClient];
	MGSOutlineViewNode *clientNode = [rootNode descendantNodeWithRepresentedObject:netClient];
	if (!clientNode) {
		// if cannot find the client then we have likely received this message
		// before our client has been added to the tree
		return;
	}
	
	NSString *nodeKey = nil;
	
	// get the item key
	NSString *itemKey = [userInfo objectForKey:MGSNoteClientItemKey];

	// item is group or script
	if ([itemKey isEqualTo:MGSNoteClientGroupKey] || [itemKey isEqualTo:MGSNoteClientScriptKey]) {

		// default to selecting the client node
		MGSOutlineViewNode *nodeToSelect = clientNode;
		NSTreeNode *clientOutlineItem = [clientTreeController mgs_outlineItemForObject:clientNode];
		

		// if the client is expanded then the group is a candidate for selection
		if ([outlineView isItemExpanded:clientOutlineItem]) {
			
			NSString *groupName = [userInfo objectForKey:MGSNoteClientGroupKey];
			NSAssert(groupName, @"group name is missing");
			
			nodeKey = [self nodeKeyForGroup:groupName];
			MGSOutlineViewNode *groupNode = [self nodeWithKey:nodeKey netClient:netClient];
			
			NSAssert(groupNode, @"group node is nil");
			if (!groupNode) return;
			
			// get the group outline item
			NSTreeNode *groupOutlineItem = [clientTreeController mgs_outlineItemForObject:groupNode];
			NSAssert(groupOutlineItem, @"group outline item is nil");
			
			nodeToSelect = groupNode;
			
			// if the group item is expanded then get the script node
			// and select it
			if ([outlineView isItemExpanded:groupOutlineItem]) {
				
				// look for script
				MGSScript *script = [userInfo objectForKey:MGSNoteClientScriptKey];
				if (script) {
					
					// select script within its group
					nodeKey = [script keyWithString:MGSNodeKeyPrefixScriptGroup];
					MGSOutlineViewNode *scriptNode = [self nodeWithKey:nodeKey netClient:netClient];
					if (scriptNode) {
						nodeToSelect = scriptNode;
					}
					
				} 	
			}
		}
		
		NSAssert(nodeToSelect, @"node to select is nil");
		
		// select the required node
		/*
		 calling NSTreeController setSelectionIndexPaths seems to call
		 NSOutlineView - scrollRowToVisible:
		 
		 so far the only workaround is to conditionally override -scrollRowToVisible.
		 
		 */
		_postNetClientSelectionNotifications = NO;
		outlineView.allowScrollRowVisible = NO;
		[clientTreeController dm_setSelectedObjects:[NSArray arrayWithObject:nodeToSelect]];
		outlineView.allowScrollRowVisible = YES;
		_postNetClientSelectionNotifications = YES;			
		
	}
}
#pragma mark -
#pragma mark NSOutlineView delegate methods

// -------------------------------------------------------------------------------
//	shouldSelectItem:item
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
	#pragma unused(outlineView)
	
	// don't allow root nodes to be selected
	MGSOutlineViewNode *node = [item representedObject];
	if (![node parentNode]) {
		return NO;
	} else {
		
		// if a currently selected client is being configured then do not allow selection
		NSArray *selection = [clientTreeController selectedObjects];
		if ([selection count] == 0) return YES;
		node = [selection objectAtIndex:0]; 
		id object = [node representedObject];
		if (object && [object isKindOfClass:[MGSNetClient class]]) {
			if ([(MGSNetClient *)object applicationWindowContext].runMode == kMGSMotherRunModeConfigure) {
				
				[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteClientClickDuringEdit object:self];
				//return NO;
				return YES;	// always allow
			}
		}
		return YES;	
	}
}

/*
 
 - outlineViewSelectionDidChange:
 
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	#pragma unused(notification)
	
	if ([outlineView selectedRow] == -1) {
		return;
	}
	
	NSArray *selection = [clientTreeController selectedObjects];
	NSAssert([selection count] == 1, @"more than one node selected");
	
	MGSOutlineViewNode *node = [selection objectAtIndex:0]; 

	/*
	 
	 root node selected
	 
	 no action is required
	 
	 this should not happen
	 
	 */
	if (![node parentNode]) {
		return;
	}
	
	[self selectedNodeDidChange:node];
}

/*
 
 - selectedNodeDidChange:
 
 */
- (void)selectedNodeDidChange:(MGSOutlineViewNode *)node
{
	MGSNetClient *netClient = nil;
	NSDictionary *userInfo = nil;
	NSString *noteName = nil;
		
	self.selectedObject = [node representedObject];

	if (!_postNetClientSelectionNotifications) {
		return;
	}
	
	/*
	 
	 client node
	 
	 */
	if ([self.selectedObject isKindOfClass:[MGSNetClient class]]) {
		
		netClient = self.selectedObject;
		
		if (netClient == self.selectedNetClient) {
			
			// post item selected notification indicating that the all group has been selected
			userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[node name], MGSNoteClientNameKey, 
						netClient, MGSNoteNetClientKey, 
						MGSNoteClientGroupKey, MGSNoteClientItemKey,
						@"", MGSNoteClientGroupKey,
						nil];
			
			noteName = MGSNoteClientItemSelected;
		} else {
			self.selectedNetClient = netClient;
			
			// post client selected notification
			userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[node name], MGSNoteClientNameKey, 
						netClient, MGSNoteNetClientKey, 
						nil];
			noteName = MGSNoteClientSelected;
		}
	}
	/*
	 
	 dictionary node
	 
	 this node can represent a range of objects
	 
	 deprecated, or at least, overly complex for current requirements
	 
	 */
	else if ([self.selectedObject isKindOfClass:[NSDictionary class]]) {
			
	/*
	 
	 a typed node
	 
	 */
	} else if (node.type) {
		NSString *groupName = nil;
		MGSOutlineViewNode *parentNode = (MGSOutlineViewNode *)[node parentNode];
		
		// get the net client
		MGSOutlineViewNode *clientNode = [node ancestorNodeWithRepresentedClass:[MGSNetClient class]];
		if (clientNode) {
			netClient = [clientNode representedObject];
		}
		if (!netClient) return;
		
		// determine if we are selecting a new client or an item
		// within the currently selected client
		if (self.selectedNetClient != netClient) {
			self.selectedNetClient = netClient;
			noteName = MGSNoteClientSelected;
		} else {
			noteName = MGSNoteClientItemSelected;
		}
		
		/*
		 
		 group node selected
		 
		 */
		if (node.type == MGSNodeTypeGroup) {
			groupName = node.name;
			userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[clientNode name], MGSNoteClientNameKey, 
						netClient, MGSNoteNetClientKey, 
						MGSNoteClientGroupKey, MGSNoteClientItemKey,
						groupName, MGSNoteClientGroupKey,
						nil];
		}
		
		/*
		 
		 script node selected
		 
		 */
		else if (node.type == MGSNodeTypeScript) {	
			MGSScript *script = [node representedObject];
			NSAssert(script, @"script missing");
			
			// get group name from parent
			if ([parentNode type] == MGSNodeTypeGroup) {

				groupName = [parentNode name];
				
				userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[clientNode name], MGSNoteClientNameKey, 
							netClient, MGSNoteNetClientKey, 
							MGSNoteClientScriptKey, MGSNoteClientItemKey,
							script, MGSNoteClientScriptKey,
							groupName, MGSNoteClientGroupKey,
							nil];
			}			
		}
			
	} else {
		NSAssert(NO, @"invalid selected item");
	}
	
	// post notification if defined
	if (noteName) {
		[[NSNotificationCenter defaultCenter] postNotificationName:noteName object:self userInfo:userInfo];
	}
	
	
}
/*
 
 - outlineView:isGroupItem:
 
 */
-(BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item
{
	#pragma unused(outlineView)
	
	MGSOutlineViewNode *node = [item representedObject];
	if (![node parentNode]) {
		return YES;
	}
	return NO;	
}


/*
 
 - outlineViewItemDidExpand:
 
 */
- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	// item expanded.
	// need to reselect child.
	// note that the controller has retained the selection even though the outline does not display it
	NSTreeNode *groupNode = [[notification userInfo] objectForKey:@"NSObject"];
	
	// is the the group node that contained our selection?
	if ([groupNode isEqualTo:_selectionGroupNode] ) {
		if (nil != _selectionIndexPaths) {
			//[_outlineController setSelectionIndexPaths:nil];
			[clientTreeController setSelectionIndexPaths:_selectionIndexPaths];
			_selectionIndexPaths = nil;
		}
		_selectionGroupNode = nil;
	}
}

/*
 
  - outlineViewItemWillCollapse:
 
 */
- (void)outlineViewItemWillCollapse:(NSNotification *)notification
{
	// when item collapses if child is selected item then child selection is lost.
	// this behaviour means that the selection must be restored when the item is expanded again.

	// get selected nodes
	NSArray *nodes = [clientTreeController selectedNodes];
	if ([nodes count] == 0) return;

	// get node to be collapsed
	NSTreeNode *groupNode = [[notification userInfo] objectForKey:@"NSObject"];
	
	// determine if selected node is child of group node.
	// if so it its selection will have to be restored when the group
	// is re-expanded
	if ([[[nodes objectAtIndex:0] parentNode] isEqualTo:groupNode]) {
		_selectionGroupNode = groupNode;
		_selectionIndexPaths = [clientTreeController selectionIndexPaths];
	} else {
		_selectionGroupNode = nil;
		_selectionIndexPaths = nil;
	}
}
 

#pragma mark -
#pragma mark KVO

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(change)
	#pragma unused(context)
	
	/*
	 
	 net client property changed
	 
	 */
	if ([object isKindOfClass:[MGSNetClient class]]) {
		
		MGSNetClient *netClient = object;

		NSTreeNode *childNode = [self nodeIndex:HOME_NODE_INDEX findChildName:[netClient serviceShortName]];
		if (nil == childNode) {
			childNode = [self nodeIndex:SHARED_NODE_INDEX findChildName:[netClient serviceShortName]];
		}
		if (nil == childNode) return;
		
		MGSOutlineViewNode *node =  [childNode representedObject];	
		BOOL expanded = [outlineView isItemExpanded:childNode];
		
		//
		// host status
		//
		if ([keyPath isEqualToString:MGSNetClientKeyPathHostStatus]) {			
			node.image = netClient.hostIcon;
		}
		
		//
		// run mode or script access change
		// the run mode is changed and then the script access mode changes.
		// 
		else if ([keyPath isEqualToString:MGSNetClientKeyPathRunMode]) {
			// colour coded feedback on runmode state
			NSColor *color = nil;
			NSImage *statusImage = nil;
			
			// as we switch clients we may receive notifications.
			// we only need to act if the value has changed
			id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
			id newValue = [change objectForKey:NSKeyValueChangeNewKey];
			if ([oldValue isEqualTo:newValue]) {
				return;
			}
			
			// run mode
			switch (netClient.applicationWindowContext.runMode) {
					
					// public access
				case kMGSMotherRunModePublic:
					color = [MGSImageAndTextCell countColor];
					break;
					
					// user access
				case kMGSMotherRunModeAuthenticatedUser:
					// here the number of user scripts may be zero at first as may
					// have to retrieve scripts from server
					color = [MGSImageAndTextCell countColorGreen];
					
					// need cast here as sharedManager returns an id an compiler gets confused as user exists for other classes
					statusImage = [[MGSImageManager sharedManager] smallImage:[[NSImage imageNamed:@"UserTemplate"] copy]];
					break; 
					
					// configuration access
				case kMGSMotherRunModeConfigure:
					color = [NSColor colorWithCalibratedRed:0.976f green:0.259f blue:0.259f alpha:1.0f];
					statusImage = [NSImage imageNamed:@"NSActionTemplate"];
					break;
					
				default:
					return;
					
			}
			node.countColor = color;
			node.statusImage = statusImage;
			
		} 
		
		//
		// script access has changed. we have to rebuild the tree.
		//
		else if ([keyPath isEqualToString:MGSNetClientKeyPathScriptAccess]) {
			
			// as we switch clients we may receieve notifications.
			// we only need to act if the value has changed
			id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
			id newValue = [change objectForKey:NSKeyValueChangeNewKey];
			if ([oldValue isEqualTo:newValue]) {
				return;
			}
				
			// if the selected client is changing we will be required to
			// preserve the selection
			id selection = nil;
			if (netClient == self.selectedNetClient) {
				selection = self.selectedObject;
			}
			
			// try and restore the expanded nodes
			
			// rebuild the tree to reflect the script access change
			[self buildClientTree:netClient atNode:node];
			if (expanded) {
				[outlineView expandItem:childNode];
			}
			
			// restore selection
			if (selection) {
				
				// get nodes
				MGSOutlineViewNode *rootNode = [self rootNodeForNetClient:netClient];
				MGSOutlineViewNode *clientNode = [rootNode descendantNodeWithRepresentedObject:netClient];
				MGSOutlineViewNode *selectedNode = nil;
				
				if ([selection isKindOfClass:[MGSScript class]]) {
					selectedNode = [clientNode descendantNodeWithRepresentedObject:selection];
				} 			
				
				// default to selecting the client node
				if (!selectedNode) {
					selectedNode = clientNode;
				}
				[self selectNode:selectedNode];
			}
		}
	} 
	
	/*
	 
	 script property changed
	 
	 */
	else if ([object isKindOfClass:[MGSScript class]]) {
		/*
		 the node does not observe the script directly to avoid coupling the node
		 too tightly to the acual object.
		 
		 also because the script object properties are not updated individually 
		 during an edit (the entire dict representation is replaced).
		 
		 instead we update the node represented object which is actually bound
		 */
		//MGSScript *script = object;
		//MGSNetClient *netClient = (id)context;
		
		if ([keyPath isEqualTo:@"dict"]) {
		
			/*
			MGSOutlineViewNode *rootNode = [self rootNodeForNetClient:netClient];
			MGSOutlineViewNode *clientNode = [rootNode descendantNodeWithRepresentedObject:netClient];
			NSAssert(clientNode, @"net client node is nil");
			
			// update represented object for all script group node
			NSString *scriptKey = [script keyWithString:MGSKeyPrefixScriptGroupAll];
			MGSOutlineViewNode *allScriptNode = [clientNodeDictionary objectForKey:scriptKey];
			[allScriptNode representedObjectDidChange];

			// update represented object for script group node
			scriptKey = [script keyWithString:MGSKeyPrefixScriptGroup];
			MGSOutlineViewNode *groupScriptNode = [clientNodeDictionary objectForKey:scriptKey];
			[groupScriptNode setRepresentedObjectValue:[script name] forKey:@"name"];
			
			// check for change of group
			NSString *group = [script group];
			MGSOutlineViewNode *parentNode = (MGSOutlineViewNode *)[groupScriptNode parentNode];
			if (![group isEqualToString:[parentNode name]]) {
	
				// remove child from parent group
				[[parentNode mutableChildNodes] removeObject:groupScriptNode];
				
				// get the group node
				MGSOutlineViewNode *groupNode = [clientNode childNodeWithName:group];
				if (!groupNode) {
					groupNode = [self newTreeNodeWithObject:group type:MGSNodeTypeGroup options:nil];				
				}
				NSAssert(groupNode.type == MGSNodeTypeGroup, @"invalid node group type found");
				
				// add node
				[[groupNode mutableChildNodes] addObject:groupScriptNode];
				
				// sort the group node
				[groupNode sortNameRecursively:NO];
			}*/
		}
	}
		
}

/*
 
 add client observations
 
 */
- (void)addClientObservations:(MGSNetClient *)netClient
{
	// observe the host status
	[netClient addObserver:self forKeyPath:MGSNetClientKeyPathHostStatus options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld  context:0];
	
	// observe the client run mode
	[netClient addObserver:self forKeyPath:MGSNetClientKeyPathRunMode options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:0];
	
	// observe changes to script access
	[netClient addObserver:self forKeyPath:MGSNetClientKeyPathScriptAccess options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:0];
}

/*
 
 remove client observations
 
 */
- (void)removeClientObservations:(MGSNetClient *)netClient
{
	if (!netClient) {
		MLog(DEBUGLOG, @"net client is nil");
		return;
	}
	
	// remove observers
	@ try {
		[netClient removeObserver:self forKeyPath:MGSNetClientKeyPathHostStatus];
		[netClient removeObserver:self forKeyPath:MGSNetClientKeyPathRunMode];
		[netClient removeObserver:self forKeyPath:MGSNetClientKeyPathScriptAccess];
	} 
	@catch (NSException *e)
	{
		MLog(RELEASELOG, @"%@", [e reason]);
	}
	
}


#pragma mark -
#pragma mark actions

/*
 
 - outlineDoubleAction:
 
 */
- (IBAction)outlineDoubleAction:(id)sender
{
#pragma unused(sender)
	
	NSInteger row = [outlineView clickedRow];
	if (row == -1) {
		row = [outlineView selectedRow];	
	}
	if (row == -1) return;
	
	NSTreeNode *node = [outlineView itemAtRow:row];
	
	// expandable item
	if ([outlineView isExpandable:node]) {
		if ([outlineView isItemExpanded:node]) {
			[outlineView collapseItem:node collapseChildren:NO];
		} else {
			[outlineView expandItem:node expandChildren:NO];
		}
		
		return;
	} 
	
	MGSOutlineViewNode *myNode = [node representedObject];
	MGSOutlineViewNode *clientNode = [myNode ancestorNodeWithRepresentedClass:[MGSNetClient class]];
	MGSNetClient *netClient = [clientNode representedObject];
	NSAssert(netClient, @"net client is nil");
	switch ([netClient applicationWindowContext].runMode) {
		case kMGSMotherRunModeConfigure:
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteEditSelectedTask object:nil userInfo:nil];
			break;
			
		case kMGSMotherRunModePublic:
		case kMGSMotherRunModeAuthenticatedUser:
			break;
			
		default:
			NSAssert(NO, @"invalid run mode");
			break;
	}
	
	
}

@end
