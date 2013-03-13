//
//  MGSScriptPlist.m
//  Mother
//
//  Created by Jonathan on 31/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSScriptPlist.h"

NSString *MGSScriptPlistExt = @"kosmictask";
NSString *MGSScriptIdentifier = @"com.mugginsoft.kosmictask";

// this key marks the KosmicTask section of a MGSNetMessage dictionary
NSString *MGSScriptKeyKosmicTask = @"KosmicTask";

// the command key is passed as an item in the MotherScript detailed above
// command key and values
NSString *MGSScriptKeyCommand = @"Command";			// identifies a command
NSString *MGSScriptKeyCommandParamaters = @"CommandParameters";			// identifies a commands parameter array
NSString *MGSScriptKeyCommandDictionary = @"CommandDictionary";			// identifies a commands dictionary

NSString *MGSScriptCommandListPublished = @"List Published";			// command host to provide list of published scripts
NSString *MGSScriptCommandListAll = @"List All";						// command host to provide list of all available scripts

NSString *MGSScriptCommandExecuteScript = @"Execute Script";			// command host to execute a given script
NSString *MGSScriptCommandBuildScript = @"Compile Script";              // command to compile script

NSString *MGSScriptCommandLogMesgUUID = @"Log MesgUUID";            // command to log request with given Message UUID

NSString *MGSScriptCommandTerminateMessageUUID = @"Terminate MesgUUID";		// command host to terminate a given Message UUID
NSString *MGSScriptCommandSuspendMessageUUID = @"Suspend MesgUUID";			// command host to suspend a given Message UUID
NSString *MGSScriptCommandResumeMessageUUID = @"Resume MesgUUID";			// command host to resume a given Message UUID

NSString *MGSScriptCommandGetScriptUUID = @"Get ScriptUUID";				// command host to get script for a given Script UUID
NSString *MGSScriptCommandGetScriptUUIDCompiledSource = @"Get ScriptUUID CompiledSource";		// command host to return compiled source for a given Script UUID

NSString *MGSScriptCommandSaveChangesAndPublish = @"Save ChangesAndPublish";		// command host to save changes and publish
NSString *MGSScriptCommandSaveEdits = @"Save Edits";		// command host to save edits
NSString *MGSScriptCommandSearch = @"Search";				// command host to search

// script keys
NSString *MGSScriptKeyScript = @"Script";	// marks an individual script
NSString *MGSScriptKeyCompiledScript = @"CompiledScript";	// marks a compiled script
NSString *MGSScriptKeyCompiledScriptDataFormat = @"CompiledScriptDF";	// marks a compiled script data format
NSString *MGSScriptKeyCompiledScriptSourceRTF = @"CompiledSourceRTF";	// marks a compiled script source
NSString *MGSScriptKeyScriptSource = @"Source";	// script source
NSString *MGSScriptKeyBoolResult = @"BoolResult";	// a bool result
NSString *MGSScriptKeyScriptCompilationError = @"ScriptCompilationError";

// these keys are saved in the application scripts plist.
NSString *MGSScriptKeyScripts = @"Scripts";             // mark scripts array in dictionary
NSString *MGSScriptKeyCapabilities = @"Capabilities";   // mark capabilities dict in dictionary

