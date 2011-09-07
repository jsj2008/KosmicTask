//
//  MGSResourceBrowserViewController.m
//  KosmicTask
//
//  Created by Jonathan on 29/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSResourceBrowserViewController.h"
#import "NSSplitView_Mugginsoft.h"
#import <MGSFragaria/MGSFragaria.h>
#import "MGSLanguagePluginController.h"
#import "NSWindow_Mugginsoft.h"
#import "MGSImageManager.h"
#import "MGSLanguageDocumentResource.h"
#import "MGSLanguagePropertiesResource.h"
#import "NSTreeController-DMExtensions.h"
#import "MGSOriginTransformer.h"
#import "MGSResourceItem.h"
#import "NSOutlineView_Mugginsoft.h"
#import "MGSSettingsOutlineViewController.h"
#import "MGSResourceDocumentViewController.h"

// resource tab indexes
#define MGS_DOCUMENT_TAB_INDEX 0
#define MGS_TEMPLATE_TAB_INDEX 1
#define MGS_SETTINGS_TAB_INDEX 2

// resource child tab indexes
#define MGS_EDITOR_CHILD_TAB_INDEX 0
#define MGS_SETTINGS_CHILD_TAB_INDEX 1
#define MGS_DOCUMENT_CHILD_TAB_INDEX 2


// class extension
@interface MGSResourceBrowserViewController()
- (void)applicationWillTerminate:(NSNotification *)notification;
- (void)processOutlineResourceNode:(MGSResourceBrowserNode *)node options:(NSSet *)options;
- (MGSResourceBrowserNode *)selectedResourceTreeNode;
- (void)resourceNodeSelected:(MGSResourceBrowserNode *)selectedNode;
- (MGSResourceBrowserNode *)selectedResourceArrayNode;
- (void)commitEditing;
- (void)resourcesManagerWillChange:(NSNotification *)note;
- (void)resourcesManagerDidChange:(NSNotification *)note;
- (void)viewEditability:(NSView *)view forResource:(id)resource;
- (void)tableView:(NSTableView *)tableView menuNeedsUpdate:(NSMenu *)menu;
- (MGSResourceItem *)clickedResource:(id)sender;
- (id)clickedObject:(id)sender;
- (void)duplicateResource:(id)sender;
- (void)updateDefaultLanguagePlugin;
- (void)scrollVisible:(id)sender;
- (void)restoreViewFramesUsingDefaults:(NSDictionary *)viewDefaults;
- (void)saveViewFramesUsingDefaults:(NSDictionary *)viewDefaults;
- (IBAction)outlineDoubleAction:(id)sender;
- (void)buildSettingsTree;
- (NSInteger)_mgs_outlineView:(NSOutlineView *)outlineView drawStyleForRow:(int)row;
- (void)setLanguagePropertyManager:(MGSLanguagePropertyManager *)manager;
@property BOOL requiredResourceSelected;
@end

const char MGSResourceSelectedObjectsContext;
const char MGSResourceTreeSelectedObjectsContext;
const char MGSSettingsTreeSelectedObjectsContext;
const char MGSSettingsTreeEditedContext;
const char MGSDocumentEditedContext;
const char MGSDocumentModeContext;

@implementation MGSResourceBrowserViewController

@synthesize languagePlugins, languagePlugin, selectedResource, resourceName , documentEdited, 
 resourceTree, resourceArray, resourceTabIndex, requiredResourceSelected, requiredResourceClass, 
resourceChildTabIndex, infoResource, newResourceClass, addResourceMenuTitle, deleteResourceMenuTitle,
selectedResourcesManager, title, editable, resourceEditable, viewFrameDefaults, defaultScriptType,
requiredResourceDoubleClicked, selectedLanguageProperty;

@synthesize tableCanDeleteResource, tableCanDuplicateResource, tableCanAddResource, tableCanDefaultResource;
@synthesize outlineCanAddResource, outlineCanDeleteResource, outlineCanDuplicateResource, outlineCanDefaultResource;

/*
 
 init
 
 */
- (id)init
{
	self = [super initWithNibName:@"ResourceBrowserView" bundle:nil];
	if (self) {
		requiredResourceSelected = NO;
		
		tableCanDeleteResource = NO;
		tableCanAddResource = NO;
		tableCanDuplicateResource = NO;
		tableCanDefaultResource = NO;
		
		outlineCanAddResource = NO;
		outlineCanDeleteResource = NO;
		outlineCanDuplicateResource = NO;
		outlineCanDefaultResource = NO;
		editable = NO;
		resourceEditable = NO;
	}
	return self;
}

#pragma mark -
#pragma mark Nib
/*
 
 - awakeFromNib
 
 */
