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
#import "MGSTaskSpecifierManager.h"
#import "NSIndexPath+Mugginsoft.h"
#import "NSString_Mugginsoft.h"

#include <sys/time.h>

#define HOME_NODE_INDEX 0
#define SHARED_NODE_INDEX 1

NSString * const MGSNodeKeyPrefixScriptGroupAll = @"$SCRIPT-ALL$";
NSString * const MGSNodeKeyPrefixScriptGroup = @"$SCRIPT-GRP$";
NSString * const MGSNodeKeyGroupPrefix = @"$GROUP$";
NSString * const MGSGroupPathSeparator = @"/";

NSString *MGSNodeTypeScript = @"script";
NSString *MGSNodeTypeGroup = @"group";

char MGSScriptDictContext;

// class extension
@interface MGSSidebarViewController()

- (void)dispatchTaskSpecAtRowIndex:(NSInteger)rowIndex displayType:(MGSTaskDisplayType)taskDisplayType;
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
- (MGSOutlineViewNode *)selectedObjectGroupNode;
- (void)updateSharedCount;
- (void)configureAnimationTimer;
- (void)animate;
- (MGSOutlineViewNode *)nodeForNetClient:(MGSNetClient *)netClient;
- (MGSOutlineViewNode *)_newGroupTreeNodeWithObject:(id)object netClient:(MGSNetClient *)netClient;

@property MGSNetClient *selectedNetClient;
@property id selectedObject;
@property MGSOutlineViewNode *selectedObjectNode;
@end

@implementation MGSSidebarViewController

@synthesize clientTree;
@synthesize selectedNetClient, selectedObject, selectedObjectNode;

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
#pragma mark Animation

/*
 
 - configureAnimationTimer
 
 */
- (void)configureAnimationTimer
{
    
    _netClientsAnimated = [NSMutableArray arrayWithCapacity:[_netClients count]];
    
    // configure client animation.
    for (MGSNetClient *netClient in _netClients) {
        if (netClient.activityFlags & MGSClientActivityUpdatingTaskList) {
            [_netClientsAnimated addObject:netClient];
        }
    }
    
    // if we need animation then start the timer
    if ([_netClientsAnimated count] > 0) {
        if (!cellAnimationTimer) {
            NSTimeInterval interval = 1.0f/[MGSImageAndTextCell updatingImagesCount];
            cellAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(animate) userInfo:nil repeats:YES];
            [self animate];
        }
    } else {
        [cellAnimationTimer invalidate];
        cellAnimationTimer = nil;
    }
}

/*
 
 - animate
 
 */
