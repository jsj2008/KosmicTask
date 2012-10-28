//
//  PrefsWindowController.h
//  mother
//
//  Created by Jonathan Mitchell on 12/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"
#import "MGSClientNetRequest.h"
#import <MGSFragaria/MGSFragaria.h>

extern NSString * MGSDefaultStartAtLogin;

@class MGSDebugController;

@interface MGSPrefsWindowController : DBPrefsWindowController <MGSNetRequestOwner, NSTabViewDelegate> {
	IBOutlet NSView *generalPrefsView;
	IBOutlet NSView *tasksPrefsView;
	IBOutlet NSView *securityPrefsView;
	IBOutlet NSView *tabsPrefsView;
	IBOutlet NSView *internetPrefsView;
    IBOutlet NSView *textEditingPrefsView;
    IBOutlet NSView *fontsAndColoursPrefsView;
	IBOutlet NSMatrix *userNameDisclosureRadioButtons;
	IBOutlet NSObjectController *internetSharingObjectController;
    IBOutlet NSObjectController *ownerObjectController;
	IBOutlet NSTextField *externalPort;
    
    MGSFragariaFontsAndColoursPrefsViewController *fontsAndColoursPrefsViewController;
    MGSFragariaTextEditingPrefsViewController *textEditingPrefsViewController;
    
	MGSDebugController *debugController;
	
	IBOutlet NSButton *useSSLCheckbox;
    IBOutlet NSButton *autoMappingCheckbox;
	BOOL _startAtLogin;
	BOOL _applyTimeoutToMachineTasks;
    NSInteger _machineTaskTimeout;
    NSInteger _machineTaskTimeoutUnits;
    
	NSString *_internetTabIdentifier;
    NSString *_generalTabIdentifier;
    NSString *_tasksTabIdentifier;
    NSString *_tabsTabIdentifier;
    NSString *_textTabIdentifier;
    NSString *_fontTabIdentifier;
    NSString *_securityTabIdentifier;
    
    NSString *_selectedNetworkTabIdentifier;
    NSString *_toolbarIdentifier;
    
    //IBOutlet NSTextField *remoteUserTaskTimeout;
    //IBOutlet NSPopUpButton  *remoteUserTaskTimeoutUnits;
}

- (IBAction)showPreferencesHelp:(id)sender;
- (IBAction)showLocalNetworkPreferencesHelp:(id)sender;
- (IBAction)showRemoteNetworkPreferencesHelp:(id)sender;
- (IBAction)refreshInternetSharing:(id)sender;
- (IBAction) showDebugPanel:(id)sender;
- (void) setStartAtLogin:(BOOL)value;
- (BOOL) startAtLogin;
- (void)updateServerPreferences;
- (void)retrieveServerPreferences;
- (void)showInternetPreferences;
- (void)showLocalNetworkPreferences;
- (IBAction)showSSLCertficate:(id)sender;
- (IBAction)revertToStandardSettings:(id)sender;
- (IBAction)autoMappingAction:(id)sender;

@property (assign) NSString *selectedNetworkTabIdentifier;

@property BOOL applyTimeoutToMachineTasks;
@property NSInteger machineTaskTimeout;
@property NSInteger machineTaskTimeoutUnits;

@end