- (void)awakeFromNib
{
	// load settings outline view controller
	settingsOutlineViewController = [[MGSSettingsOutlineViewController alloc] init];
	settingsOutlineViewController.delegate = self;
	settingsView = [settingsOutlineViewController view];	// trigger load
	
	// create Fragaria instance
	fragaria = [[MGSFragaria alloc] init];
	
	//
	// define initial object configuration
	//
	// see MGSFragaria.h for details
	//
	[fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOIsSyntaxColoured];
	[fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOShowLineNumberGutter];
	[fragaria setObject:self forKey:MGSFODelegate];
	
	// embed in our host view
	[fragaria embedInView:editorHostView];
	editorTextView = [fragaria objectForKey:ro_MGSFOTextView];
	
	[[MGSLanguagePluginController sharedController] resolvePluginResources];
	 
	// KVO
	[resourceArrayController addObserver:self forKeyPath:@"selectedObjects" options:0 context:(void *)&MGSResourceSelectedObjectsContext];
	[resourceTreeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:(void *)&MGSResourceTreeSelectedObjectsContext];
	[settingsOutlineViewController addObserver:self forKeyPath:@"selectedLanguageProperty" options:0 context:(void *)&MGSSettingsTreeSelectedObjectsContext];
	[settingsOutlineViewController addObserver:self forKeyPath:@"documentEdited" options:0 context:(void *)&MGSSettingsTreeEditedContext];
	[resourceDocumentViewController addObserver:self forKeyPath:@"documentEdited" options:0 context:(void *)&MGSDocumentEditedContext];
	[resourceDocumentViewController addObserver:self forKeyPath:@"mode" options:NSKeyValueObservingOptionPrior context:(void *)&MGSDocumentModeContext];

	// notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourcesManagerWillChange:) name:MGSResourcesManagerWillChange object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourcesManagerDidChange:) name:MGSResourcesManagerDidChange object:nil];
	
	// language plugins
	self.languagePlugins = [[MGSLanguagePluginController sharedController] instances];

	/*
	 
	 bindings
	 
	 these were initially created in IB but then a refactor caused them to break
	 
	 note some text fields still bound in IB
	 
	 */
	
	// controllers
	[resourceController bind:NSContentBinding toObject:self withKeyPath:@"selectedResource" options:nil];
	[resourceArrayController bind:NSContentBinding toObject:self withKeyPath:@"resourceArray" options:nil];
	[resourceTreeController bind:NSContentBinding toObject:self withKeyPath:@"resourceTree" options:nil];
	
	// resource outline view
	[resourceOutlineView bind:NSContentBinding toObject:resourceTreeController withKeyPath:@"arrangedObjects" options:nil];
	[resourceOutlineView bind:NSSelectionIndexPathsBinding toObject:resourceTreeController withKeyPath:@"selectionIndexPaths" options:nil];
	[[resourceOutlineView tableColumnWithIdentifier:@"outline"] bind:NSValueBinding toObject:resourceTreeController withKeyPath:@"arrangedObjects.bindingObject" options:nil];	
	[resourceOutlineView setDoubleAction:@selector(outlineDoubleAction:)];
	[resourceOutlineView setTarget:self];
	
	// resource tab view
	[resourceTabView bind:NSSelectedIndexBinding toObject:self withKeyPath:@"resourceTabIndex" options:nil];
	
	// resource table view
	[resourceTableView bind:NSContentBinding toObject:resourceArrayController withKeyPath:@"arrangedObjects" options:nil];
	[resourceTableView bind:NSSelectionIndexesBinding toObject:resourceArrayController withKeyPath:@"selectionIndexes" options:nil];
	[resourceTableView bind:NSSortDescriptorsBinding toObject:resourceArrayController withKeyPath:@"sortDescriptors" options:nil];
	[[resourceTableView tableColumnWithIdentifier:@"resource"] bind:NSValueBinding toObject:resourceArrayController withKeyPath:@"arrangedObjects.bindingObject" options:nil];
	[[resourceTableView tableColumnWithIdentifier:@"description"] bind:NSValueBinding toObject:resourceArrayController withKeyPath:@"arrangedObjects.description" options:nil];
	[[resourceTableView tableColumnWithIdentifier:@"script"] bind:NSValueBinding toObject:resourceArrayController withKeyPath:@"arrangedObjects.subrootDescription" options:nil];
	
	[[resourceTableView tableColumnWithIdentifier:@"origin"] bind:NSValueBinding toObject:resourceArrayController withKeyPath:@"arrangedObjects.representedObject.origin" options:[NSDictionary dictionaryWithObjectsAndKeys:[MGSOriginTransformer new], NSValueTransformerBindingOption, nil]];
	[[[resourceTableView tableColumnWithIdentifier:@"origin"] headerCell] setImage:[NSImage imageNamed:@"GearSmall"]];
	
	// fragaria
	[editorTextView bind:NSEditableBinding toObject:self withKeyPath:@"editable" options:nil];
	[editorTextView bind:[NSEditableBinding stringByAppendingString:@"2"] toObject:self withKeyPath:@"resourceEditable" options:nil];
	
	initialTableItemFrame = [tableItemCount frame];
}

#pragma mark -
#pragma mark actions

/*
 
 - outlineDoubleAction:
 
 */
- (IBAction)outlineDoubleAction:(id)sender
{
	#pragma unused(sender)
	
	NSInteger row = [resourceOutlineView clickedRow];
	if (row == -1) {
		row = [resourceOutlineView selectedRow];	
	}
	if (row == -1) return;
	
	NSTreeNode *outlineNode = [resourceOutlineView itemAtRow:row];
	
	// expandable item
	if ([resourceOutlineView isExpandable:outlineNode]) {
		if ([resourceOutlineView isItemExpanded:outlineNode]) {
			[resourceOutlineView collapseItem:outlineNode collapseChildren:NO];
		} else {
			[resourceOutlineView expandItem:outlineNode expandChildren:NO];
		}
		
	// if we have selected a leaf node and it is of the required type
	// then flag double click
	} else if (self.requiredResourceSelected) {
		self.requiredResourceDoubleClicked = YES;
	}
}

#pragma mark -
#pragma mark Tree handling

/*
 
 - buildResourceTree
 
 */
- (void)buildResourceTree
{
	// array holds tree roots
	NSMutableArray *tree = [NSMutableArray arrayWithCapacity:10];

	// language root node
	languageRootNode = [MGSResourceBrowserNode treeNodeWithRepresentedObject:@"LANGUAGES"];
	languageRootNode.counter = [self.languagePlugins count];
	languageRootNode.hasCount = YES;
	languageRootNode.image = [[[MGSImageManager sharedManager] script] copy];
	[tree addObject:languageRootNode];
	
	MGSResourceBrowserNode *selectedNode = nil;
	
	// language child nodes
	for (MGSLanguagePlugin *plugin in [NSMutableArray arrayWithArray:self.languagePlugins]) {
		
		// if cannot modify the resources then we bind to a copy
		MGSResourceBrowserNode *languageNode = [plugin resourceTreeAsCopy:!self.editable];
		[[languageRootNode mutableChildNodes] addObject:languageNode];

		if (!selectedNode) {
			selectedNode = languageNode;
		}
	}
	
	// assign the tree
	self.resourceTree = tree;
	
	// select and expand initial node
	if (selectedNode) {
		[self processOutlineResourceNode:selectedNode options:[NSSet setWithObjects:@"select", nil]];
	}
	
	[self updateDefaultLanguagePlugin];
}

/*
 
 - buildSettingsTree
 
 */