- (void)animate
{
    for (MGSNetClient *netClient in _netClientsAnimated) {
        
        MGSOutlineViewNode *clientNode = [self nodeForNetClient:netClient];
        
        if (clientNode.updatingImageIndex < [MGSImageAndTextCell updatingImagesCount]) {
            clientNode.updatingImageIndex +=1;
        } else {
            clientNode.updatingImageIndex = 0;
        }
    }
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

/*
 
 - selectedObjectGroupNode
 
 */
- (MGSOutlineViewNode *)selectedObjectGroupNode
{
	MGSOutlineViewNode *selectedGroupNode = nil;
	if (self.selectedObjectNode) {
		if (self.selectedObjectNode.type == MGSNodeTypeScript) {
			selectedGroupNode = (MGSOutlineViewNode *)[self.selectedObjectNode parentNode];
		} else if (self.selectedObjectNode.type == MGSNodeTypeGroup) {
			selectedGroupNode = self.selectedObjectNode;
		}		
	}
	
	return selectedGroupNode;
}

#pragma mark -
#pragma mark Tree model

/*
 
 - buildClientTree:atNode:
 
 */
- (void)buildClientTree:(MGSNetClient *)netClient atNode:(MGSOutlineViewNode *)clientNode
{
	BOOL manipulateController = YES;
	BOOL useReplacementMethod = YES;
	NSTreeNode *clientOutlineItem = [clientTreeController mgs_outlineItemForObject:clientNode];		
	NSIndexPath *clientIndexPath = [clientOutlineItem indexPath];
	
	/*
	 
	 we want to remove child nodes as efficiently as possible.
	 
	 we can do this either by manipulating the model or the controller.
	 
	 */
	if (manipulateController) {
		
		if (useReplacementMethod) {
			
			/*
			 
			  temporarily remove the node while we update it.
			 
			  this generates the fewest notifications
			 
			 */
			[clientTreeController removeObjectAtArrangedObjectIndexPath:clientIndexPath];
			[[clientNode mutableChildNodes] setArray:nil];
		} else {
			
			/*
			 
			 manipulate the controller directly
			 
			 */
			NSInteger i = [[clientOutlineItem mutableChildNodes] count] - 1;
			NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:i+1];
			
			for (MGSOutlineViewNode *childNode in [[clientOutlineItem mutableChildNodes] copy]) {
				[indexPaths addObject:[childNode indexPath]];
			}
			
			// this raises lots of notifications too as it simply iterates
			// over the paths individually
			[clientTreeController removeObjectsAtArrangedObjectIndexPaths:indexPaths];
		}
		
	} else {
		// mutating the model directly requires that the controller rely on KVO
		// observing of the content object.
		// for batch operations like below this can lead to lots of selection updating.
		//[[clientNode mutableChildNodes] setArray:[NSMutableArray arrayWithCapacity:1]];
		[[clientNode mutableChildNodes] setArray:nil];
		
		// raises losts of notifications
		//[[clientNode mutableChildNodes] removeAllObjects];
	}
	
	// get the script manager for the client
	MGSClientScriptManager *scriptManager = [netClient.taskController scriptManager];		
	NSAssert(scriptManager, @"script controller is nil");
	
	clientNode.count = 0;
	
	// create a cache to hold node references keyed by the netclient service name.
	// we replace any existing object.
	/*
	 
	 the cache provides a convenient way to lookup any node based on its key.
	 the key will normally be derived either from the node name or the represented object.
	 
	 */
	NSMutableDictionary *clientNodeCache = [NSMutableDictionary dictionaryWithCapacity:300];
	[outlineNodeCache setObject:clientNodeCache forKey:[netClient key]];
    
    // add the client node itself to the cache as well as all the children
	[clientNodeCache setObject:clientNode forKey:[netClient key]]; 
    
	NSMutableArray *clientChildNodes = [NSMutableArray arrayWithCapacity:100];
	
	// build task group tree
	NSArray *groupNames = [scriptManager groupNames];
	NSString *scriptKeyPrefix = nil;
	for (NSString *groupName in groupNames) {

        // we want clean group names
        MGSScriptManager *groupScriptManager = [scriptManager groupWithName:groupName];
        
        NSRange range = [groupName rangeOfString:@"Funny"];
        if (range.length != 0) {
            NSLog(@"Funny found");
        }
        [self valueForKey:nil];
        
		// make a group node
        // this will return the top level node if the group name contains path separators
		MGSOutlineViewNode *groupTopNode = [self newGroupTreeNodeWithObject:groupName netClient:netClient];
		
		// get script handler for group name
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
		
		// add the group top node
        if (![clientChildNodes containsObject:groupTopNode]) {
            [clientChildNodes addObject:groupTopNode];
		}
        
        // get the node to attach the tasks to
        MGSOutlineViewNode *groupNode = [self nodeWithKey:[self nodeKeyForGroup:groupName] netClient:netClient];
        if (!groupNode) {
            groupNode = groupTopNode;
        }
        
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

	
	if (manipulateController) {
		
		if (useReplacementMethod) {
			[[clientNode mutableChildNodes] addObjectsFromArray:clientChildNodes];
			[clientTreeController insertObject:clientNode atArrangedObjectIndexPath:clientIndexPath];
		} else {
			
			/* this is defective - the child nodes cannot find their client parent */
			NSAssert(NO, @"defective code path");
			NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[clientChildNodes count]];
			NSInteger idx = 0;
			for (MGSOutlineViewNode *childNode in [clientChildNodes copy]) {
				[indexPaths addObject:[clientIndexPath indexPathByAddingIndex:idx++]];
			}
			[clientTreeController insertObjects:clientChildNodes atArrangedObjectIndexPaths:indexPaths];
		}
		
	} else {
		
		//
		[[clientNode mutableChildNodes] addObjectsFromArray:clientChildNodes];
		
		// this causes the outline view selection to get updated as each item is added!
		//[[clientNode mutableChildNodes] setArray:clientChildNodes];
	}
	
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
	
    NSString *groupName = object;
    
    MGSOutlineViewNode *groupNode = nil;
    
#undef MGS_GROUP_PATH_SUPPORTED

    // process / in group paths
//
// funny
// funny / jokes
// funny / stories
// funny / stories / animals
#ifdef MGS_GROUP_PATH_SUPPORTED
    
    // split group name into path components
    NSArray *groupComponents = [groupName mgs_minimalComponentsSeparatedByString:MGSGroupPathSeparator];
    
    // group has a path
    if ([groupComponents count] > 1) {
        
        // make a group node
        MGSOutlineViewNode *parentNode  = nil;
        NSString *groupNodeKey = nil;
        
        for (NSString *groupComponent in groupComponents) {
            
            // build the group node key back up from the components
            if (!groupNodeKey) {
                groupNodeKey = groupComponent;
            } else {
                groupNodeKey = [NSString stringWithFormat:@"%@ %@ %@", groupNodeKey, MGSGroupPathSeparator, groupComponent];
            }
            
            MGSOutlineViewNode *node = nil;
            
            // get existing group node
            node = [self nodeWithKey:[self nodeKeyForGroup:groupNodeKey] netClient:netClient];
            
            // make a group node if none exists
            if (!node) {
                node = [self _newGroupTreeNodeWithObject:groupNodeKey netClient:netClient];
                
                // use the component as the label not the key
                node.label = groupComponent;
                
                if (parentNode) {
                    [[parentNode mutableChildNodes] addObject:node];
                }

            }
            
            // we need to keep track of the top level node
            if (!groupNode) {
                groupNode = node;
            }
            
            parentNode = node;
        }
    } 
#endif

    if (!groupNode) {
        groupNode = [self _newGroupTreeNodeWithObject:groupName netClient:netClient];
    }
    
	
	return groupNode;
}

