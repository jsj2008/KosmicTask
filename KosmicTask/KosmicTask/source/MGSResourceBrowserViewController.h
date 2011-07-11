//
//  MGSResourceBrowserViewController.h
//  KosmicTask
//
//  Created by Jonathan on 29/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSLanguagePlugin.h"
#import "MGSResourceBrowserNode.h"
#import "MGSLanguageTemplateResource.h"

@class MGSFragaria;
@class MGSLanguageProperty;
@class MGSSettingsOutlineViewController;
@class MGSResourceDocumentViewController;

@interface MGSResourceBrowserViewController : NSViewController <NSTextViewDelegate, NSSplitViewDelegate>{

	MGSSettingsOutlineViewController *settingsOutlineViewController;
	
	IBOutlet MGSResourceDocumentViewController *resourceDocumentViewController;
	
	// views
	IBOutlet NSSplitView *splitViewMain;
	IBOutlet NSView *splitViewMainDrag;
	IBOutlet NSSplitView *splitViewResource;
	IBOutlet NSView *editorHostView;
	IBOutlet NSOutlineView *resourceOutlineView;
	IBOutlet NSTabView *resourceTabView;
	IBOutlet NSTabView *resourceChildTabView;
	IBOutlet NSTableView *resourceTableView;
	//IBOutlet NSView *documentView;
	IBOutlet NSView *settingsView;
	IBOutlet NSTextField *tableItemCount;
	
	NSString *title;
	
	NSTextView *editorTextView;
	MGSFragaria *fragaria;	// fragaria instance
	
	// languages
	NSArray *languagePlugins;
	MGSLanguagePlugin *languagePlugin;
	NSString *defaultScriptType;
	MGSLanguageProperty *selectedLanguageProperty;
	//NSDictionary *languageProperties;
	
	// resources
	NSMutableArray *resourceTree;
	NSMutableArray *resourceArray;
	MGSResourceItem *selectedResource;
	MGSLanguageDocumentResource *infoResource;
	NSString *resourceName;
	BOOL requiredResourceSelected;
	NSString *addResourceMenuTitle;
	NSString *deleteResourceMenuTitle;
	MGSResourcesManager *selectedResourcesManager;
	
	MGSResourceBrowserNode *languageRootNode;
	
	// classes
	Class requiredResourceClass;
	Class newResourceClass;
	
	BOOL tableCanDeleteResource;
	BOOL tableCanAddResource;
	BOOL tableCanDuplicateResource;
	BOOL tableCanDefaultResource;
	
	BOOL outlineCanAddResource;
	BOOL outlineCanDeleteResource;
	BOOL outlineCanDuplicateResource;
	BOOL outlineCanDefaultResource;
	BOOL editable;	// view editable
	BOOL resourceEditable;	// resource editable
	BOOL requiredResourceDoubleClicked;
	
	BOOL documentEdited;
	//NSInteger selectedTabIndex;
	NSInteger resourceTabIndex;
	NSInteger resourceChildTabIndex;
	
	NSRect initialTableItemFrame;
	IBOutlet NSMenu *tableContextMenu;
	NSDictionary *viewFrameDefaults;
	
	// data controllers
	IBOutlet NSArrayController *resourceArrayController;
	IBOutlet NSTreeController *resourceTreeController;
	IBOutlet NSObjectController *resourceController;
}


@property (readonly) BOOL requiredResourceSelected;
@property (copy) NSString *title;

@property (assign) NSMutableArray *resourceTree;
@property (assign) NSMutableArray *resourceArray;

@property NSInteger resourceTabIndex;
@property NSInteger resourceChildTabIndex;

@property Class requiredResourceClass;
@property Class newResourceClass;

@property (assign) MGSLanguageDocumentResource *infoResource;
@property (assign) MGSResourceItem *selectedResource;
@property (assign) MGSResourcesManager *selectedResourcesManager;
@property (assign) NSString *resourceName;
//@property (assign) NSDictionary *languageProperties;

@property (assign) MGSLanguageProperty *selectedLanguageProperty;

@property (copy) NSArray *languagePlugins;
@property (assign) MGSLanguagePlugin *languagePlugin;
@property (copy) NSString *defaultScriptType;;

@property (copy) NSString *addResourceMenuTitle;
@property (copy) NSString *deleteResourceMenuTitle;

@property BOOL tableCanDeleteResource;
@property BOOL tableCanAddResource;
@property BOOL tableCanDuplicateResource;
@property BOOL tableCanDefaultResource;

@property BOOL outlineCanAddResource;
@property BOOL outlineCanDeleteResource;
@property BOOL outlineCanDuplicateResource;
@property BOOL outlineCanDefaultResource;

@property BOOL resourceEditable;

@property (getter=isEditable)BOOL editable;

@property (assign) BOOL documentEdited;
@property (assign) NSDictionary *viewFrameDefaults;
@property BOOL requiredResourceDoubleClicked;

- (MGSLanguageTemplateResource *)selectedTemplate;

- (void)buildResourceTree;
- (void)selectDefaultTemplate;

- (IBAction)addResource:(id)sender;
- (IBAction)deleteResource:(id)sender;
- (IBAction)saveDocument:(id)sender;
- (IBAction)setDefaultResource:(id)sender;
- (IBAction)expandAll:(id)sender;
- (IBAction)collapseAll:(id)sender;

- (IBAction)setDefaultOutlineResource:(id)sender;
- (IBAction)setDefaultTableResource:(id)sender;

- (IBAction)duplicateTableResource:(id)sender;
- (IBAction)duplicateOutlineResource:(id)sender;

- (IBAction)deleteTableResource:(id)sender;
- (IBAction)deleteOutlineResource:(id)sender;

- (void)saveViewState;
- (MGSLanguagePropertyManager *)languagePropertyManager;

@end
