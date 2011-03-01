//
//  MGSNotifications.m
//  Mother
//
//  Created by Jonathan on 07/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSNotifications.h"

// licensing
NSString *MGSNoteConnectionLimitExceeded = @"MGSNoteConnectionLimitExceeded";	// connection limit exceeded

//toolbar
NSString *MGSNoteAppRunModeChanged = @"MGSActionRunModeChanged";	// action run mode changes between Run and Configure
NSString *MGSNoteAppRunModeShouldChange = @"MGSNoteAppRunModeShouldChange";

NSString *MGSNoteShouldAuthenticateAccess = @"MGSShouldAuthenticateAccess";	// authenticate  access
NSString *MGSNoteAuthenticateAccessSucceeded = @"MGSAuthenticateAccessSucceeded";	// authenticate access succeeded

NSString *MGSNoteClientSaveSucceeded = @"MGSClientSaveSucceeded";	// client save succeeded

NSString *MGSNoteLogout = @"MGSLogOut";	// log user out 

NSString *MGSNoteWindowEditModeChangeRequest = @"MGSWindowEditModeChangeRequest";	// window edit mode change request
NSString *MGSNoteWindowEditModeDidChange = @"MGSWindowEditModeDidChange";	// window edit mode did change
NSString *MGSNoteWindowEditModeShouldChange = @"MGSWindowEditModeShouldChange";		// request to change window edit mode
NSString *MGSNoteWindowScriptCompilationStateDidChange = @"MGSNoteWindowScriptCompilationStateDidChange";	// window script compilation state did change
NSString *MGSNoteWindowCanExecuteScriptStateDidChange = @"MGSNoteWindowCanExecuteScriptStateDidChange";	// window script execute without build state did change
NSString *MGSNoteWindowSizeModeChanged = @"MGSWindowSizeModeChanged";

// toolbar
NSString *MGSNoteViewConfigChangeRequest = @"MGSNoteViewConfigChangeRequest";	// request change views visible - sidebar, browser, history
NSString *MGSNoteViewConfigDidChange = @"MGSNoteViewConfigDidChange";	// did change views visible - sidebar, browser, history
NSString *MGSNoteBuildScript = @"MGSBuildScript";
NSString *MGSNoteShowDictionary = @"MGSShowDictionary";

// mother window
NSString *MGSNoteActionSelectionChanged = @"MGSActionSelectionChanged";					// action selection has changed

// edit window
NSString *MGSNoteScriptTextChanged = @"MGSScriptTextChanged";
NSString *MGSNoteEditWindowUpdateModel = @"MGSEditWindowUpdateModel";
NSString *MGSNoteActionSaved = @"MGSNoteActionSaved";

// authentication
NSString *MGSNoteAuthenticationDialogWillDisplay = @"MGSAuthenticationDialogWillDisplay";

// any view
NSString *MGSNoteViewModelEdited = @"MGSViewModelEdited";	// view model has been edited

// task toolbar
NSString *MGSNoteCreateNewTask = @"MGSCreateNewTask";
NSString *MGSNoteDeleteSelectedTask = @"MGSDeleteSelectedTask";
NSString *MGSNoteScriptScheduledForDelete = @"MGSNoteScriptScheduledForDelete";
NSString *MGSNoteEditSelectedTask = @"MGSEditSelectedTask";
NSString *MGSNoteOpenTaskInWindow = @"MGSOpenTaskInWindow";
NSString *MGSNoteDuplicateSelectedTask = @"MGSDuplicateSelectedTask";
NSString *MGSNoteWillUndoConfigurationChanges = @"MGSNoteWillUndoConfigurationChanges";

// top level script notifications
NSString *MGSNoteAppToggleExecutePauseTask = @"MGSAppToggleExecutePauseTask";
NSString *MGSNoteAppToggleExecuteTerminateTask = @"MGSAppToggleExecuteTerminatePauseTask";
NSString *MGSNoteAppTerminateTask = @"MGSAppTerminateExecuteTask";

// display toolbar
NSString *MGSNoteExecuteSelectedTask = @"MGSExecuteSelectedTask";
NSString *MGSNoteStopSelectedTask = @"MGSStopSelectedTask";
NSString *MGSNoteSuspendSelectedTask = @"MGSSuspendSelectedTask";
NSString *MGSNoteResumeSelectedTask = @"MGSResumeSelectedTask";

// search toolbar item
NSString *MGSNoteSearchFilterChanged = @"MGSSearchFilterChanged";
NSString *MGSNoteMainBrowserModeChanged = @"MGSMainBrowserModeChanged";

// context menu
NSString *MGSShowTaskTabContextMenu = @"MGSShowTaskTabContextMenu";

// parameter subview
NSString *MGSNoteActionInputModified = @"MGSActionInputModified";

// results
NSString *MGSNoteOpenResultInWindow = @"MGSOpenResultInWindow";
NSString *MGSNoteResultViewModeChanged = @"MGSResultViewModeChanged";	

// client browser
NSString *MGSNoteClientAvailable = @"MGSNetClientAvailable"; 
NSString *MGSNoteClientUnavailable = @"MGSNetClientUnavailable";
NSString *MGSNoteClientSelected = @"MGSNetClientSelected";
NSString *MGSNoteClientClickDuringEdit = @"MGSNetClientClickDuringEdit";
NSString *MGSNoteClientItemSelected = @"MGSNoteClientItemSelected";

// input request view
NSString *MGSNoteInitialiseAction = @"MGSNoteInitialiseAction";
NSString *MGSNoteRefreshAction = @"MGSNoteRefreshAction";

// open panel
NSString *MGSNoteOpenSourceFile = @"MGSNoteOpenSourceFile";

// user info keys
NSString *MGSNoteBoolStateKey = @"BoolState";
NSString *MGSNoteModeKey = @"Mode";
NSString *MGSNotePrevModeKey = @"PrevMode";
NSString *MGSNoteViewConfigKey = @"ViewConfig";
NSString *MGSNoteViewStateKey = @"ViewState";
NSString *MGSActionKey = @"Action";
NSString *MGSNoteClientNameKey = @"ClientName";
NSString *MGSNoteNetClientKey = @"NetClient";
NSString *MGSNoteValueKey = @"Value";
NSString *MGSNoteLocationKey = @"Location";
NSString *MGSNoteClientGroupKey = @"ClientGroup";
NSString *MGSNoteClientItemKey = @"ClientItem";
NSString *MGSNoteClientScriptKey = @"ClientScript";
NSString *MGSNoteClientScriptArrayKey = @"ClientScriptArray";
NSString *MGSNoteClientScriptUUIDKey = @"ClientScriptUUID";
NSString *MGSNoteRunKey = @"Run";

//NSString *MGSNoteShowBoolKey = @"ShowBool";

// group icons window
NSString *MGSNoteGroupIconWindowItemSelected = @"MGSNoteGroupIconWindowItemSelected";
NSString *MGSNoteGroupIconSelected = @"MGSNoteGroupIconSelected";