/*
 
 - _newGroupTreeNodeWithObject:netClient:
 
 */
- (MGSOutlineViewNode *)_newGroupTreeNodeWithObject:(id)object netClient:(MGSNetClient *)netClient
{
 	NSAssert([object isKindOfClass:[NSString class]], @"bad object class");
	
    NSString *groupName = object;

    MGSOutlineViewNode *groupNode = [self newTreeNodeWithObject:groupName type:MGSNodeTypeGroup options:nil];
    
    // get script handler for group name
    // get the script manager for the client
	MGSClientScriptManager *scriptManager = [netClient.taskController scriptManager];
	NSAssert(scriptManager, @"script controller is nil");
	MGSScriptManager *groupScriptManager = [scriptManager groupWithName:groupName];
	
	// get image for the group
	groupNode.image = [[groupScriptManager displayObject] image];
	groupNode.hasCount = YES;
	groupNode.countChildNodes = YES;
    
	// add to the node map
	NSString *nodeKey = [self nodeKeyForGroup:groupName];
	[self cacheNode:groupNode withKey:nodeKey netClient:netClient];
	
	return groupNode;

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
#pragma mark Menu handling
/*
 
 validate menu item
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    SEL action = [anItem action];
    NSInteger clickedRow = [outlineView clickedRow];
	if (clickedRow == -1) {
		return NO;
	}

	// get node
	NSTreeNode *node = [outlineView itemAtRow:clickedRow];
	MGSOutlineViewNode *myNode = [node representedObject];
	
	// open task in new window
    if (action == @selector(openTaskInNewWindow:)) {
		
		return myNode.type == MGSNodeTypeScript ? YES : NO;
	}
	
	// open task in new tab
    if (action == @selector(openTaskInNewTab:)) {
		
		return myNode.type == MGSNodeTypeScript ? YES : NO;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Node actions
/*
 
 open task in new tab
 
 */
- (IBAction)openTaskInNewTab:(id)sender
{
#pragma unused(sender)
	
	[self dispatchTaskSpecAtRowIndex:[outlineView clickedRow] displayType:MGSTaskDisplayInNewTab];	
}
/*
 
 open task in new window
 
 */
- (IBAction)openTaskInNewWindow:(id)sender
{
#pragma unused(sender)
	[self dispatchTaskSpecAtRowIndex:[outlineView clickedRow] displayType:MGSTaskDisplayInNewWindow];	
}

/*
 
 - dispatchTaskSpecAtRowIndex:displayType:
 
 */
- (void)dispatchTaskSpecAtRowIndex:(NSInteger)rowIndex displayType:(MGSTaskDisplayType)taskDisplayType
{
	if (rowIndex == -1) {
		return;
	}
	
	// get node
	NSTreeNode *node = [outlineView itemAtRow:rowIndex];
	MGSOutlineViewNode *myNode = [node representedObject];
	if (myNode.type != MGSNodeTypeScript) {
		return;
	}
	
	// get selected script
	MGSScript *script = [myNode representedObject];
	NSAssert(script && [script isKindOfClass:[MGSScript class]], @"script missing");
	
	// get script net client
	MGSNetClient *netClient = nil;
	MGSOutlineViewNode *clientNode = [myNode ancestorNodeWithRepresentedClass:[MGSNetClient class]];
	if (clientNode) {
		netClient = [clientNode representedObject];
	}
	if (!netClient) {
		return;
	}
	
	// create new task spec
	MGSTaskSpecifier *taskSpec = [[MGSTaskSpecifierManager sharedController] 
								  newTaskSpecForNetClient:netClient 
													script:script];	
	taskSpec.displayType = taskDisplayType;
	
	// display action accordingly
	switch (taskSpec.displayType) {
			
			// display task in new tab
		case MGSTaskDisplayInNewTab:
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteOpenTaskInNewTab object:taskSpec];
			break;
			
			// display task in new window
		case MGSTaskDisplayInNewWindow:
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteOpenTaskInWindow object:taskSpec];
			return;
			break;
			
			// try and find matching tab for task?
		default:
			break;
	}
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
	return [outlineNodeCache objectForKey:[netClient key]];
}