- (void)buildSettingsTree
{
	// we require a language plugin
	if (!self.languagePlugin) {
clearTree:
		//self.settingsTree = nil;
		return;
	}
	

	MGSLanguagePropertyManager *languagePropertyManager = [self.languagePlugin languagePropertyManager];
	
	//
	// template resource
	//
	if ([self.selectedResource isKindOfClass:[MGSLanguageTemplateResource class]]) {
		
		// copy the language manager and 
		// note that we create a copy of the manager
		languagePropertyManager = [languagePropertyManager copy];
		 
		// reinitialise the properties so that the properties than can be reset in the
		// original object cannot be reset in the copy.
		// likely to be unnecessary giv changes in MGSLangaugeProperty -copyWithZone:
		[languagePropertyManager reinitialiseProperties];
		
		// update with the selected template dictionary resource.
		[languagePropertyManager updatePropertiesFromDictionary:self.selectedResource.dictionaryResource];		
		
	//
	// properties resource
	//
	} else if ([self.selectedResource isKindOfClass:[MGSLanguagePropertiesResource class]]) {
		
		// we want to update the property resource so we operate on the original
		// languagePropertyManager object
	} else {
		goto clearTree;
	}
	
	[self setLanguagePropertyManager:languagePropertyManager];
}

/*
 
 - processOutlineResourceNode:options:
 
 */
- (void)processOutlineResourceNode:(MGSResourceBrowserNode *)node options:(NSSet *)options
{
	[self commitEditing];
	
	NSAssert([node isKindOfClass:[MGSResourceBrowserNode class]], @"bad node class");
	[resourceTreeController mgs_processOutlineView:resourceOutlineView node:node options:options];
	
/*	
	// NSTreeController.h states that arrangedObjects is a root proxy object that responds to -childNodes
	id proxyTree = [resourceTreeController arrangedObjects];
	NSAssert([proxyTree respondsToSelector:@selector(childNodes)], @"NSTreeController arranged objects proxy does not respond to -childNodes");
	NSAssert([proxyTree respondsToSelector:@selector(descendantNodeAtIndexPath:)], @"NSTreeController arranged objects proxy does not respond to -descendantNodeAtIndexPath:");

	// get path to node
	NSIndexPath *indexPath = [resourceTreeController dm_indexPathToObject:node];
	id outlineItem = [proxyTree descendantNodeAtIndexPath:indexPath]; // this will be an NSTreeNode
	if (!outlineItem) {
		MLogInfo(@"outline item not found");
		return;
	}
		
	// select item
	if ([options containsObject:@"select"]) {
		[resourceTreeController dm_setSelectedObjects:[NSArray arrayWithObject:node]];
	}

	// expand item
	if ([options containsObject:@"expand"]) {
		[resourceOutlineView expandItem:outlineItem];
	} else if ([options containsObject:@"expandChildren"]) {
		[resourceOutlineView expandItem:outlineItem expandChildren:YES];
	}
 */
}

/*
 
 - expandAll:
 
 */
- (IBAction)expandAll:(id)sender
{
#pragma unused(sender)
	NSInteger row = [resourceOutlineView clickedRow];
	if (row == -1) {
		row = [resourceOutlineView selectedRow];	
	}
	if (row == -1) return;
	
	[resourceOutlineView expandItem:[resourceOutlineView itemAtRow:row] expandChildren:YES];
}

/*
 
 - collapseAll:
 
 */
- (IBAction)collapseAll:(id)sender
{
#pragma unused(sender)
	NSInteger row = [resourceOutlineView clickedRow];
	if (row == -1) {
		row = [resourceOutlineView selectedRow];	
	}
	if (row == -1) return;
	
	[resourceOutlineView collapseItem:[resourceOutlineView itemAtRow:row] collapseChildren:YES];
}


/*
 
 - selectedResourceTreeNode
 
 */
- (MGSResourceBrowserNode *)selectedResourceTreeNode
{
	// selected tree objects
	NSArray *selectedObjects = [resourceTreeController selectedObjects];
	if ([selectedObjects count] == 0) {
		return nil;
	}
	
	// validate
	NSAssert([selectedObjects count] == 1, @"multiple selections not supported");
	MGSResourceBrowserNode *selectedNode = [selectedObjects objectAtIndex:0];		
	NSAssert([selectedNode isKindOfClass:[MGSResourceBrowserNode class]], @"invalid tree node class");

	return selectedNode;
}

/*
 
 - selectedResourceArrayNode
 
 */
- (MGSResourceBrowserNode *)selectedResourceArrayNode
{
	NSArray *selectedObjects = [resourceArrayController selectedObjects];
	if ([selectedObjects count] == 0) {
		return nil;
	}

	// validate
	NSAssert([selectedObjects count] == 1, @"multiple selections not supported");
	MGSResourceBrowserNode *selectedNode = [selectedObjects objectAtIndex:0];		
	NSAssert([selectedNode isKindOfClass:[MGSResourceBrowserNode class]], @"invalid node class");

	return selectedNode;
}

#pragma mark -
#pragma mark Resource nodes

/*
 
 - resourceNodeSelected:
 
 */
- (void)resourceNodeSelected:(MGSResourceBrowserNode *)selectedNode
{
	id nodeObject = [selectedNode representedObject];
	
	self.selectedResource = nil;
	self.resourceName = nil; 		
	self.selectedResourcesManager = nil;
	
	// can only add a resource if a resource manager or item is selected.
	// if anything else is selected we won't know what class of item to add
	if ([nodeObject isKindOfClass:[MGSResourcesManager class]]) {
		
		// select resource item child
		if ([[selectedNode childNodes] count] > 0) {
			selectedNode = [[selectedNode childNodes] objectAtIndex:0];
			nodeObject = [selectedNode representedObject];
		} else {
			self.selectedResourcesManager = nodeObject;
		}
	}
	
	if ([nodeObject isKindOfClass:[MGSResourceItem class]]) {
		
		self.resourceName = [selectedNode name]; 
		self.selectedResourcesManager = [nodeObject delegate];
		self.selectedResource = nodeObject;		
	} 
	
	[self buildSettingsTree];
}


#pragma mark -
#pragma mark Resources

/*
 
 - clickedResource
 
 */
- (MGSResourceItem *)clickedResource:(id)sender
{
	id object = [self clickedObject:sender];
	if ([object isKindOfClass:[MGSResourceItem class]]) {
		return (MGSResourceItem *)object;
	}
	
	return nil;
}

/*
 
 - clickedObject
 
 */
- (id)clickedObject:(id)sender
{
	id object = self.selectedResource;
	
	if ([sender respondsToSelector:@selector(clickedRow)]) {
		NSInteger row = [sender clickedRow];
		if (row == -1) {
			if ([sender respondsToSelector:@selector(selectedRow)]) {
				row = [sender selectedRow];
			}
		}
		
		if (row == -1) {
			return nil;
		}
		
		MGSResourceBrowserNode *node = nil;
		
		if (sender == resourceOutlineView) {
			NSTreeNode *outlineNode = [resourceOutlineView itemAtRow:row];
			node = outlineNode.representedObject;
		} else if (sender == resourceTableView) {
			node = [[resourceArrayController arrangedObjects] objectAtIndex:row];
		} else {
			object = nil;
		}
		
		object = node.representedObject;
	}
	return object;
}

