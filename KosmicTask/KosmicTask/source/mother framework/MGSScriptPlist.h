//
//  MGSScriptPlist.h
//  Mother
//
//  Created by Jonathan on 31/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum _MGSScriptUserModeInteraction {
	kMGSScriptUserModeCanInteractIfLocal    = 0,	
	kMGSScriptUserModeCanInteract           = 1,
	kMGSScriptUserModeNeverInteract         = 2,
};
typedef NSInteger MGSScriptUserModeInteraction;

extern NSString *MGSScriptIdentifier;
extern NSString *MGSScriptPlistExt;
extern NSString *MGSScriptPlistBundleIDExt;
extern NSString *MGSScriptKeyKosmicTask;
extern NSString *MGSScriptKeyCommand;
extern NSString *MGSScriptKeyCommandParamaters;
extern NSString *MGSScriptKeyCommandDictionary;
extern NSString *MGSScriptCommandListPublished;
extern NSString *MGSScriptCommandListAll;
extern NSString *MGSScriptCommandExecuteScript;
extern NSString *MGSScriptCommandTerminateMessageUUID;
extern NSString *MGSScriptCommandSuspendMessageUUID;
extern NSString *MGSScriptCommandResumeMessageUUID;
extern NSString *MGSScriptCommandLogMesgUUID;
extern NSString *MGSScriptCommandGetScriptUUID;
extern NSString *MGSScriptCommandGetScriptUUIDCompiledSource;
extern NSString *MGSScriptCommandSaveChangesAndPublish;
extern NSString *MGSScriptCommandBuildScript;
extern NSString *MGSScriptCommandSaveEdits;
extern NSString *MGSScriptCommandSearch;

extern NSString *MGSScriptKeyScript;
extern NSString *MGSScriptKeyCompiledScript;
extern NSString *MGSScriptKeyScriptSource;
extern NSString *MGSScriptKeyCompiledScriptSourceRTF;
extern NSString *MGSScriptKeyScriptCompilationError;
extern NSString *MGSScriptKeyBoolResult;
extern NSString *MGSScriptKeyCompiledScriptDataFormat;

// script plist keys
extern NSString *MGSScriptKeyScripts;
extern NSString *MGSScriptKeyCapabilities;
extern NSString *MGSScriptKeyDescription;
extern NSString *MGSScriptKeyGroup;

extern NSString *MGSScriptKeyIdentifier;
extern NSString *MGSScriptKeyFileVersion;
extern NSString *MGSScriptKeyName;
extern NSString *MGSScriptKeyParameters;
extern NSString *MGSScriptKeyDefault;
extern NSString *MGSScriptKeyValue;
extern NSString *MGSScriptKeyUUID;
extern NSString *MGSScriptKeyPublished;
extern NSString *MGSScriptKeyProhibitSuspend;
extern NSString *MGSScriptKeyProhibitTerminate;
extern NSString *MGSScriptKeyAuthor;
extern NSString *MGSScriptKeyAuthorNote;
extern NSString *MGSScriptKeyCreated;
extern NSString *MGSScriptKeyModified;
extern NSString *MGSScriptKeyModifiedAuto;
extern NSString *MGSScriptKeyLongDescription;
extern NSString *MGSScriptKeyCode;
extern NSString *MGSScriptKeyStatus;
extern NSString *MGSScriptKeySubroutine;
extern NSString *MGSScriptKeyRunClass;
extern NSString *MGSScriptKeyOnRun;
extern NSString *MGSScriptKeyScriptType;
extern NSString *MGSScriptKeyTimeout;
extern NSString *MGSScriptKeyTimeoutUnits;
extern NSString *MGSScriptKeyApplyTimeout;
extern NSString *MGSScriptKeyBundled;
extern NSString *MGSScriptKeyLabelIndex;
extern NSString *MGSScriptKeyRatingIndex;
extern NSString *MGSScriptKeyRepresentation;
extern NSString *MGSScriptKeyOrigin;
extern NSString *MGSScriptKeyExternalBuildPath;
extern NSString *MGSScriptKeyBuildOptions;
extern NSString *MGSScriptKeyExternalExecutorPath;
extern NSString *MGSScriptKeyExecutorOptions;
extern NSString *MGSScriptKeyVariableName;
extern NSString *MGSScriptKeyVariableStatus;
extern NSString *MGSScriptKeyVariableNameUpdating;

extern NSString *MGSScriptInputArgumentName;
extern NSString *MGSScriptInputArgumentCase;
extern NSString *MGSScriptInputArgumentStyle;
extern NSString *MGSScriptInputArgumentPrefix;
extern NSString *MGSScriptInputArgumentNameExclusions;

// user interaction modes
extern NSString *MGSScriptKeyUserInteractionMode;

// subroutine names
extern NSString *MGSScriptSubroutineDefault;
extern NSString *MGSScriptSubroutineRun;

// script code keys
extern NSString *MGSScriptKeyCompiled;
extern NSString *MGSScriptKeyCompiledFormat;
extern NSString *MGSScriptKeySourceRTFData;
extern NSString *MGSScriptKeySource;

extern NSString *MGSScriptKeyScriptUUID;
extern NSString *MGSScriptKeyScheduleForDeletion;
extern NSString *MGSScriptKeyScheduleForSave;
extern NSString *MGSScriptKeySchedulePublished;

extern NSString *MGSScriptKeyScriptVersionID;
extern NSString *MGSScriptKeyVersionMajor;
extern NSString *MGSScriptKeyVersionMinor;
extern NSString *MGSScriptKeyVersionRevision;
extern NSString *MGSScriptKeyVersionRevisionAuto;

// script parameter types
extern NSString *MGSScriptKeyClassName;
extern NSString *MGSScriptKeyClassInfo;
extern NSString *MGSScriptKeySendAsAttachment;
extern NSString *MGSScriptKeyAttachmentIndex;
extern NSString *MGSScriptKeyType;
extern NSString *MGSScriptTypeInteger;
extern NSString *MGSScriptTypeString;
extern NSString *MGSScriptTypeDouble;
extern NSString *MGSScriptTypeData;

// error keys
extern NSString *MGSScriptKeyNSErrorDict;
extern NSString *MGSScriptKeyStdError;

// script task return keys
extern NSString *MGSScriptKeyResult;
extern NSString *MGSScriptKeyResultObject;
extern NSString *MGSScriptKeyResultScript;

// search keys
extern NSString *MGSScriptKeySearchQuery;
extern NSString *MGSScriptKeySearchScope;
extern NSString *MGSScriptKeySearchID;
extern NSString *MGSScriptKeySearchResult;
extern NSString *MGSScriptKeyMatchCount;

// search values
extern NSString *MGSScriptSearchScopeContent;
extern NSString *MGSScriptSearchScopeScript;

// script data format
extern NSString *MGSScriptDataFormatRaw;
extern NSString *MGSScriptDataFormatTarBzip2;
