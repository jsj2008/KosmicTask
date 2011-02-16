//
//  MGSToolbarController.h
//  Mother
//
//  Created by Jonathan on 02/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSTaskSpecifier;
@class MGSDisplayToolViewController;
@class MGSModeToolViewController;
@class MGSEditModeToolViewController;
@class MGSViewToolViewController;
@class MGSActionToolViewController;
@class MGSScriptToolViewController;
@class MGSBrowserToolViewController;
@class MGSResultToolViewController;
@class MGSMinimalViewToolViewController;
@class MGSNetClient;

typedef enum _eMGSToolbarStyle {
	MGSToolbarStyleMain = 0,
	MGSToolbarStyleEdit = 1,
	MGSToolbarStyleAction = 2,
	MGSToolbarStyleResult = 3,
}  MGSToolbarStyle;

@protocol MGSToolbarDelegate
@optional
- (BOOL)saveClientBeforeChangeToRunMode:(NSInteger)mode;
@end

@interface MGSToolbarController : NSObject <NSToolbarDelegate> {
	IBOutlet NSToolbar *toolbar;
	IBOutlet NSWindow *window;
	IBOutlet NSView *searchView;
	IBOutlet NSSearchField *searchField;
	
	IBOutlet MGSDisplayToolViewController *displayPanelController;
	IBOutlet MGSModeToolViewController *modeViewController;
	IBOutlet MGSActionToolViewController *actionViewController;
	IBOutlet MGSEditModeToolViewController *editModeViewController;
	IBOutlet MGSScriptToolViewController *scriptViewController;
	IBOutlet MGSResultToolViewController *resultViewController;
	IBOutlet MGSMinimalViewToolViewController *minimalViewController;
	
	NSMutableDictionary *toolbarItems; //The dictionary that holds all our "master" copies of the NSToolbarItems
	
	MGSTaskSpecifier *_actionSpecifier; // currently active action
	id _delegate;
	MGSToolbarStyle _style;
	NSString *_identifier;
	NSArray *_utilisedControllers;
	MGSNetClient *_netClient;
}

- (void)loadNib;
- (void)setDelegate:(id <MGSToolbarDelegate>)object;
- (void)setRunMode:(NSInteger)mode;
- (void)setUtilisedControllers:(NSArray *)controllers;
- (void)discardUnutilisedController:(id *)controller;
- (IBAction)updateSearchFilter:(id)sender;

@property NSWindow *window;
@property (assign) MGSTaskSpecifier *actionSpecifier;
@property MGSToolbarStyle style;
@property (copy) NSString *identifier;

@property (readonly) MGSDisplayToolViewController *displayPanelController;
@property (readonly) MGSModeToolViewController *modeViewController;
@property (readonly) MGSActionToolViewController *actionViewController;
@property (readonly) MGSEditModeToolViewController *editModeViewController;
@property (readonly) MGSScriptToolViewController *scriptViewController;
@property (readonly) MGSResultToolViewController *resultViewController;
@property (readonly) MGSMinimalViewToolViewController *minimalViewController;
@property MGSNetClient *netClient;

@end