/*
 
 - addResource:
 
 */
- (IBAction)addResource:(id)sender;
{	
#pragma unused(sender)
	[self commitEditing];
	
	// resources can only be added to the user resources manager
	[self.selectedResourcesManager addNewResource]; 
	
	self.documentEdited = YES;
}

#pragma mark -
#pragma mark Duplicate resource

/*
 
 - duplicateResource:
 
 */
- (void)duplicateResource:(id)sender
{
#pragma unused(sender)
	
	[self commitEditing];
		
	if ([self.selectedResource.delegate isKindOfClass:[MGSResourcesManager class]]) {
				
		MGSResourcesManager *manager = self.selectedResource.delegate;

		id clickedResource = [self clickedResource:sender];
		[manager addDuplicateResource:clickedResource]; 
			
	}
}

/*
 
 - duplicateOutlineResource:
 
 */
- (IBAction)duplicateOutlineResource:(id)sender
{
	#pragma unused(sender)
	
	[self duplicateResource:resourceOutlineView];
}

/*
 
 - duplicateTableResource:
 
 */
- (IBAction)duplicateTableResource:(id)sender
{
	#pragma unused(sender)
	
	[self duplicateResource:resourceTableView];
}

#pragma mark -
#pragma mark Delete resource

/*
 
 - deleteResource:
 
 */
- (void)deleteResource:(id)sender
{
#pragma unused(sender)
	
	//[self commitEditing];
	
	[self.selectedResourcesManager deleteResource:[self clickedResource:sender]];
}

/*
 
 - deleteOutlineResource:
 
 */
- (IBAction)deleteOutlineResource:(id)sender
{
#pragma unused(sender)
	
	[self deleteResource:resourceOutlineView];
}

/*
 
 - deleteTableResource:
 
 */
- (IBAction)deleteTableResource:(id)sender
{
#pragma unused(sender)
	
	[self deleteResource:resourceTableView];
}

#pragma mark -
#pragma mark Default resource
/*
 
 - setDefaultResource:
 
 */
- (IBAction)setDefaultResource:(id)sender
{
	id selectedObject = [self clickedObject:sender];
		
	if ([selectedObject isKindOfClass:[MGSResourceItem class]]) {
		
		MGSResourceItem *resource = selectedObject;
		id manager = [resource delegate];
		if ([manager isKindOfClass:[MGSResourcesManager class]]) {
			[manager setDefaultResourceID:resource.ID];
		}
	} else if ([selectedObject isKindOfClass:[MGSLanguagePlugin class]]) {

		MGSLanguagePlugin *plugin = selectedObject;
		[[MGSLanguagePluginController sharedController] setDefaultScriptType:[plugin scriptType]];

		[self updateDefaultLanguagePlugin];
		
	} else {
		MLogInfo(@"cannot set default for class: %@", [selectedObject className]);
	}
	
	self.documentEdited = YES;
}

/*
 
 - setDefaultOutlineResource:
 
 */
- (IBAction)setDefaultOutlineResource:(id)sender
{
	#pragma unused(sender)
	
	[self setDefaultResource:resourceOutlineView];
}

/*
 
 - setDefaultTableResource:
 
 */
- (IBAction)setDefaultTableResource:(id)sender
{
	#pragma unused(sender)
	
	[self setDefaultResource:resourceTableView];
}


#pragma mark -
#pragma mark Persistence

/*
 
 - saveDocument:
 
 */
- (IBAction)saveDocument:(id)sender
{
#pragma unused(sender)
	
	// TODO: the MGSResourcesManager should track its own dirty status
	
	// check if document edited
	if (!self.documentEdited) {
		return;
	}
	
	// end editing
	[self commitEditing];

	// template resource
	if ([self.selectedResource isKindOfClass:[MGSLanguageTemplateResource class]]) {
				
		// get dictionary of language settings to be saved as dictionary resource
		self.selectedResource.dictionaryResource = [[self languagePropertyManager] dictionaryOfModifiedProperties];
	}
	
	// save manager and resource
	[self.selectedResourcesManager save];
	[self.selectedResource save];
	
	// reset edit flag
	self.documentEdited = NO;	
	settingsOutlineViewController.documentEdited = NO;
	resourceDocumentViewController.documentEdited = NO;
}

/*
 
 - saveViewState
 
 */
- (void)saveViewState
{
	[self saveViewFramesUsingDefaults:self.viewFrameDefaults];
}
#pragma mark -
#pragma mark Language resource

/*
 
 - updateDefaultLanguagePlugin
 
 */
- (void)updateDefaultLanguagePlugin
{
	self.defaultScriptType = [[MGSLanguagePluginController sharedController] defaultScriptType];
	for (MGSResourceBrowserNode *node in [languageRootNode childNodes]) {
		
		NSAssert([node.representedObject isKindOfClass:[MGSLanguagePlugin class]], @"invalid language node class");
		
		MGSLanguagePlugin *plugin = node.representedObject;			
		if ([plugin.scriptType isEqualToString:self.defaultScriptType]) {
			node.statusImage = [[[MGSImageManager sharedManager] defaultResource] copy];
		} else {
			node.statusImage = nil;
		}
	}
	
	self.defaultScriptType = [[MGSLanguagePluginController sharedController] defaultScriptType];
	
	//self.documentEdited = YES;
}

/*
 
 - languagePropertyManager
 
 */
- (MGSLanguagePropertyManager *)languagePropertyManager
{
	return settingsOutlineViewController.languagePropertyManager;
}

/*
 
 - setLanguagePropertyManager
 
 */
- (void)setLanguagePropertyManager:(MGSLanguagePropertyManager *)manager
{
	settingsOutlineViewController.languagePropertyManager = manager;
}


#pragma mark -
#pragma mark Template resource

/*
 
 - selectDefaultTemplate
 
 */
