//
//  MGSPreferences.m
//  Mother
//
//  Created by Jonathan on 28/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
//
// NSUserDefaults use the bundle to determine the Application ID.
// Mother server and task may not have acces to the main bundle ID hence
// this class.
//
// Plist CF types are toll free bridged to their NS counterparts.
//

#import "MGSMother.h"
#import "MGSMotherServer.h"
#import "MGSPreferences.h"
#import "NSObject_Mugginsoft.h"

// preference strings
NSString *MGSEnableServerSSLSecurity = @"MGSEnableServerSSLSecurity";
NSString *MGSUsernameDisclosureMode = @"MGSUsernameDisclosureMode";
NSString *MGSDebugLoggingEnabled = @"MGSUsernameDisclosureMode";
NSString *MGSEnableCoreDumps = @"MGSEnableCoreDumps";
NSString *MGSEnableDebugLogging = @"MGSEnableDebugLogging";
NSString *MGSEnableExceptionPanel = @"MGSEnableExceptionPanel";
NSString *MGSAllowEditApplicationTasks = @"MGSAllowEditApplicationTasks";
NSString *MGSEnableLoggingToConsoleOnly = @"MGSEnableLoggingToConsoleOnly";
NSString *MGSTaskResultDisplayLocked = @"MGSTaskResultDisplayLocked";
NSString *MGSExternalPortNumber = @"MGSExternalPortNumber";
NSString *MGSAllowInternetAccess = @"MGSAllowInternetAccess";
NSString *MGSAllowLocalAccess = @"MGSAllowLocalAccess";
NSString *MGSAllowLocalUsersToAuthenticate = @"MGSAllowLocalUsersToAuthenticate";
NSString *MGSAllowRemoteUsersToAuthenticate = @"MGSAllowRemoteUsersToAuthenticate";
NSString *MGSEnableInternetAccessAtLogin = @"MGSEnableInternetAccessAtLogin";
NSString *MGSDisplayGroupListWhenSidebarHidden = @"MGSDisplayGroupListWhenSidebarHidden";
NSString *MGSDeferRemoteClientConnections = @"MGSDeferRemoteClientConnections";
NSString *MGSRemoteClientConnectionDelay = @"MGSRemoteClientConnectionDelay";
NSString *MGSTaskAuthorName = @"MGSTaskAuthorName";
NSString *MGSDeferredClientConnectionTimeout = @"MGSDeferredClientConnectionTimeout";
NSString *MGSTaskHistoryCapacity = @"MGSTaskHistoryCapacity";
NSString *MGSModClickOpensNewWindow = @"MGSModClickOpensNewWindow";
NSString *MGSModClickOpensNewTab = @"MGSModClickOpensNewTab";
NSString *MGSConfirmClosingMultipleTabsOrWindows = @"MGSConfirmClosingMultipleTabsOrWindows";
NSString *MGSNewTabKeepTaskDisplayed = @"MGSNewTabKeepTaskDisplayed";
NSString *MGSAppleScriptParameterPrefix = @"MGSAppleScriptParameterPrefix";
NSString *MGSAppleScriptParameterSuffix = @"MGSAppleScriptParameterSuffix";
NSString *MGSMaxLogEntryLength = @"MGSMaxLogEntryLength";
NSString *MGSDefaultScriptType = @"MGSDefaultScriptType";
NSString *MGSWindowResourceBrowserOutlineSplitViewFrames = @"MGSWindowResourceBrowserOutlineSplitViewFrames";
NSString *MGSWindowResourceBrowserTableSplitViewFrames = @"MGSWindowResourceBrowserTableSplitViewFrames";
NSString *MGSSheetResourceBrowserOutlineSplitViewFrames = @"MGSSheetResourceBrowserOutlineSplitViewFrames";
NSString *MGSSheetResourceBrowserTableSplitViewFrames = @"MGSSheetResourceBrowserTableSplitViewFrames";
NSString *MGSAllowEditApplicationResources = @"MGSAllowEditApplicationResources";
NSString *MGSTaskBrowserMode = @"MGSTaskBrowserMode";
NSString *MGSTaskDetailMode = @"MGSTaskDetailMode";
NSString *MGSMainSidebarVisible = @"MGSMainSidebarVisible";
NSString *MGSTaskBrowserHeight = @"MGSTaskBrowserHeight";
NSString *MGSTaskDetailHeight = @"MGSTaskDetailHeight";
NSString *MGSMainGroupListVisible = @"MGSMainGroupListVisible";
NSString *MGSAnimateUI = @"MGSAnimateUI";
NSString *MGSKeepExecutedTasksDisplayed = @"MGSKeepExecutedTasksDisplayed";
NSString *MGSResultViewColor = @"MGSResultViewColor";
NSString *MGSResultViewFontName = @"MGSResultViewFontName";
NSString *MGSResultViewFontSize = @"MGSResultViewFontSize";
NSString *MGSUseSeparateNetworkThread = @"MGSUseSeparateNetworkThread";
NSString *MGSSendCocoaTaskCRashReports = @"MGSSendCocoaTaskCRashReports";

