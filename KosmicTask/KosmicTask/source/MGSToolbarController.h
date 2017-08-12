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

enum _eMGSToolbarStyle {
	MGSToolbarStyleMain = 0,
	MGSToolbarStyleEdit = 1,
	MGSToolbarStyleAction = 2,
	MGSToolbarStyleResult = 3,
};
typedef NSInteger MGSToolbarStyle;

@protocol MGSToolbarDelegate
@optional
- (BOOL)saveClientBeforeChangeToRunMode:(NSInteger)mode;
@end

@interface MGSToolbarController : NSObject <NSToolbarDelegate> {
	IBOutlet NSToolbar *toolbar;
	IBOutlet NSWindow *__weak window;
	IBOutlet NSView *searchView;
	IBOutlet NSSearchField *searchField;
	
	IBOutlet MGSDisplayToolViewController *__weak displayPanelController;
	IBOutlet MGSModeToolViewController *__weak modeViewController;
	IBOutlet MGSActionToolViewController *__weak actionViewController;
	IBOutlet MGSEditModeToolViewController *__weak editModeViewController;
	IBOutlet MGSScriptToolViewController *__weak scriptViewController;
	IBOutlet MGSResultToolViewController *__weak resultViewController;
	IBOutlet MGSMinimalViewToolViewController *__weak minimalViewController;
	
	NSMutableDictionary *toolbarItems; //The dictionary that holds all our "master" copies of the NSToolbarItems
	
	MGSTaskSpecifier *_actionSpecifier; // currently active action
	id _delegate;
	MGSToolbarStyle _style;
	NSString *_identifier;
	NSArray *_utilisedControllers;
	MGSNetClient *__weak _netClient;
}

- (void)loadNib;
- (void)setDelegate:(id <MGSToolbarDelegate>)object;
- (void)setRunMode:(NSInteger)mode;
- (void)setUtilisedControllers:(NSArray *)controllers;
- (void)discardUnutilisedController:(id *)controller;
- (IBAction)updateSearchFilter:(id)sender;

@property (weak) NSWindow *window;
@property (strong) MGSTaskSpecifier *actionSpecifier;
@property MGSToolbarStyle style;
@property (copy) NSString *identifier;

@property (weak, readonly) MGSDisplayToolViewController *displayPanelController;
@property (weak, readonly) MGSModeToolViewController *modeViewController;
@property (weak, readonly) MGSActionToolViewController *actionViewController;
@property (weak, readonly) MGSEditModeToolViewController *editModeViewController;
@property (weak, readonly) MGSScriptToolViewController *scriptViewController;
@property (weak, readonly) MGSResultToolViewController *resultViewController;
@property (weak, readonly) MGSMinimalViewToolViewController *minimalViewController;
@property (weak) MGSNetClient *netClient;

@end