- (void)selectDefaultTemplate
{
	for (MGSResourceBrowserNode *node in [languageRootNode childNodes]) {
		
		NSAssert([node.representedObject isKindOfClass:[MGSLanguagePlugin class]], @"invalid language node class");
		
		MGSLanguagePlugin *plugin = node.representedObject;	
		
		// match plugin script type
		if ([plugin.scriptType isEqualToString:self.defaultScriptType]) {
	
			MGSResourceItem *pluginResource = [plugin defaultTemplateResource];
			MGSResourceItem *resource = nil;
			if (pluginResource) {
				
					// we may be operating on a copy of the master resource tree
					// hence the pluginResource object may not exist in our tree.
					// hence we search for the ID
					NSNumber *resourceID = [pluginResource ID];
					NSString *resourceOrigin = pluginResource.origin;
				
					for (NSTreeNode *childNode in [node childNodes]) {
						NSAssert([childNode.representedObject isKindOfClass:[MGSLanguageResourcesManager class]], @"bad manager class");
						
						MGSLanguageResourcesManager *manager = childNode.representedObject;
						if ([manager.origin isEqualToString:resourceOrigin] ) {
							resource = [manager.templateManager resourceWithID:resourceID];
							if (resource) break;
						}
					}
					
				[resourceTreeController dm_setSelectedObjects:[NSArray arrayWithObject:resource.node]];
				[self scrollVisible:resourceOutlineView];
				
				// when displayed as sheet scrollRowToVisible: fails
				[self performSelector:@selector(scrollVisible:) withObject:resourceOutlineView afterDelay:0];
			}
			break;
		}
	}
}

/*
 
 - scrollVisible:
 
 */
- (void)scrollVisible:(id)sender
{
	if ([sender isKindOfClass:[NSTableView class]]) {
		NSInteger selectedRow = [sender selectedRow];
		[sender scrollRowToVisible:selectedRow];
	}
}
#pragma mark -
#pragma mark Accessors

/*
 
 - setResource:
 
 */
- (void)setSelectedResource:(MGSResourceItem *)item
{
	if (!item) return;
	
	[self saveDocument:self];
	
	// unload and reload external resource properties
	[self.selectedResource unload];
	selectedResource = item;
	[self.selectedResource load];
	
	// has required resource type has been selected?
	self.requiredResourceSelected = [self.selectedResource isKindOfClass:[requiredResourceClass class]];
	
	// is the resource editable?
    // application resources are generally not editable.
    // user resources are.
    // if the resource manager can be mutated then the resources themselves can be edited.
	BOOL canEdit = NO;
	id manager = [self.selectedResource delegate];
	if ([manager isKindOfClass:[MGSResourcesManager class]]) {
		canEdit = [manager canMutate];
	}
	self.resourceEditable = canEdit;
	
	resourceDocumentViewController.selectedResource = item;
	
	// get node represented object and display
	if ([self.selectedResource isKindOfClass:[MGSLanguageTemplateResource class]]) {
				
		NSAssert(self.languagePlugin, @"languagePlugin nil");
		
		// set the string.
		NSString *stringResource = [self.selectedResource stringResource];
		[fragaria setString:stringResource];
		
		// set text syntax definition
		NSString *syntaxDefinition = [self.languagePlugin syntaxDefinition];
		[fragaria setObject:syntaxDefinition forKey:MGSFOSyntaxDefinitionName];
		
		self.resourceTabIndex = MGS_TEMPLATE_TAB_INDEX;
		
	} else if ([self.selectedResource isKindOfClass:[MGSLanguageDocumentResource class]]) {			
		
		self.resourceTabIndex = MGS_DOCUMENT_TAB_INDEX;
		
	} else if ([self.selectedResource isKindOfClass:[MGSLanguagePropertiesResource class]]) {			
		
		self.resourceTabIndex = MGS_SETTINGS_TAB_INDEX;

	} else {
		
		self.resourceTabIndex = MGS_DOCUMENT_TAB_INDEX;
		
	}
	
}

/*
 
 - setSelectedResourcesManager:
 
 */
- (void)setSelectedResourcesManager:(MGSResourcesManager *)manager
{
	selectedResourcesManager = manager;
	if (selectedResourcesManager) {
		self.newResourceClass = [selectedResourcesManager resourceClass];
		
		NSAssert([[selectedResourcesManager rootManagerDelegate] isKindOfClass:[MGSLanguagePlugin class]], @"bad delegate class");
		
		self.languagePlugin = (MGSLanguagePlugin *)[selectedResourcesManager rootManagerDelegate];
	} else {
		self.newResourceClass = nil;
		self.languagePlugin = nil;
	}
}


/*
 
 - setLanguagePlugin:
 
 */
- (void)setLanguagePlugin:(MGSLanguagePlugin *)plugin
{
	languagePlugin = plugin;
	self.title = [plugin scriptType];
}

/*
 
 - setTitle:
 
 */
- (void)setTitle:(NSString *)aString
{
	if (!aString) {
		aString = NSLocalizedString(@"Resources", @"Default resource browser view title");
	}
	title = aString;
}

/*
 
 - setNewResourceClass:
 
 */
- (void)setNewResourceClass:(Class)klass
{
	//NSAssert([klass isMemberOfClass:[MGSResourceItem class]], @"bad resource class");
	
	newResourceClass = klass;
	
	/*
	NSString *resourceTitle = [MGSResourceItem title];
	if (self.tableCanAddResource) {
		resourceTitle = [klass title];
	} 
	
	self.addResourceMenuTitle = [NSString stringWithFormat: NSLocalizedString(@"Add %@", @"Resource browser menu title"), resourceTitle];
	self.deleteResourceMenuTitle = [NSString stringWithFormat: NSLocalizedString(@"Delete %@", @"Resource browser menu title"), resourceTitle];
	 */
}

/*
 
 - setEditable:
 
 */
- (void)setEditable:(BOOL)aBool
{
	editable = aBool;
	
	NSMenu * menu = nil;
	NSRect rect = [tableItemCount frame];
	if (editable) {
		rect.origin.x = initialTableItemFrame.origin.x;
		menu = tableContextMenu;
	} else {
		rect.origin.x = 8;
	}
	[tableItemCount setFrame:rect];
	[tableItemCount setNeedsDisplay:YES];
	[resourceTableView setMenu:menu];
	
	settingsOutlineViewController.editable = self.editable;
}
/*
 
 - setResourceEditable:
 
 */
- (void)setResourceEditable:(BOOL)aBool
{
    resourceEditable = aBool;
    
    settingsOutlineViewController.resourceEditable = self.resourceEditable;
}

/*
 
 - setDefaultScriptType:
 
 */
- (void)setDefaultScriptType:(NSString *)scriptType
{
	defaultScriptType = scriptType;
	[self selectDefaultTemplate];
}

