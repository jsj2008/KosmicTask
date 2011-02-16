//
//  PrefsWindowController.h
//  mother
//
//  Created by Jonathan Mitchell on 12/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"
#import "MGSNetRequest.h"

extern NSString * MGSDefaultStartAtLogin;

@class MGSDebugController;

@interface MGSPrefsWindowController : DBPrefsWindowController <MGSNetRequestOwner> {
	IBOutlet NSView *generalPrefsView;
	IBOutlet NSView *advancedPrefsView;
	IBOutlet NSView *securityPrefsView;
	IBOutlet NSView *tabsPrefsView;
	IBOutlet NSView *internetPrefsView;
	IBOutlet NSMatrix *userNameDisclosureRadioButtons;
	IBOutlet NSObjectController *internetSharingObjectController;
	IBOutlet NSTextField *externalPort;
	
	MGSDebugController *debugController;
	
	IBOutlet NSButton *useSSLCheckbox;
	BOOL _startAtLogin;
	
	NSString *_internetTabIdentifier;
}


- (IBAction)refreshInternetSharing:(id)sender;
- (IBAction)toggleInternetSharing:(id)sender;
- (IBAction) showDebugPanel:(id)sender;
- (void) setStartAtLogin:(BOOL)value;
- (BOOL) startAtLogin;
- (void)updateServerPreferences;
- (void)retrieveServerPreferences;
- (void)showInternetPreferences;
- (IBAction)showSSLCertficate:(id)sender;
@end