/*
 
 - nodeForNetClient:
 
 */
- (MGSOutlineViewNode *)nodeForNetClient:(MGSNetClient *)netClient
{
    MGSOutlineViewNode *clientNode = [self nodeWithKey:netClient.key netClient:netClient];
    
    // this is the non cached approach
    if (!clientNode) {
        
#ifdef MGS_DEBUG
        NSLog(@"Sidebar outline net client node cache miss");
#endif
        MGSOutlineViewNode *rootNode = [self rootNodeForNetClient:netClient];

        // very inefficient as it iterates over every leaf.
        clientNode = [rootNode descendantNodeWithRepresentedObject:netClient];
    }
    
    return clientNode;
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
	/*
	 
	 determine if current selection is in all group or named group
	 
	 */
	MGSOutlineViewNode *selectedGroupNode = self.selectedObjectGroupNode;
	BOOL currentSelectionInAllGroup= [selectedGroupNode.name isEqualToString:[MGSClientScriptManager groupNameAll]];
	
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
	MGSOutlineViewNode *nodeToBeSelected = nil;
	MGSOutlineViewNode *clientNode = [self nodeForNetClient:netClient];
	if (!clientNode) {
        MLogInfo(@"net client node is nil");
        return;
    }
	
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
		
		if (currentSelectionInAllGroup) {
			nodeToBeSelected = scriptNode;
		}
		
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
			if (!nodeToBeSelected) {
				nodeToBeSelected = scriptNode;
			}
			[clientTreeController dm_setSelectedObjects:[NSArray arrayWithObject:nodeToBeSelected]];
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
	
    // check that this client is not already available
    if ([_netClients containsObject:netClient]) {
        
        MLogDebug(@"net client already available. reload will occur.");
        
        // remove first to force reload
        [self netClientUnavailable:notification];
    }
    
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
		if ([[clientNode childNodes] count] > 0) {
			[self performSelector:@selector(selectNode:) withObject:[[clientNode childNodes] objectAtIndex:0] afterDelay:0];
		} else {
			[self performSelector:@selector(selectNode:) withObject:clientNode afterDelay:0];
		}
	}
    
    [self updateSharedCount];
	
}