/*
 
 - setDocumentEdited:
 
 */
- (void)setDocumentEdited:(BOOL)value
{
    documentEdited = value;
}

#pragma mark -
#pragma mark Editing

/*
 
 - commitEditing
 
 */
- (void)commitEditing
{
	[resourceArrayController commitEditing];
	[resourceTreeController commitEditing];
	[resourceController commitEditing];
	
	// fragaria is not bound so we commit our edit manually
	if ([self.selectedResource isKindOfClass:[MGSLanguageTemplateResource class]]) {
		self.selectedResource.stringResource = [[fragaria string] copy];
	}
	
}

/*
 
 - selectedTemplate
 
 */
- (MGSLanguageTemplateResource *)selectedTemplate
{
	if ([self.selectedResource isKindOfClass:[MGSLanguageTemplateResource class]]) {
		return (MGSLanguageTemplateResource *)self.selectedResource;
	}
	
	return nil;
}

#pragma mark -
#pragma mark Validation

/*
 
 - validateMenuItem:
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	// menu selector
	SEL menuActionSelector = [menuItem action];
	
		
	// set default script
	// node expansion/collapsing
	if (menuActionSelector == @selector(expandAll:) || menuActionSelector == @selector(collapseAll:)) {
		NSInteger row = [resourceOutlineView clickedRow];
		if (row == -1) {
			row = [resourceOutlineView selectedRow];	
		}
		if (row == -1) return NO;

		// itemAtRow: returns an NSTreeNode - see release notes for 10.5
		NSTreeNode *node = [resourceOutlineView itemAtRow:row];
		return ![node isLeaf];
	}
	
	return YES;
}

#pragma mark -
#pragma mark KVO

/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
    
	if (context == &MGSDocumentEditedContext) {
		
		if (resourceDocumentViewController.documentEdited) {
			self.documentEdited = YES;
		}
		
		return;
	} else if (context == &MGSDocumentModeContext) {
		[resourceController commitEditing];
		return;
	}
	
	[self commitEditing];
	
	// resource tableview selection changed
	if (context == &MGSResourceSelectedObjectsContext) {

		[self viewEditability:resourceTableView forResource:nil];

		// selected resource array node
		MGSResourceBrowserNode *selectedNode = [self selectedResourceArrayNode];
		if (!selectedNode) {
			//self.tableCanAddResource = self.outlineCanAddResource;
			return;
		}
		
		// process selected node
		[self resourceNodeSelected:selectedNode];

		[self viewEditability:resourceTableView forResource:selectedNode.representedObject];		
		
	// resource tree objects selection
	} else if (context == &MGSResourceTreeSelectedObjectsContext) {
		

		[self viewEditability:resourceOutlineView forResource:nil];

		// selected resource tree node
		MGSResourceBrowserNode *selectedNode = [self selectedResourceTreeNode];
		if (!selectedNode) {			
			return;
		}
		
		[self resourceNodeSelected:selectedNode];
		      
		// resource array binds to the nodes, not the represented object.
		// we only want leaf resources.
		self.resourceArray = [selectedNode leaves];
		
		[self viewEditability:resourceOutlineView forResource:selectedNode.representedObject];
	
        
	// settings tree objects selection
	} else if (context == &MGSSettingsTreeSelectedObjectsContext) {

		self.selectedLanguageProperty = settingsOutlineViewController.selectedLanguageProperty;
		
	} else if (context == &MGSSettingsTreeEditedContext) {
		
		if (settingsOutlineViewController.documentEdited) {
			self.documentEdited = YES;
		}
		
	} 	
}

/*
 
 - viewEditability:forResource:
 
 */
- (void)viewEditability:(NSView *)view forResource:(id)resourceObject
{
	BOOL canAdd = NO;
	BOOL canDelete = NO;
	BOOL canDuplicate = NO;
	BOOL canDefault = NO;
	
	MGSResourceItem *resource = nil;
	MGSResourcesManager *manager = nil;
	
	if (view == resourceOutlineView) {
		
		if ([resourceObject isKindOfClass:[MGSResourceItem class]]) {
			resource = resourceObject;
			manager = [resource delegate];
			
			MGSResourceItem *defaultResource = [manager defaultResource];
			BOOL defaultResourceSelected = defaultResource == resource;
			
			canAdd = YES;
			canDelete = [manager canAddResources] && !defaultResourceSelected;
			canDuplicate = YES;
			canDefault = [resource canDefaultResource] && !defaultResourceSelected;	
		} else if ([resourceObject isKindOfClass:[MGSLanguageTemplateResourcesManager class]] ||
				   [resourceObject isKindOfClass:[MGSLanguageDocumentResourcesManager class]]) {
			canAdd = YES;
		} else if ([resourceObject isKindOfClass:[MGSLanguagePlugin class]]) {
			canDefault = YES;
		}
		
		self.outlineCanAddResource = canAdd;
		self.outlineCanDeleteResource = canDelete;
		self.outlineCanDuplicateResource = canDuplicate;
		self.outlineCanDefaultResource = canDefault;	
	} else if (view == resourceTableView) {
		
		if (!resourceObject) {
			canAdd = self.selectedResourcesManager ? YES : NO;
		} else if ([resourceObject isKindOfClass:[MGSResourceItem class]]) {
			resource = resourceObject;
			canAdd = self.selectedResourcesManager ? YES : NO;
			canDelete = self.resourceEditable;
			canDuplicate = YES;
			canDefault = [resource canDefaultResource];
		}
		
		self.tableCanAddResource = canAdd;
		self.tableCanDeleteResource = canDelete;
		self.tableCanDuplicateResource = canDuplicate;
		self.tableCanDefaultResource = canDefault;
	} else {
		NSAssert(NO, @"invalid view");
	}

	// resource title
	NSString *resourceTitle = nil;
	if ([resourceObject isKindOfClass:[MGSResourceItem class]]) {
		resourceTitle = [(MGSResourceItem *)resourceObject title];
	} else if ([resourceObject isKindOfClass:[MGSResourcesManager class]]) {
		resourceTitle = [[(MGSResourcesManager *)resourceObject resourceClass] title];
	} 
	
	if (!resourceTitle) {
		resourceTitle = [MGSResourceItem title];
	}
	
	self.addResourceMenuTitle = [NSString stringWithFormat: NSLocalizedString(@"Add %@", @"Resource browser menu title"), resourceTitle];
	self.deleteResourceMenuTitle = [NSString stringWithFormat: NSLocalizedString(@"Delete %@", @"Resource browser menu title"), resourceTitle];
	
}

