//
//  MGSClientTaskController.h
//  Mother
//
//  Created by Jonathan on 19/12/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetClient.h"

@class MGSClientScriptManager;
@class MGSScript;


@interface MGSClientTaskController : NSObject {
	MGSClientScriptManager *_scriptManager;			// working script manager
	MGSClientScriptManager *_publicScriptManager;	// public script manager
	MGSClientScriptManager *_trustedScriptManager;	// trusted user script manager
	MGSScriptAccess _scriptAccess;						// current script access
	NSInteger _scriptAccessModes;						// supported access modes
	id _delegate;
	MGSNetClient *_netClient;
	BOOL _localScriptPropertiesLoaded;
	NSString *_activeScriptUUID;
	NSString *_activeGroupName;
	NSString *_activeGroupDisplayName;
}

@property (readonly) MGSClientScriptManager *scriptManager;	// active script controller
@property id delegate;
@property (readonly) MGSNetClient *netClient;
@property MGSScriptAccess scriptAccess;
@property (readonly) NSInteger scriptAccessModes;
@property BOOL localScriptPropertiesLoaded;
@property (copy) NSString *activeScriptUUID;
@property (copy) NSString *activeGroupName;
@property (copy) NSString *activeGroupDisplayName;

- (id)initWithNetClient:(MGSNetClient *)netClient;
- (void)updateScript:(MGSScript *)updatedScript;
- (BOOL)hasScripts;
- (void)setTrustedScriptDictionary:(NSMutableDictionary *)scriptDict;
- (void)setPublicScriptDictionary:(NSMutableDictionary *)scriptDict;
- (void)clearScripts;
- (BOOL)saveLocalScriptProperties;
- (void)setActiveGroupIndex:(NSInteger)index;
- (void)setImageNameForActiveGroup:(NSString *)imageName location:(NSString *)location;

// configuration
- (BOOL)isConfigurationEdited;
- (void)undoConfigurationChanges;
- (void)acceptConfigurationChanges;
@end
