//
//  MGSNotifications.h
//  Mother
//
//  Created by Jonathan on 07/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// notification names
extern NSString *MGSNoteConnectionLimitExceeded;
extern NSString *MGSNoteAppRunModeChanged;
extern NSString *MGSNoteAppRunModeShouldChange;

extern NSString *MGSNoteWindowEditModeChangeRequest;
extern NSString *MGSNoteWindowEditModeDidChange;
extern NSString *MGSNoteWindowEditModeShouldChange;
extern NSString *MGSNoteWindowScriptCompilationStateDidChange;
extern NSString *MGSNoteWindowCanExecuteScriptStateDidChange;
extern NSString *MGSNoteViewConfigChangeRequest;
extern NSString *MGSNoteViewConfigDidChange;
extern NSString *MGSNoteResultViewModeChanged;
extern NSString *MGSNoteActionSelectionChanged;
extern NSString *MGSNoteCreateNewTask;
extern NSString *MGSNoteDeleteSelectedTask;
extern NSString *MGSNoteEditSelectedTask;
extern NSString *MGSNoteActionSaved;
extern NSString *MGSNoteRefreshAction;
extern NSString *MGSNoteDuplicateSelectedTask;
extern NSString *MGSNoteClientAvailable;
extern NSString *MGSNoteClientUnavailable;
extern NSString *MGSNoteClientSelected;
extern NSString *MGSNoteClientItemSelected;
extern NSString *MGSNoteClientClickDuringEdit;
extern NSString *MGSNoteBuildScript;
extern NSString *MGSNoteShowDictionary;
extern NSString *MGSNoteShouldAuthenticateAccess;	// should authenticate  access
extern NSString *MGSNoteAuthenticateAccessSucceeded;	// authenticate access succeeded
extern NSString *MGSNoteOpenTaskInWindow;	// open action in window
extern NSString *MGSNoteOpenTaskInNewTab;
extern NSString *MGSNoteExecuteSelectedTask;
extern NSString *MGSNoteStopSelectedTask;
extern NSString *MGSNoteResumeSelectedTask;
extern NSString *MGSNoteSuspendSelectedTask;
extern NSString *MGSNoteEditWindowUpdateModel;
extern NSString *MGSNoteActionInputModified;
extern NSString *MGSNoteOpenResultInWindow;	
extern NSString *MGSNoteClientSaveSucceeded;
extern NSString *MGSNoteInitialiseAction;
extern NSString *MGSNoteWindowSizeModeChanged;
extern NSString *MGSNoteScriptScheduledForDelete;
extern NSString *MGSNoteClientScriptUUIDKey;
extern NSString *MGSNoteAppToggleExecutePauseTask;
extern NSString *MGSNoteAppToggleExecuteTerminateTask;
extern NSString *MGSNoteAppTerminateTask;
extern NSString *MGSNoteWillUndoConfigurationChanges;
extern NSString *MGSNoteClientScriptArrayKey;
extern NSString *MGSNoteClientActive;

extern NSString *MGSShowTaskTabContextMenu;

extern NSString *MGSNoteLogout;
extern NSString *MGSNoteAuthenticationDialogWillDisplay;

extern NSString *MGSNoteSearchFilterChanged;
extern NSString *MGSNoteMainBrowserModeChanged;

extern NSString *MGSNoteScriptTextChanged;
extern NSString *MGSNoteViewModelEdited;

// user info keys
extern NSString *MGSNoteBoolStateKey;
extern NSString *MGSNoteModeKey;
extern NSString *MGSNotePrevModeKey;
extern NSString *MGSNoteViewConfigKey;
extern NSString *MGSNoteViewStateKey;
extern NSString *MGSActionKey;
extern NSString *MGSNoteClientNameKey;
extern NSString *MGSNoteNetClientKey;
extern NSString *MGSNoteValueKey;
extern NSString *MGSNoteLocationKey;
extern NSString *MGSNoteClientGroupKey;
extern NSString *MGSNoteClientItemKey;
extern NSString *MGSNoteClientScriptKey;
extern NSString *MGSNoteRunKey;

extern NSString *MGSNoteOpenSourceFile;

extern NSString *MGSNoteGroupIconWindowItemSelected;
extern NSString *MGSNoteGroupIconSelected;