#pragma mark -
#pragma mark NSView handling

/*
 
 - restoreViewFramesUsingDefaults:
 
 */
- (void)restoreViewFramesUsingDefaults:(NSDictionary *)viewDefaults
{
	if (!viewDefaults) return;
	
	[splitViewMain restoreSubviewFramesWithDefaultsName:[viewDefaults objectForKey:@"MainSplitView"]];
	[splitViewResource restoreSubviewFramesWithDefaultsName:[viewDefaults objectForKey:@"ResourceSplitView"]];
}

/*
 
 - saveViewFramesUsingDefaults:
 
 */
- (void)saveViewFramesUsingDefaults:(NSDictionary *)viewDefaults
{
	if (!viewDefaults) return;
	
	[splitViewMain saveSubviewFramesWithDefaultsName:[viewDefaults objectForKey:@"MainSplitView"]];
	[splitViewResource saveSubviewFramesWithDefaultsName:[viewDefaults objectForKey:@"ResourceSplitView"]];
}

/*
 
 - setViewFrameDefaults:
 
 */
- (void)setViewFrameDefaults:(NSDictionary *)viewDefaults
{
	viewFrameDefaults = viewDefaults;
	[self restoreViewFramesUsingDefaults:self.viewFrameDefaults];
}

#pragma mark -
#pragma mark NSTabView

/*
 
 - setResourceTabIndex:
 
 */
- (void)setResourceTabIndex:(NSInteger)idx
{
	resourceTabIndex = idx;
	
	NSTabViewItem *tabViewDoc1 = [resourceTabView tabViewItemAtIndex:MGS_DOCUMENT_TAB_INDEX];
	NSTabViewItem *tabViewDoc2 = [resourceChildTabView tabViewItemAtIndex:MGS_DOCUMENT_CHILD_TAB_INDEX];
	
	NSTabViewItem *tabViewSettings1 = [resourceTabView tabViewItemAtIndex:MGS_SETTINGS_TAB_INDEX];
	NSTabViewItem *tabViewSettings2 = [resourceChildTabView tabViewItemAtIndex:MGS_SETTINGS_CHILD_TAB_INDEX];
	
	// add sub view to required view hierarchy
	if (idx == MGS_DOCUMENT_TAB_INDEX) {
		if ([tabViewDoc1 view] != [resourceDocumentViewController view]) {
			[tabViewDoc2 setView:[[NSView alloc] initWithFrame:[[resourceDocumentViewController view] frame]]];
			[tabViewDoc1 setView:[resourceDocumentViewController view]];
		}
	} else if (idx == MGS_TEMPLATE_TAB_INDEX) {
		if ([tabViewDoc2 view] != [resourceDocumentViewController view]) {
			[tabViewDoc1 setView:[[NSView alloc] initWithFrame:[[resourceDocumentViewController view] frame]]];
			[tabViewDoc2 setView:[resourceDocumentViewController view]];
		}
		if ([tabViewSettings2 view] != settingsView) {
			[tabViewSettings1 setView:[[NSView alloc] initWithFrame:[settingsView frame]]];
			[tabViewSettings2 setView:settingsView];
		}
	} else if (idx == MGS_SETTINGS_TAB_INDEX) {
		if ([tabViewSettings1 view] != settingsView) {
			[tabViewSettings2 setView:[[NSView alloc] initWithFrame:[settingsView frame]]];
			[tabViewSettings1 setView:settingsView];
		}
	}
}

#pragma mark -
#pragma mark NSOutlineView Delegate

/*
 
 - outlineView:shouldSelectItem:
 
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	NSTreeNode *node = item;
	
	if (outlineView == resourceOutlineView) {
		NSAssert([[node representedObject] isKindOfClass:[MGSResourceBrowserNode class]], @"bad node class");
		
		MGSResourceBrowserNode *browserNode = [node representedObject];
		if (![browserNode parentNode]) {
			return YES;
		}
	}
		
	return YES;
}

/*
 
 - mgs_outlineView:drawStyleForRow:
 
 */
-(NSInteger)mgs_outlineView:(NSOutlineView *)outlineView drawStyleForRow:(int)row
{
	NSInteger drawStyle = 0;
	
	if (outlineView == resourceOutlineView) {
		
		drawStyle = [self _mgs_outlineView:outlineView drawStyleForRow:row];		
		if (drawStyle == 1 && row > 0) {
			NSInteger prevDrawStyle = [self _mgs_outlineView:outlineView drawStyleForRow:row-1];
			
			if (prevDrawStyle == 0) {
				drawStyle |= 0x02;
			}
		}
	} 
	
	return drawStyle;
}

/*
 
 - _mgs_outlineView:drawStyleForRow:
 
 */
-(NSInteger)_mgs_outlineView:(NSOutlineView *)outlineView drawStyleForRow:(int)row
{
	NSInteger drawStyle = 0;
	
	if (outlineView == resourceOutlineView) {
		
		// release notes for 10.5 state itemAtRow is NSTreeNode
		NSTreeNode *node = [outlineView itemAtRow:row];
		
		MGSResourceBrowserNode *browserNode = [node representedObject];
		if (!browserNode) return 0;
		NSAssert([browserNode isKindOfClass:[MGSResourceBrowserNode class]], @"bad node class");
		
		id object = browserNode.representedObject;
		if ([object isKindOfClass:[MGSLanguagePlugin class]]) {
			drawStyle = 0x1;
		} else if (![browserNode parentNode]) {
			drawStyle = 0x1;
		}
	}
	
	return drawStyle;
}

#pragma mark -
#pragma mark NSSplitView Delegate

/*
 
 splitView:resizeSubviewsWithOldSize:
 
 */
- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize: (NSSize)oldSize
{	
	MGSSplitviewBehaviour behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;
	NSArray *minWidthArray = nil;
	
	if (splitView == splitViewMain) {
		minWidthArray = [NSArray arrayWithObjects:[NSNumber numberWithDouble:150], [NSNumber numberWithDouble:250], nil];
		behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;
	} else if (splitView == splitViewResource) {
		minWidthArray = [NSArray arrayWithObjects:[NSNumber numberWithDouble:150], [NSNumber numberWithDouble:0], nil];
		behaviour = MGSSplitviewBehaviourOf2ViewsSecondFixed;
	}
	
	// see the NSSplitView_Mugginsoft category
	[splitView resizeSubviewsWithOldSize:oldSize withBehaviour:behaviour minSizes:minWidthArray];
}

