//
//  MGSPreferences.h
//  Mother
//
//  Created by Jonathan on 28/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// disclosure modes
#define DISCLOSE_USERNAME_TO_NONE 0
#define DISCLOSE_USERNAME_TO_LOCAL 1
#define DISCLOSE_USERNAME_TO_ALL 2

#define MGS_MAX_LOG_ENTRY_LENGTH 5000

extern NSString *MGSEnableServerSSLSecurity;
extern NSString *MGSUsernameDisclosureMode;
extern NSString *MGSEnableCoreDumps;
extern NSString *MGSEnableDebugLogging;
extern NSString *MGSEnableLoggingToConsoleOnly;
extern NSString *MGSEnableExceptionPanel;
extern NSString *MGSExternalPortNumber;
extern NSString *MGSAllowInternetAccess;
extern NSString *MGSAllowLocalAccess;
extern NSString *MGSEnableInternetAccessAtLogin;
extern NSString *MGSTaskResultDisplayLocked;
extern NSString *MGSDisplayGroupListWhenSidebarHidden;
extern NSString *MGSDeferRemoteClientConnections;
extern NSString *MGSRemoteClientConnectionDelay;
extern NSString *MGSDeferredClientConnectionTimeout;
extern NSString *MGSAllowEditApplicationTasks;
extern NSString *MGSTaskAuthorName;
extern NSString *MGSTaskHistoryCapacity ;
extern NSString *MGSModClickOpensNewWindow;
extern NSString *MGSModClickOpensNewTab;
extern NSString *MGSConfirmClosingMultipleTabsOrWindows;
extern NSString *MGSNewTabKeepTaskDisplayed;
extern NSString *MGSAppleScriptParameterPrefix;
extern NSString *MGSAppleScriptParameterSuffix;
extern NSString *MGSMaxLogEntryLength;
extern NSString *MGSDefaultScriptType;
extern NSString *MGSWindowResourceBrowserOutlineSplitViewFrames;
extern NSString *MGSWindowResourceBrowserTableSplitViewFrames;
extern NSString *MGSSheetResourceBrowserOutlineSplitViewFrames;
extern NSString *MGSSheetResourceBrowserTableSplitViewFrames;
extern NSString *MGSAllowEditApplicationResources;
extern NSString *MGSTaskBrowserMode;
extern NSString *MGSTaskDetailMode;
extern NSString *MGSTaskBrowserHeight;
extern NSString *MGSTaskDetailHeight;
extern NSString *MGSMainSidebarVisible;
extern NSString *MGSMainGroupListVisible;
extern NSString *MGSAnimateUI;
extern NSString *MGSKeepExecutedTasksDisplayed;
extern NSString *MGSResultViewColor;
extern NSString *MGSResultViewFontName;
extern NSString *MGSResultViewFontSize;
extern NSString *MGSUseSeparateNetworkThread;
extern NSString *MGSSendCocoaTaskCRashReports;
extern NSString *MGSAllowLocalUsersToAuthenticate;
extern NSString *MGSAllowRemoteUsersToAuthenticate;
extern NSString *MGSRequestWriteConnectionTimeout;
extern NSString *MGSHeartbeatRequestTimeout;
extern NSString *MGSDefaultRequestTimeout;

@interface MGSPreferences : NSObject {

}

+ (id)standardUserDefaults;
- (void)setObject:(id)object forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
- (void)registerDefaults;
- (BOOL)synchronize;
- (id)objectForKey:(NSString *)key withPreSync:(BOOL)preSync;
- (BOOL)boolForKey:(NSString *)key withPreSync:(BOOL)preSync;
- (BOOL)boolForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
@end