// keys to define an individual script
NSString *MGSScriptKeyIdentifier = @"Identifier";
NSString *MGSScriptKeyFileVersion = @"FileVersion";
NSString *MGSScriptKeyDescription = @"Description";
NSString *MGSScriptKeyGroup = @"Group";
NSString *MGSScriptKeyCompiled = @"Compiled";
NSString *MGSScriptKeyCompiledFormat = @"CompiledFormat";
NSString *MGSScriptKeySourceRTFData = @"SourceRTFData";
NSString *MGSScriptKeySource = @"Source";
NSString *MGSScriptKeyPublished = @"Published";
NSString *MGSScriptKeyProhibitSuspend = @"ProhibitSuspend";
NSString *MGSScriptKeyProhibitTerminate = @"ProhibitTerminate";
NSString *MGSScriptKeyName = @"Name";
NSString *MGSScriptKeyParameters = @"Parameters";
NSString *MGSScriptKeyCode = @"Code";
NSString *MGSScriptKeyDefault = @"Default";
NSString *MGSScriptKeyValue = @"Value";
NSString *MGSScriptKeyUUID = @"UUID";
NSString *MGSScriptKeyScriptUUID = @"UUID";		// script file is identified by its UUID
NSString *MGSScriptKeyScriptVersionID = @"VersionID";		// script file version ID
NSString *MGSScriptKeyAuthor = @"Author";
NSString *MGSScriptKeyAuthorNote = @"AuthorNote";
NSString *MGSScriptKeyCreated = @"Created"; 
NSString *MGSScriptKeyModified = @"Modified";
NSString *MGSScriptKeyModifiedAuto = @"ModifiedAuto";
NSString *MGSScriptKeyLongDescription = @"LongDescription";
NSString *MGSScriptKeyVersionMajor = @"VersionMajor";
NSString *MGSScriptKeyVersionMinor = @"VersionMinor";
NSString *MGSScriptKeyVersionRevision = @"VersionRevision";
NSString *MGSScriptKeyVersionRevisionAuto = @"VersionRevisionAuto";
NSString *MGSScriptKeyStatus = @"Status";
NSString *MGSScriptKeySubroutine = @"Subroutine";
NSString *MGSScriptKeyRunClass = @"RunClass";
NSString *MGSScriptKeyOnRun = @"OnRun";
NSString *MGSScriptKeyScriptType = @"ScriptType";
NSString *MGSScriptKeyUserInteractionMode = @"UserInteractionMode";
NSString *MGSScriptKeyTimeout = @"Timeout";
NSString *MGSScriptKeyTimeoutUnits = @"TimeoutUnits";
NSString *MGSScriptKeyApplyTimeout = @"ApplyTimeout";
NSString *MGSScriptKeyBundled = @"Bundled";
NSString *MGSScriptKeyLabelIndex = @"LabelIndex";
NSString *MGSScriptKeyRatingIndex = @"RatingIndex";
NSString *MGSScriptKeyRepresentation = @"Representation";
NSString *MGSScriptKeyOrigin = @"Origin";
NSString *MGSScriptKeyExternalBuildPath = @"BuildPath";
NSString *MGSScriptKeyBuildOptions = @"BuildOptions";
NSString *MGSScriptKeyExternalExecutorPath = @"ExecutorPath";
NSString *MGSScriptKeyExecutorOptions = @"ExecutorOptions";
NSString *MGSScriptInputArgumentName = @"InputArgumentName";
NSString *MGSScriptInputArgumentCase = @"InputArgumentCase";
NSString *MGSScriptInputArgumentStyle = @"InputArgumentStyle";
NSString *MGSScriptInputArgumentPrefix = @"InputArgumentPrefix";
NSString *MGSScriptInputArgumentNameExclusions = @"InputArgumentNameExclusions";

// change scheduling
NSString *MGSScriptKeyScheduleForDeletion = @"ScheduleForDeletion";		// delete script on save
NSString *MGSScriptKeyScheduleForSave = @"ScheduleForSave";				// script needs to be saved
NSString *MGSScriptKeySchedulePublished = @"SchedulePublished";				// script schedlued for published state change

// subroutine names
NSString *MGSScriptSubroutineDefault = @"kosmicTask";
NSString *MGSScriptSubroutineRun = @"run";

// script parameter types
NSString *MGSScriptKeyClassName = @"ClassName";
NSString *MGSScriptKeyClassInfo = @"ClassInfo";
NSString *MGSScriptKeySendAsAttachment = @"SendAsAttachment";
NSString *MGSScriptKeyAttachmentIndex = @"AttachmentIndex";
NSString *MGSScriptKeyType = @"Type";
NSString *MGSScriptTypeInteger = @"Integer";
NSString *MGSScriptTypeString = @"String";
NSString *MGSScriptTypeDouble = @"Double";
NSString *MGSScriptTypeData = @"Data";

// error keys
NSString *MGSScriptKeyNSErrorDict = @"NSErrorDict";
NSString *MGSScriptKeyStdError = @"StdErr";

// script task keys
NSString *MGSScriptKeyResult = @"Result";
NSString *MGSScriptKeyResultObject = @"ResultObject";
NSString *MGSScriptKeyResultScript = @"ResultScript";


// script search keys
NSString *MGSScriptKeySearchQuery = @"SearchQuery";
NSString *MGSScriptKeySearchScope = @"SearchScope";
NSString *MGSScriptKeySearchID = @"SearchID";
NSString *MGSScriptKeySearchResult = @"SearchResult";
NSString *MGSScriptKeyMatchCount = @"MatchCount";

// script search values
NSString *MGSScriptSearchScopeContent = @"Content";
NSString *MGSScriptSearchScopeScript = @"Script";

// script data format
NSString *MGSScriptDataFormatRaw = @"raw";
NSString *MGSScriptDataFormatTarBzip2 = @"tar-bzip2";

