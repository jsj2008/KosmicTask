//
//  MGSRequestTabViewController.h
//  Mother
//
//  Created by Jonathan on 15/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSTaskSpecifier;
@class MGSRequestViewController;
@class MGSRequestTabScrollView;
@class MGSNetClient;

typedef enum {
	kMGSActionTabSelectedStartup = 0,
	kMGSActionTabSelectedUUIDMatch,
	kMGSActionTabSelectedNetClientMatch,
	kMGSActionTabSelectedNewTabCreated,
} MGSActionTabSelected;

@protocol MGSRequestTabViewController
- (void)tabViewActionSelected:(MGSTaskSpecifier *)action;
@end

@class PSMTabBarControl;
@class MGSTaskSpecifier;

@interface MGSRequestTabViewController : NSViewController {
	id _delegate;
	IBOutlet    NSTabView           *tabView;
    IBOutlet    NSTextField         *tabField;
    IBOutlet    NSDrawer            *drawer;
    IBOutlet    MGSRequestTabScrollView *requestTabScrollView;
	
	// for mproved source see https://github.com/dergraf83/PSMTabBarControl
    IBOutlet    PSMTabBarControl    *tabBar;
	IBOutlet	NSMenu				*tabContextMenu;
	
	// these outlets correspond to the config drawer
    IBOutlet    NSButton            *isProcessingButton;
    IBOutlet    NSButton            *isEditedButton;
    IBOutlet    NSTextField         *objectCounterField;
    IBOutlet    NSPopUpButton       *iconButton;
	IBOutlet	NSPopUpButton		*popUp_style;
	IBOutlet	NSPopUpButton		*popUp_orientation;
	IBOutlet	NSPopUpButton		*popUp_tearOff;
	IBOutlet	NSButton			*button_canCloseOnlyTab;
	IBOutlet	NSButton			*button_disableTabClosing;
	IBOutlet	NSButton			*button_hideForSingleTab;
	IBOutlet	NSButton			*button_showAddTab;
	IBOutlet	NSButton			*button_useOverflow;
	IBOutlet	NSButton			*button_automaticallyAnimate;
	IBOutlet	NSButton			*button_allowScrubbing;
	IBOutlet	NSButton			*button_sizeToFit;
	IBOutlet	NSTextField			*textField_minWidth;
	IBOutlet	NSTextField			*textField_maxWidth;
	IBOutlet	NSTextField			*textField_optimumWidth;
	
	NSTabViewItem *_currentTabViewItem;
	CGFloat _minViewHeight;
	
}

@property id delegate;
@property CGFloat minViewHeight;

- (MGSTaskSpecifier *)actionSpecifierForSelectedTab;
- (MGSTaskSpecifier *)actionSpecifierForTabViewItem:(NSTabViewItem *)tabViewItem;

- (NSTabViewItem *)tabViewItemForAction:(MGSTaskSpecifier *)action;
- (NSTabViewItem *)tabViewItemForActionUUID:(MGSTaskSpecifier *)action;
- (NSTabViewItem *)tabViewItemForActionClient:(MGSTaskSpecifier *)action;
- (NSInteger)actionProcessingCount;
- (MGSRequestViewController *)selectedRequestViewController;
- (void)applyUserDefaultsToSelectedTab;

// tab control
- (NSInteger)tabCount;
- (void)addDefaultTabs;
- (void)selectNextTab;
- (void)selectPreviousTab;

// MGSTaskSpecifier handling
- (void)setActionSpecifierForSelectedTab:(MGSTaskSpecifier *)action;
- (void)addTabWithActionSpecifier:(MGSTaskSpecifier *)action;
- (void)executeSelectedAction;
- (void)terminateSelectedAction;
- (void)suspendSelectedAction;
- (void)resumeSelectedAction;
- (MGSActionTabSelected)selectTabForActionSpecifier:(MGSTaskSpecifier *)action;

- (NSTabViewItem *)tabViewItemForRequestView:(MGSRequestViewController *)requestView;


// UI
- (IBAction)addNewTab:(id)sender;
- (IBAction)closeSelectedTab:(id)sender;
- (IBAction)stopProcessing:(id)sender;
- (IBAction)setIconNamed:(id)sender;
- (IBAction)setObjectCount:(id)sender;
- (IBAction)setTabLabel:(id)sender;
- (IBAction)addCopyOfSelectedTab:(id)sender;

// Actions
- (IBAction)isProcessingAction:(id)sender;
- (IBAction)isEditedAction:(id)sender;

- (PSMTabBarControl *)tabBar;

// request view controller delaget messages
- (void)requestViewActionWillChange:(MGSRequestViewController *)requestViewController;
- (void)requestViewActionDidChange:(MGSRequestViewController *)requestViewController;
- (void)closeTabForRequestView:(MGSRequestViewController *)requestView;

// tab bar config
- (void)configStyle:(id)sender;
- (void)configOrientation:(id)sender;
- (void)configCanCloseOnlyTab:(id)sender;
- (void)configDisableTabClose:(id)sender;
- (void)configHideForSingleTab:(id)sender;
- (void)configAddTabButton:(id)sender;
- (void)configTabMinWidth:(id)sender;
- (void)configTabMaxWidth:(id)sender;
- (void)configTabOptimumWidth:(id)sender;
- (void)configTabSizeToFit:(id)sender;
- (void)configTearOffStyle:(id)sender;
- (void)configUseOverflowMenu:(id)sender;
- (void)configAutomaticallyAnimates:(id)sender;
- (void)configAllowsScrubbing:(id)sender;

// delegate
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem;

// toolbar
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (IBAction)toggleToolbar:(id)sender;
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;

@end