/*
 
 - updateSharedCount
 
 */
- (void)updateSharedCount
{
    NSInteger sharedCount = _netClients.count - 1;
    if (sharedCount < 0) sharedCount = 0;
    _sharedNode.count = sharedCount;
    _sharedNode.countColor = [MGSImageAndTextCell countColorMidGrey];
    if (sharedCount == 0) {
        _sharedNode.hasCount = NO;
    } else {
        _sharedNode.hasCount = YES;
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

    if ([_netClients containsObject:netClient]) {
    
        MGSOutlineViewNode *rootNode = [self rootNodeForNetClient:netClient];
        [rootNode removeChildNodeWithRepresentedObject:netClient];
        
        [self removeClientObservations:netClient];

        // remove client ref
        [_netClients removeObject:netClient];
        
        // remove client node map
        [outlineNodeCache removeObjectForKey:[netClient key]];
    }
    
    [self configureAnimationTimer];
    
    [self updateSharedCount];
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
	
	// get client node
	MGSOutlineViewNode *clientNode = [self nodeForNetClient:netClient];
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
			NSString *groupKeyPrefix = MGSNodeKeyPrefixScriptGroup;
			/*
			 
			 even though we know the group we may want to persist with selecting the script
			 in the all group
			 
			 */
			MGSOutlineViewNode *selectedGroupNode = self.selectedObjectGroupNode;
			BOOL currentSelectionInAllGroup= [selectedGroupNode.name isEqualToString:[MGSClientScriptManager groupNameAll]];
			if (currentSelectionInAllGroup) {
				groupName = [MGSClientScriptManager groupNameAll];
				groupKeyPrefix = MGSNodeKeyPrefixScriptGroupAll;
			}
			
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
					nodeKey = [script keyWithString:groupKeyPrefix];
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
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
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
	
	MGSOutlineViewNode *node = 0;
	NSArray *selection = [clientTreeController selectedObjects];
	if ([selection count] > 0) {
	
		node = [selection objectAtIndex:0]; 

		/*
		 
		 root node selected
		 
		 no action is required
		 
		 this should not happen
		 
		 */
		if (![node parentNode]) {
			return;
		}
	}
	
	[self selectedNodeDidChange:node];
}

/*
 
 */
- (void)setSelectedObjectNode:(MGSOutlineViewNode *)node
{
	selectedObjectNode = node;
	self.selectedObject = [node representedObject];
}
/*
 
 - selectedNodeDidChange:
 
 */
- (void)selectedNodeDidChange:(MGSOutlineViewNode *)node
{
	MGSNetClient *netClient = nil;
	NSDictionary *userInfo = nil;
	NSString *noteName = nil;
		
	self.selectedObjectNode = node;
	
	if (!_postNetClientSelectionNotifications) {
		return;
	}
	
	if (!self.selectedObjectNode) {
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
				MGSOutlineViewNode *clientNode = [self nodeForNetClient:netClient];
				MGSOutlineViewNode *selectedNode = nil;
				
				if ([selection isKindOfClass:[MGSScript class]]) {
                    
                    // TODO: use the cache ? perhaps the ALL group causes issues
					selectedNode = [clientNode descendantNodeWithRepresentedObject:selection];
				} 			
				
				// default to selecting the client node
				if (!selectedNode) {
					selectedNode = clientNode;
				}
				[self selectNode:selectedNode];
			}
		}
        //
		// updating
		//
		else if ([keyPath isEqualToString:MGSNetClientKeyPathActivityFlags]) {
        
            if (netClient.activityFlags & MGSClientActivityUpdatingTaskList) {
                node.updating = YES;
            } else {
                node.updating = NO;
            }
            
            [self configureAnimationTimer];
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
    
    // observe changes to updating
	[netClient addObserver:self forKeyPath:MGSNetClientKeyPathActivityFlags options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:0];

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
        [netClient removeObserver:self forKeyPath:MGSNetClientKeyPathActivityFlags];
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
	if (!netClient) {
        MLogInfo(@"MGSNetClient is nil");
        return;
    }
    
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
