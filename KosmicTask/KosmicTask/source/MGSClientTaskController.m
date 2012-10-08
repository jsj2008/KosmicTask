//
//  MGSClientTaskController.m
//  Mother
//
//  Created by Jonathan on 19/12/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MGSMother.h"
#import "MGSClientTaskController.h"
#import "MGSClientScriptManager.h"
#import "MGSPath.h"
#import "MGSScriptManager.h"
#import "MGSClientNetRequest.h"

NSString *MGSTaskDictTasksKey = @"Tasks";

@interface MGSClientTaskController(Private)
- (BOOL)saveLocalScriptPropertiesForAccess:(MGSScriptAccess)access;
- (BOOL)loadLocalScriptPropertiesForAccess:(MGSScriptAccess)access;
- (NSString *)localScriptPropertiesPath;
@end

@implementation MGSClientTaskController

@synthesize scriptManager = _scriptManager;
@synthesize delegate = _delegate;
@synthesize netClient = _netClient;
@synthesize scriptAccess = _scriptAccess;
@synthesize scriptAccessModes = _scriptAccessModes;
@synthesize localScriptPropertiesLoaded = _localScriptPropertiesLoaded;
@synthesize activeScriptUUID = _activeScriptUUID;
@synthesize activeGroupName = _activeGroupName;
@synthesize activeGroupDisplayName = _activeGroupDisplayName;

#pragma mark Class Methods

/*
 
 init
 
 */
- (id)init
{
	return [self initWithNetClient:nil];
}
/*
 
 init - designated init
 
 */
- (id)initWithNetClient:(MGSNetClient *)netClient
{
	if (!netClient) {
		return nil;
	}
	
	if ((self = [super init])) {
		
		_netClient = netClient;
		
		_scriptManager = [[MGSClientScriptManager alloc] init];
		_publicScriptManager = [[MGSClientScriptManager alloc] init];
		_trustedScriptManager = [[MGSClientScriptManager alloc] init];
		_scriptAccess = MGSScriptAccessNone;
		_scriptAccessModes = MGSScriptAccessInit;
		self.localScriptPropertiesLoaded = NO;

		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];

	}
	
	return self;
}


// returns YES if client has scripts.
// on returning NO the caller should attempt to retrieve
// scripts from the host
- (BOOL)hasScripts
{
	return [_scriptManager hasScripts];
}

/*
 
 set trusted script dictionary
 
 */
- (void)setTrustedScriptDictionary:(NSMutableDictionary *)scriptDict
{
	_trustedScriptManager = [[MGSClientScriptManager alloc] init];
	[_trustedScriptManager setDictionary:scriptDict];
	
	self.scriptAccess = MGSScriptAccessTrusted;
	_scriptAccessModes |= MGSScriptAccessTrusted;
}

/*
 
 set public script dictionary
 
 */
- (void)setPublicScriptDictionary:(NSMutableDictionary *)scriptDict
{
	_publicScriptManager = [[MGSClientScriptManager alloc] init];
	[_publicScriptManager setDictionary:scriptDict];
	
	self.scriptAccess = MGSScriptAccessPublic;
	_scriptAccessModes |= MGSScriptAccessPublic;
}

/*
 
 set script access to user or public
 
 */
- (void)setScriptAccess:(MGSScriptAccess)acx
{
	if (self.localScriptPropertiesLoaded) {
		[self saveLocalScriptPropertiesForAccess:self.scriptAccess];
	}

	switch (acx) {
			
			// script controller points to public scripts
		case MGSScriptAccessPublic:
			
			// if trusted mode scripts available then create public script dict from them.
			// this will update public mode with changes made in trusted mode to published tasks
			if ((_scriptAccessModes & MGSScriptAccessTrusted) == MGSScriptAccessTrusted) {
				_publicScriptManager = [_trustedScriptManager publishedScriptManager];
			}
			
			_scriptManager = _publicScriptManager;
			break;
		
		
			// script controller points to trusted user scripts
		case MGSScriptAccessTrusted:
			
			_scriptManager = _trustedScriptManager;
			break;
		
		case MGSScriptAccessNone:
			break;
			
		case MGSScriptAccessInit:
			break;
			
		default:	
			NSAssert(NO, @"invalid access");
			break;
	}

	_scriptAccess = acx;

	[self loadLocalScriptPropertiesForAccess:self.scriptAccess];
}

/*
 
 set active script UUID
 
 */
- (void)setActiveScriptUUID:(NSString *)uuid
{
	_activeScriptUUID = uuid;
}


/*
 
 set active group index
 
 */
- (void)setActiveGroupIndex:(NSInteger)idx
{
	[_scriptManager setActiveGroupIndex:idx];
	self.activeGroupName = [_scriptManager groupNameAtIndex:idx];
	self.activeGroupDisplayName = [_scriptManager groupDisplayNameAtIndex:idx];
}

/*
 
 set image name for active group
 
 */