/*
	  
- splitView:additionalEffectiveRectOfDividerAtIndex:
 
*/
- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
#pragma unused(dividerIndex)
	
	NSView *view = nil;
	if (splitView == splitViewMain) {
		view = splitViewMainDrag;
	} 
	
	if (!view) return NSZeroRect;
	return [splitView convertRect:[view bounds] fromView:view];
}
/*
 
 - splitView:constrainMaxCoordinate:ofSubviewAt:
 
 */
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
#pragma unused(offset)
	
	//NSView *subview = [[splitView subviews] objectAtIndex:offset];
	//CGFloat width = [[subview superview] bounds].size.width;
	
	CGFloat value = proposedMax;
	
	if (splitView == splitViewMain) {
		value = 500.0f;
	} else if (splitView == splitViewResource) {
		value = proposedMax;
	}
	
	return value;
}
/*
 
 - splitView:constrainMinCoordinate:ofSubviewAt:
 
 */
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
#pragma unused(offset)
	
	CGFloat value = proposedMin;
	
	if (splitView == splitViewMain) {
		value = 150.0f;
	} else if (splitView == splitViewResource) {
		value = 150.0f;
	}
	
	return value;
}

#pragma mark -
#pragma mark NSMenu delegate

/*
 
 - menuNeedsUpdate
 
 */
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if (menu == [resourceTableView menu]) {
		[self tableView:resourceTableView menuNeedsUpdate:menu];
	} else if (menu == [resourceOutlineView menu]) {
		[self tableView:resourceOutlineView menuNeedsUpdate:menu];
	}
}

/*
 
 - menuDidClose:
 
 */
- (void)menuDidClose:(NSMenu *)menu
{
	if (menu == [resourceTableView menu] || menu == [resourceOutlineView menu]) {
		//clickedResource = nil;
	}
	
}

/*
 
 - tableView:menuNeedsUpdate:
 
 */
- (void)tableView:(NSTableView *)tableView menuNeedsUpdate:(NSMenu *)menu
{
	#pragma unused(menu)
	
	NSInteger row = [tableView clickedRow];
	
	if (row == -1) {
		row = [tableView selectedRow];	
	}
	if (row == -1) return;

	MGSResourceBrowserNode *node = nil;
	if ([tableView isKindOfClass:[NSOutlineView class]]) {
		node = [(NSTreeNode *)[(NSOutlineView *)tableView itemAtRow:row] representedObject];
	} else {
		node = [[resourceArrayController arrangedObjects] objectAtIndex:row];
	}
	
	MGSResourceItem *resource = node.representedObject;
	[self viewEditability:tableView forResource:resource];
	
}	
#pragma mark -
#pragma mark NSTextView delegate
/*
 
 - textDidChange:
 
 */
- (void)textDidChange:(NSNotification *)notification
{
#pragma unused(notification)
	
	self.documentEdited = YES;
}

/*
 
 - controlTextDidChange:
 
 */
- (void)controlTextDidChange:(NSNotification *)notification
{
#pragma unused(notification)
	
	self.documentEdited = YES;
}

#pragma mark -
#pragma mark Notifications

/*
 
 - applicationWillTerminate:
 
 */
- (void)applicationWillTerminate:(NSNotification *)notification
{
#pragma unused(notification)
	
	[self saveDocument:self];
	
	[self saveViewState];
}

/*
 
 - resourcesManagerWillChange:
 
 */
- (void)resourcesManagerWillChange:(NSNotification *)note
{
	id sender = [note object];
	NSDictionary *userInfo = [note userInfo];
	MGSResourceItem *resource = nil;
	
	if (![sender isKindOfClass:[MGSResourcesManager class]]) {
		return;
	}
	
	// resource will be deleted
	if ([userInfo objectForKey:MGSResourceDeleted]) {
		resource = [userInfo objectForKey:MGSResourceDeleted];
						
		NSAssert([resource isKindOfClass:[MGSResourceItem class]], @"bad resource class");
		
		if ([[resourceTreeController selectedObjects] containsObject:resource.node]) {
			
			// get NSTreeController tree node
			NSIndexPath *indexPath = [resourceTreeController dm_indexPathToObject:resource.node];
			NSTreeNode *treeNode = [[resourceTreeController arrangedObjects] descendantNodeAtIndexPath:indexPath];
			
			if (![treeNode isLeaf]) {
				return;
			}
			
			// child index of item to delete
			NSTreeNode *parentNode = [treeNode parentNode];
			NSUInteger idx = [[parentNode childNodes] indexOfObject:treeNode];
			
			// we are going to delete the resource so select alternative
			if (idx > 0) {
				treeNode = [[parentNode childNodes] objectAtIndex:--idx];
			} else if ([[parentNode childNodes] count] > 1) {
				treeNode = [[parentNode childNodes] objectAtIndex:1];
			} else {
				treeNode = parentNode;
			}
			[self processOutlineResourceNode:treeNode.representedObject options:[NSSet setWithObjects:@"select", @"expand", nil]];
		 }
	}
	
}

/*
 
 - resourcesManagerDidChange:
 
 */
- (void)resourcesManagerDidChange:(NSNotification *)note
{
	id sender = [note object];
	NSDictionary *userInfo = [note userInfo];
	MGSResourceItem *resource = nil;
	
	if (![sender isKindOfClass:[MGSResourcesManager class]]) {
		return;
	}
	
	// resource added
	if ([userInfo objectForKey:MGSResourceAdded]) {
		resource = [userInfo objectForKey:MGSResourceAdded];
		
		// select the new resource
		[self processOutlineResourceNode:resource.node options:[NSSet setWithObjects:@"select", @"expand", nil]];
		
	}
	
	// resource deleted
	if ([userInfo objectForKey:MGSResourceDeleted]) {
		resource = [userInfo objectForKey:MGSResourceDeleted];
	}

	// default resource id changed
	if ([userInfo objectForKey:MGSDefaultResourceIDChanged]) {
		resource = [userInfo objectForKey:MGSDefaultResourceIDChanged];
	}
	
	// mark document dirty
	self.documentEdited = YES;
	
	// save if we are editable only.
    if (self.editable) {
        [self saveDocument:self];
    }
}

@end