static CFStringRef appID = CFSTR("com.mugginsoft.kosmictask");

static MGSPreferences *_standardUserDefaults = nil;

@implementation MGSPreferences

/*
 
 standard user defaults
 
 */
+ (id)standardUserDefaults
{
	if (!_standardUserDefaults) {
		_standardUserDefaults = [[self alloc] init];
	}
	return _standardUserDefaults;
}

/*
 
 set object for key
 
 */
- (void)setObject:(id)object forKey:(NSString *)key
{
	// object must be a plist type
	if (![NSPropertyListSerialization propertyList:object isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
		MLog(DEBUGLOG, @"invalid plist object");
		return;
	}
	
	// Set up the preference.
	CFPreferencesSetValue((CFStringRef)key, object, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	//CFPreferencesSetAppValue((CFStringRef)key, object, appID);
	
	// sync to save
	//[self synchronize];
}

/*
 
 object for key
 
 */
- (id)objectForKey:(NSString *)key
{
	return [self objectForKey:key withPreSync:NO];
}

/*
 
 object for key with presync
 
 */
- (id)objectForKey:(NSString *)key withPreSync:(BOOL)preSync
{
	// if the defaults database is changed externally then a sync
	// must occur to refresh the preferences cache
	if (preSync) {
		[self synchronize];
	}
	
	CFPropertyListRef plistRef = CFPreferencesCopyValue ((CFStringRef)key, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	//CFPropertyListRef plistRef = CFPreferencesCopyAppValue ((CFStringRef)key, appID);
	
	return NSMakeCollectable(plistRef);
}

/*
 
 BOOL for key
 
 */
- (BOOL)boolForKey:(NSString *)key
{
	return [self boolForKey:key withPreSync:NO];
}

/*
 
 integer for key
 
 */
- (NSInteger)integerForKey:(NSString *)key
{
	id object = [self objectForKey:key withPreSync:NO];
	if (object) {
		return [object integerValue];
	}
	
	return 0;
}

/*
 
 BOOL for key with presync
 
 */
- (BOOL)boolForKey:(NSString *)key withPreSync:(BOOL)preSync
{
	id object = [self objectForKey:key withPreSync:preSync];
	if (object) {
		return [object boolValue];
	}
	
	return NO;
}

/*
 
 register default values to be shared between app and framework.
 unlike NSUserDefaults these defaults will be actually written out
 to the preference plist.
 
 */
- (void)registerDefaults
{
	// SSL 
	if (![self objectForKey: MGSEnableServerSSLSecurity]) {
		[self setObject:[NSNumber numberWithBool:NO] forKey:MGSEnableServerSSLSecurity];
	}
	
	// username disclosure
	if (![self objectForKey: MGSUsernameDisclosureMode]) {
		[self setObject:[NSNumber numberWithInteger:DISCLOSE_USERNAME_TO_NONE] forKey:MGSUsernameDisclosureMode];
	}

	// debug logging
	if (![self objectForKey: MGSEnableDebugLogging]) {
		[self setObject:[NSNumber numberWithBool:NO] forKey:MGSEnableDebugLogging];
	}

	// external port number
	if (![self objectForKey: MGSExternalPortNumber]) {
		[self setObject:[NSNumber numberWithInteger:MOTHER_IANA_REGISTERED_PORT] forKey:MGSExternalPortNumber];
	}

	// allow local access 
	if (![self objectForKey: MGSAllowLocalAccess]) {
		[self setObject:[NSNumber numberWithBool:YES] forKey:MGSAllowLocalAccess];
	}

    // allow internet access
	if (![self objectForKey: MGSAllowInternetAccess]) {
		[self setObject:[NSNumber numberWithBool:NO] forKey:MGSAllowInternetAccess];
	}

	// enable internet access at login
	if (![self objectForKey: MGSEnableInternetAccessAtLogin]) {
		[self setObject:[NSNumber numberWithBool:NO] forKey:MGSEnableInternetAccessAtLogin];
	}	

	// max log entry length
	if (![self objectForKey: MGSMaxLogEntryLength]) {
		[self setObject:[NSNumber numberWithInteger:MGS_MAX_LOG_ENTRY_LENGTH] forKey:MGSMaxLogEntryLength];
	}	

}

/*
 
 synchronize
 
 Write out the preference data and read in new.
 Once read data is cached so external changes will not be seen
 until another sync has occurred
 
 */
- (BOOL)synchronize
{
	//CFPreferencesAppSynchronize(appID);
	return CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}
@end