- (void)setImageNameForActiveGroup:(NSString *)imageName location:(NSString *)location
{
	// get active group name 
	MGSScriptManager *scriptManager = [[self scriptManager] activeGroup];
	NSString *groupName = scriptManager.name;
	
	// update all MGSClientScriptHandler instances
	NSArray *handlers = [NSArray arrayWithObjects:_publicScriptManager, _trustedScriptManager, nil];
	for (MGSClientScriptManager *handler in handlers) {
		scriptManager = [handler groupWithName:groupName];
		if (scriptManager) {
			[handler setImageResourceForGroup:scriptManager name:imageName location:location];
		}
	}
}
#pragma mark Modification

/*
 
 update script
 
 */
- (void)updateScript:(MGSScript *)updatedScript
{
	[_scriptManager updateScript:updatedScript];
	
	if (_delegate && [_delegate respondsToSelector:@selector(netClientScriptDataUpdated:)]) {
		[_delegate netClientScriptDataUpdated:self.netClient];
	}
}

/*
 
 clear the scripts
 
 */
- (void)clearScripts
{
	self.scriptAccess = MGSScriptAccessInit;
	//_scriptController = [[MGSClientScriptHandler alloc] init];	
}

#pragma mark Notifcations

/*
 
 application will terminate
 
 */
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	#pragma unused(aNotification)
	
	[self saveLocalScriptProperties];
}

#pragma mark Storage
/*
 
 save local script properties
 
 */
- (BOOL)saveLocalScriptProperties
{
	return [self saveLocalScriptPropertiesForAccess:self.scriptAccess];
}

#pragma mark Configuration Changes 

/*
 
 undo configuration changes
 
 */
- (void)undoConfigurationChanges
{
	// undo configuration changes
	[_scriptManager undoConfigurationChanges];
}

/*
 
 accept configuration changes
 
 */
- (void)acceptConfigurationChanges
{
	[_scriptManager acceptConfigurationChanges];
}

/*
 
 returns YES if configuration has been edited
 
 */
- (BOOL)isConfigurationEdited
{
	BOOL edited = NO;
	
	// get list of changed scripts
	NSMutableArray *scriptArray = [[self scriptManager] changeArrayCopy];	
	if ([scriptArray count] > 0) {
		edited = YES;
	}
	
	return edited;
}

@end

@implementation MGSClientTaskController(Private)
/*
 
 local script properties path
 
 */
- (NSString *)localScriptPropertiesPath
{
	NSString *filename = [[self.netClient serviceName] stringByAppendingString:@".Tasks.plist"];
	return [[MGSPath userApplicationSupportPath] stringByAppendingPathComponent:filename];
}

/*
 
 load local script properties for access
 
 */
- (BOOL)loadLocalScriptPropertiesForAccess:(MGSScriptAccess)acx
{
	#pragma unused(acx)
	
	self.localScriptPropertiesLoaded = YES;
	
	// load the property list
	NSMutableDictionary *rootDict = [NSMutableDictionary dictionaryWithContentsOfFile:[self localScriptPropertiesPath]];
	if (!rootDict) return NO;
	
	// get the tasks dict
	NSMutableDictionary *tasksDict = [rootDict objectForKey:MGSTaskDictTasksKey];
	if (!tasksDict) return YES;
	
	// update scripts in controller with dictionary properties
	[_scriptManager updateScriptsFromLocalTaskDictionary:tasksDict];
	
	return YES;
}
/*
 
 save local script properties
 
 */
- (BOOL)saveLocalScriptPropertiesForAccess:(MGSScriptAccess)acx
{
	// can only save properties if scripts loaded
	if (acx != MGSScriptAccessPublic && acx != MGSScriptAccessTrusted) {
		return NO;
	}
	
	// load the property list
	NSMutableDictionary *rootDict = [NSMutableDictionary dictionaryWithContentsOfFile:[self localScriptPropertiesPath]];
	if (!rootDict) {
		rootDict = [NSMutableDictionary dictionaryWithCapacity:1 ];
	}
	
	// get the task dictionary
	NSMutableDictionary *taskDict = [_scriptManager localTaskDictionary];
	
	// if saving public access scripts then update the existing task dict
	if (acx == MGSScriptAccessPublic) {
		NSMutableDictionary *prevTaskDict = [rootDict objectForKey:MGSTaskDictTasksKey];
		if (prevTaskDict) {
			// update prev dict
			[prevTaskDict addEntriesFromDictionary:taskDict];
			taskDict = prevTaskDict;
		}
	} 
	
	// save task dict
	[rootDict setObject:taskDict forKey:MGSTaskDictTasksKey];
	
	// save root
	NSString *path = [self localScriptPropertiesPath];
	BOOL saved = [rootDict writeToFile:path atomically:YES];
	if (!saved) {
		MLog(RELEASELOG, @"could not write local task dict: %@", path);
	}
	
	return saved;
}

@end
