//
//  MGSScriptEditViewController.m
//  Mother
//
//  Created by Jonathan on 08/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSScriptEditViewController.h"
#import "MGSScriptViewController.h"
#import "NSView_Mugginsoft.h"
#import "MGSTaskSpecifier.h"
#import "MGSMotherModes.h"
#import "MGSClientRequestManager.h"
#import "MGSNotifications.h"
#import "MGSScript.h"
#import "MGSScriptCode.h"
#import "MGSScriptPList.h"
#import "MGSNetClient.h"
#import <OSAKit/OSAKit.h>
#import "MGSApplesScriptDictWindowController.h"
#import "MGSError.h"
#import "MGSNetRequestPayload.h"
#import "NSSplitView_Mugginsoft.h"
#import "MGSBuildTaskSheetController.h"
#import "MGSLanguagePlugin.h"
#import "MGSResourceBrowserWindowController.h"
#import "MGSSettingsOutlineViewController.h"
#import "MGSLanguagePluginController.h"
#import "MGSEditWindowController.h"
#import "NSMutableAttributedString+Mugginsoft.h"

#define MIN_TOP_SPLITVIEW_HEIGHT 200
#define MIN_BOTTOM_SPLITVIEW_HEIGHT 50

#define MGS_SCRIPT_EDITOR 0
#define MGS_SETTINGS_EDITOR 1

//#define MGS_DEBUG_CONTROLLER
char MGSScriptOnRunContext;

NSString * const MGSIgnoreBuildError = @"MGSIgnoreBuildError";

const char MGSErrorCheckboxContext;
const char MGSScriptTypeContext;
const char MGSSettingsEditedContext;
const char MGSScriptLanguagePropertyManagerContext;
const char MGSSettingsEditedLanguagePropertyContext;

@interface OSADictionary: NSObject
+ (void)chooseDictionary;
@end

// class extension
@interface MGSScriptEditViewController()
- (void)buildTaskScript:(NSNotification *)notification;
- (void)showDictionary:(NSNotification *)notification;
- (void)scriptTextChanged:(NSNotification *)notification;
- (void)setConsoleText:(NSString *)text append:(BOOL)append options:(NSDictionary *)options;
- (void)updateLanguageDependentBuildFlags;
- (void)requestBuild;
- (void)disconnectedAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void)buildTaskSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void)updateCanExecuteScript;
- (NSWindow *)windowOrPending;

@property NSInteger buildStatusFlags;
@property (copy) NSString *buildStatus;

@property BOOL canExecuteScript;
@property BOOL scriptBuilt;
@property BOOL languageRequiresBuild;
@property BOOL languageSupportsBuild;
@property BOOL canBuildScript;

@end


@implementation MGSScriptEditViewController

@synthesize taskSpec = _taskSpec;
@synthesize scriptBuilt;
@synthesize pendingWindow = _pendingWindow;
@synthesize buildConsoleResult = _buildConsoleResult;
@synthesize scriptViewController, buildStatusFlags, buildResultIndex, buildSheetMessage, buildStderrResult, 
buildResult, buildStatus, languageRequiresBuild, canExecuteScript, canBuildScript, languageSupportsBuild;

#pragma mark -
#pragma mark Instance methods
/*
 
 init
 
 */
- (id)init
{
	_nibLoaded = NO;
	return [super initWithNibName:@"ScriptEditView" bundle:nil];	// load another nib
	
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{	
	if (_nibLoaded) {
		return;
	}
	
	_pendingWindow = nil;
	scriptBuilt = NO;
	languageRequiresBuild = NO;
	canExecuteScript = NO;
	_nibLoaded = YES;
	buildResultIndex = MGS_BUILD_RESULT_INDEX_CONSOLE;
	canBuildScript = NO;
	buildStatus = MGS_BUILD_PENDING;
	requestExecuteOnSuccessfulBuild = NO;

	// load script view controller
	scriptViewController = [[MGSScriptViewController alloc] init];
	scriptViewController.delegate = self;
	
	// load settings outline view controller
	settingsOutlineViewController = [[MGSSettingsOutlineViewController alloc] init];
	settingsOutlineViewController.delegate = self;
	[settingsOutlineViewController view];	// trigger load
	
	NSView *subview = [[splitView subviews] objectAtIndex:0];
	[splitView replaceSubview:subview withViewSizedAsOld:[scriptViewController view]];
	
	subview = [[splitView subviews] objectAtIndex:1];
	[splitView replaceSubview:subview withViewSizedAsOld:buildResultView];

	[scriptViewController setEditMode:kMGSMotherRunModeConfigure];
	
	// add observers
	[settingsOutlineViewController addObserver:self forKeyPath:@"documentEdited" options:NSKeyValueObservingOptionNew context:(void *)&MGSSettingsEditedContext];
	[settingsOutlineViewController addObserver:self forKeyPath:@"editedLanguageProperty" options:NSKeyValueObservingOptionNew context:(void *)&MGSSettingsEditedLanguagePropertyContext];

	// register for notifications 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buildTaskScript:) name:MGSNoteBuildScript object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDictionary:) name:MGSNoteShowDictionary object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptTextChanged:) name:MGSNoteScriptTextChanged object:nil];

	// bind script type content values
	[scriptType bind:@"contentValues" toObject:self withKeyPath:@"taskSpec.script.scriptTypes" options:nil];
	[scriptType bind:NSSelectedValueBinding toObject:self withKeyPath:@"taskSpec.script.scriptType" options:nil];
	
	// bind build result segment 
	[buildResultSegment bind:NSSelectedIndexBinding toObject:self withKeyPath:@"buildResultIndex" options:nil];
	if ([buildResultSegment segmentCount] > 1) {
        [buildResultSegment setSegmentCount:1];
    }
	// bind build status field
	[buildStatusTextField bind:NSValueBinding toObject:self withKeyPath:@"buildStatus" options:nil];
	 
	// prepare the console text view
	NSFont *consoleFont = [NSFont fontWithName:@"Menlo" size: 11];
	consoleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSColor blackColor], NSForegroundColorAttributeName,
								consoleFont, NSFontAttributeName, nil];
	
	// console error options
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSColor redColor], NSForegroundColorAttributeName,
								nil];
	consoleErrorOptions = [NSDictionary dictionaryWithObjectsAndKeys:
										attributes, @"attributes",
										nil].mutableCopy;

	// console text options
	attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSColor blueColor], NSForegroundColorAttributeName,
								nil];
	consoleTextOptions = [NSDictionary dictionaryWithObjectsAndKeys:
												attributes, @"attributes",
												nil].mutableCopy;

	// console success options
	attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSColor blackColor], NSForegroundColorAttributeName,
								nil];
	consoleSuccessOptions = [NSDictionary dictionaryWithObjectsAndKeys:
											   attributes, @"attributes",
											   nil].mutableCopy;
    
    // initialsie the build result
    self.buildStderrResult = @"";
    
#ifdef MGS_DEBUG_CONTROLLER
    NSLog(@"%@ Preprocessor DEBUG defined.", [self className]);
#endif
}


#pragma mark -
#pragma mark MGSScriptViewController delegate
/*
 
 - scriptViewLoaded
 
 */
- (void)scriptViewLoaded:(MGSScriptViewController *)aScriptViewController
{
	#pragma unused(aScriptViewController)
	
	[scriptViewController setEditable:YES];
}

#pragma mark -
#pragma mark Undo management 
/*
 
 - undoManager
 */
- (NSUndoManager *)undoManager {
	return [scriptViewController undoManager];
}

#pragma mark -
#pragma mark KVO 
/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
	
	if (context == &MGSErrorCheckboxContext) {
		
		BOOL ignoreErrors = [_buildTaskSheetController buildWarningsCheckBoxState];
		self.scriptBuilt = ignoreErrors;
		
	} else if (context == &MGSScriptTypeContext) {
		
		// clear any existing compiled data that exists
		[[[_taskSpec script] scriptCode] setCompiledData:nil withFormat:nil];

        // update build flags that depend on the language type
		[self updateLanguageDependentBuildFlags];
		
		self.scriptBuilt = NO;
        
        // initialise the build result
        self.buildStderrResult = @"";
        self.buildConsoleResult = @"";
        self.buildResultIndex = MGS_BUILD_RESULT_INDEX_CONSOLE;
		
		// update language property manager for settings outline controller
		//settingsOutlineViewController.languagePropertyManager = [_taskSpec.script languagePropertyManager];

	} else if (context == &MGSSettingsEditedContext) {
		
		[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewModelEdited object:[[self view] window] userInfo:nil];
	
	} else if (context == &MGSSettingsEditedLanguagePropertyContext) {
		
		// this language property has been edited
		MGSLanguageProperty *langProp = settingsOutlineViewController.editedLanguageProperty;
		
		// if property influences the build then we may need to rebuild
		if (langProp.requestType == kMGSBuildRequest) {
			self.scriptBuilt = NO;
		}
		
        // sync the script with the language properties
#warning This may be being perfomed automatically
        //[[_taskSpec script] syncScriptWithLanguageProperties];
        
	} else if (context == &MGSScriptLanguagePropertyManagerContext) {

        // script language property manager has been updated
		settingsOutlineViewController.languagePropertyManager = [_taskSpec.script languagePropertyManager];
		
	} else if (context == &MGSScriptOnRunContext) {
        onRunBehaviour.stringValue = [[_taskSpec script] onRunString];
    }
}


#pragma mark -
#pragma mark Property updating


/*
 
 - updateLanguageDependentBuildFlags
 
 */
- (void)updateLanguageDependentBuildFlags
{
	// build result flags indicate what build result request should contain
	MGSBuildResultFlags buildResultFlags = [[[_taskSpec script] languagePlugin] buildResultFlags];
	
	// if build contains compiled data then a build is required
	if (buildResultFlags & kMGSCompiledScript) {
		self.languageRequiresBuild = YES;
	} else {
		self.languageRequiresBuild = NO;
	}
	
	// determine if we can build without executing
	MGSLanguageProperty *langProp = [[[_taskSpec script] languagePropertyManager] propertyForKey:MGS_LP_CanBuild];
	self.languageSupportsBuild = [[langProp value] boolValue];
	
	self.buildStatusFlags = MGS_BUILD_PENDING;
}

/*
 
 - updateCanExecuteScript
 
 */
- (void)updateCanExecuteScript
{
	/*
	 
	 we can execute the script if:
	 
		the script does not require a build 
	 
	 or
	 
		the script has no fatal errors 
	 
	 */
	self.canExecuteScript = !self.languageRequiresBuild || self.scriptBuilt;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteWindowCanExecuteScriptStateDidChange object:[self windowOrPending] 
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:self.canExecuteScript], MGSNoteBoolStateKey, nil]];

}

/*
 
 - updateCanBuildScript
 
 */
- (void)updateCanBuildScript
{
	/*
	 
	 we can build the script if:
	 
		language supports build AND script not built
	 
	 */
	self.canBuildScript = self.languageSupportsBuild && !self.scriptBuilt;
	BOOL scriptCompiled = !self.canBuildScript;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteWindowScriptCompilationStateDidChange object:[self windowOrPending] 
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:scriptCompiled], MGSNoteBoolStateKey, nil]];
	
}

#pragma mark -
#pragma mark Accessors

/*
 
 - setTaskSpec
 
 */
- (void)setTaskSpec:(MGSTaskSpecifier *)aTaskSpec
{
	if (_taskSpec) {
		[_taskSpec removeObserver:self forKeyPath:@"script.scriptType"];
		[_taskSpec removeObserver:self forKeyPath:@"script.languagePropertyManager"];
        [_taskSpec removeObserver:self forKeyPath:@"script.onRun"];
	}
	
	_taskSpec = aTaskSpec;
	scriptViewController.taskSpec = _taskSpec;
	
	[self updateLanguageDependentBuildFlags];
	
	// if task is new then it will have a template set.
	// request compilation of this template
	if (_taskSpec.taskStatus == MGSTaskStatusNew) {
		self.scriptBuilt = NO;
		
	} else {
		self.scriptBuilt = YES;
	}
	
    // the outline displays the language property manager for the script.
    // the property manager and the script share properties that have to be kept in sync.
    // syncing at present is done manually
	settingsOutlineViewController.languagePropertyManager = [[_taskSpec script] languagePropertyManager];
	
	[_taskSpec addObserver:self forKeyPath:@"script.scriptType" options:NSKeyValueObservingOptionNew context:(void *)&MGSScriptTypeContext];
	[_taskSpec addObserver:self forKeyPath:@"script.languagePropertyManager" options:NSKeyValueObservingOptionNew context:(void *)&MGSScriptLanguagePropertyManagerContext];
	[_taskSpec addObserver:self forKeyPath:@"script.onRun" options:NSKeyValueObservingOptionNew context:(void *)&MGSScriptOnRunContext];
	[_taskSpec addObserver:self forKeyPath:@"script.subroutine" options:NSKeyValueObservingOptionNew context:(void *)&MGSScriptOnRunContext];
	[_taskSpec addObserver:self forKeyPath:@"script.runClass" options:NSKeyValueObservingOptionNew context:(void *)&MGSScriptOnRunContext];
    
    // initialise the build result
    self.buildStderrResult = @"";
    self.buildConsoleResult = @"";
    self.buildResultIndex = MGS_BUILD_RESULT_INDEX_CONSOLE;
    
}

/*
 
 - setBuildResultIndex:
 
 */
- (void)setBuildResultIndex:(NSInteger)idx
{
	NSString *result = nil;
	
	switch (idx) {
		case MGS_BUILD_RESULT_INDEX_CONSOLE:
			result = self.buildConsoleResult;
			break;
			
		case MGS_BUILD_RESULT_INDEX_STDERR:
			result = self.buildStderrResult;
			break;
		
		default:
			NSAssert(NO, @"invalid build result index");
	}

	if (!result) result = @"";
	buildResultIndex = idx;
	self.buildResult = result;
}

/*
 
 - setBuildResult:
 
 */
- (void)setBuildResult:(NSString *)result
{
	buildResult = result;
	
	// update console output
	NSDictionary *consoleOptions = nil;
	if (self.buildStatusFlags == MGS_BUILD_NO_WARNINGS) {
		consoleOptions = consoleSuccessOptions;
	} else {
		consoleOptions = consoleErrorOptions;
	}
	[self setConsoleText:buildResult append:NO options:consoleOptions];
	
}

/*
 
 - setBuildConsoleResult:
 
 */
- (void)setBuildConsoleResult:(NSString *)result
{
	_buildConsoleResult = result;
	
	if (self.buildResultIndex == MGS_BUILD_RESULT_INDEX_CONSOLE) {
		self.buildResult = _buildConsoleResult;
	}
	
}

/*
 
 - setBuildStderrResult:
 
 */
- (void)setBuildStderrResult:(NSString *)result
{
	buildStderrResult = result;

    // make stderr segment available
    BOOL stderrAvailable = !([result isEqualToString:@""] || !result);
    if (stderrAvailable) {
        
        // add segment if required
        if ([buildResultSegment segmentCount] == 1) {
            [buildResultSegment setSegmentCount:2];
            [buildResultSegment setLabel:@"stderr" forSegment:1];
            [buildResultSegment setWidth:[buildResultSegment widthForSegment:0] forSegment:1];

            if (self.buildResultIndex == MGS_BUILD_RESULT_INDEX_STDERR) {
                self.buildResult = buildStderrResult;
            }
        }
    } else {
        if (self.buildResultIndex == MGS_BUILD_RESULT_INDEX_STDERR) {
            self.buildResultIndex = MGS_BUILD_RESULT_INDEX_CONSOLE;
        }
        
        // remove segment if required
        [buildResultSegment setSegmentCount:1];
    }
	
}

/*
 
 - setBuildStatusFlags:
 
 */
- (void)setBuildStatusFlags:(NSInteger)flags
{
	buildStatusFlags = flags;
	
	NSString *statusString = NSLocalizedString(@"Build status unknown", @"Build status undefined");
	
	if (self.languageSupportsBuild) {
		if (buildStatusFlags == MGS_BUILD_PENDING) {
			statusString = NSLocalizedString(@"Build pending", @"Build status");
		} else if (buildStatusFlags == MGS_BUILD_FLAG_INITIATED) {
			statusString = NSLocalizedString(@"Building...", @"Build status");
		} else if (buildStatusFlags == MGS_BUILD_NO_WARNINGS) {
			statusString = NSLocalizedString(@"Build succeeded (0 warnings)", @"Build status");
		} else if (buildStatusFlags & MGS_BUILD_FLAG_FATAL_ERROR) {
			statusString = NSLocalizedString(@"Build failed", @"Build status");
		} else {
			statusString = NSLocalizedString(@"Build completed (with warnings)", @"Build status");
		}
	} else {
		statusString = NSLocalizedString(@"Build unsupported", @"Build status");
	}
	self.buildStatus = statusString;
	
}

/*
 
 - setScriptBuilt:
 
 */
- (void)setScriptBuilt:(BOOL)value
{
	scriptBuilt = value;
	
	if (!scriptBuilt) {
		self.buildStatusFlags = MGS_BUILD_PENDING;
		requestExecuteOnSuccessfulBuild = NO;
	}
	
	[self updateCanExecuteScript];
	[self updateCanBuildScript];
}

/*
 
 - setLanguageRequiresBuild:
 
 */
- (void)setLanguageRequiresBuild:(BOOL)value
{
	languageRequiresBuild = value;
	
	[self updateCanExecuteScript];
}

/*
 
 - setLanguageSupportsBuild:
 
 */
- (void)setLanguageSupportsBuild:(BOOL)value
{
	languageSupportsBuild = value;
	
	[self updateCanBuildScript];
}

/*
 
 current window
 
 */
- (NSWindow *)windowOrPending
{
	NSWindow *window = [[self view] window];
	if (!window) {
		window = _pendingWindow;
	}
	
	return window;
}

/*
 
 - canSaveScript
 
 */
- (BOOL)canSaveScript
{
	// if language requires a build and the script is not built
	// then we cannot save the script
	if (self.languageRequiresBuild && !self.scriptBuilt) {
		return NO;
	}
	
	return YES;
}

/*
 
 - scriptTextView
 
 */
- (NSTextView *)scriptTextView
{
    return scriptViewController.scriptTextView;
}
#pragma mark -
#pragma mark Actions

/*
 
 -showTemplateEditor:
 
 */
- (IBAction)showTemplateEditor:(id)sender
{
#pragma unused(sender)
	
	[[MGSResourceBrowserWindowController sharedController] showWindow:self];
}
/*
 
 -scriptTypeAction:
 
 */
- (IBAction)scriptTypeAction:(id)sender
{
#pragma unused(sender)
	
}

/*
 
 -showSettings:
 
 */
- (IBAction)showSettings:(id)sender
{
#pragma unused(sender)
	
	[modeSegment setSelectedSegment:MGS_SETTINGS_EDITOR];
    [NSApp sendAction:modeSegment.action to:self from:modeSegment];
}

/*
 
 - modeSegmentAction:
 
 */
- (IBAction)modeSegmentAction:(id)sender
{
	#pragma unused(sender)
	
	NSView *showView = nil, *hideView = nil;
	
	switch ([modeSegment selectedSegment]) {
		
		// edit script
		case MGS_SCRIPT_EDITOR:
			showView = splitView;
			hideView = [settingsOutlineViewController view];
			break;
			
		// edit settings
		case MGS_SETTINGS_EDITOR:
			
			/*
			 
			 the script view controller relies upon the 
			 textDidEndEditing: notification being sent.
			 
			 if the text has been edited and we swap the view out
			 the notification doesn't get sent!
			 
			 so we send it manually.
			 
			 */
			[scriptViewController textDidEndEditing:nil];
			showView = [settingsOutlineViewController view];
			hideView = splitView;
			break;
			
		default:
			NSAssert(FALSE, @"invalid segment index");
	}
	
	[[self view] replaceSubview:hideView withViewSizedAsOld:showView];
}

/*
 
 print
 
 */
- (void)printDocument:(id)sender
{
#pragma unused(sender)
	
	[scriptViewController printDocument:self];
}
#pragma mark -
#pragma mark Notification methods

/*
 
 script text changed
 
 */
- (void)scriptTextChanged:(NSNotification *)notification
{
	// only respond to notifications for this window
	if ([notification object] != [[self view] window])  return;

	if (self.scriptBuilt) {
		self.scriptBuilt = NO;
	}
}

/*
 
 - buildTaskScript
 
 */
- (void)buildTaskScript:(NSNotification *)notification
{
	
	// only respond to notifications for this window
	if ([notification object] != [[self view] window])  return;
	
	BOOL runAfterBuild = NO;
	
	// look for option keys
	NSNumber *runNumber = [[notification userInfo] objectForKey:MGSNoteRunKey];
	if (runNumber) {
		runAfterBuild = [runNumber boolValue];
	}
	
	requestExecuteOnSuccessfulBuild = runAfterBuild;
	
	[self requestBuild];
}

/*
 
 show dictionary
 
 */
- (void)showDictionary:(NSNotification *)notification
{	
	// only respond to notifications for this window
	if ([notification object] != [[self view] window]) return;

	/*
	if (nil == _applesScriptDictWindowController) {
		_applesScriptDictWindowController = [[MGSApplesScriptDictWindowController alloc] init];
	}
	
	[_applesScriptDictWindowController showWindow:self]; 
	 */
	//_osaDict = [[OSADictionary alloc] init];
	//[_osaDict chooseDictionary];
	
	// use private class to show AppleScript dictionary
	// part of OSAKit
	if ([OSADictionary respondsToSelector:@selector(chooseDictionary)]) {
		[OSADictionary performSelector:@selector(chooseDictionary)];
	}
	
}

#pragma mark -
#pragma mark MGSNetRequest owner

/*
 
 net request owner message
 
 */
-(void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload options:(NSDictionary *)options
{
	BOOL pendingExecuteOnSuccessfulBuild = requestExecuteOnSuccessfulBuild;
	requestExecuteOnSuccessfulBuild = NO;
	
	self.buildStatusFlags |= MGS_BUILD_FLAG_COMPLETED;
	NSMutableArray *errors = [NSMutableArray arrayWithCapacity:5];
		
	// validate response
	NSString *requestCommand = netRequest.kosmicTaskCommand;

	if (NSOrderedSame == [requestCommand caseInsensitiveCompare:MGSScriptCommandBuildScript]) {
		// a build request was issued
		
	} else if (NSOrderedSame == [requestCommand caseInsensitiveCompare:MGSScriptCommandExecuteScript]) {
		
		// a build request was issued and translated into an execute request
		
	} else {
		[MGSError clientCode:MGSErrorCodeInvalidCommandReply];
		return;
	}

	// build result flags indicate what build result request should contain
	MGSBuildResultFlags buildResultFlags = [[[_taskSpec script] languagePlugin] buildResultFlags];

	/*
	 
	 check for request error.
	 
	 errors and warnings will both generate a request level error.
	 
	 */
	if (netRequest.error) {
		
		// provisionally record a build warning
		self.buildStatusFlags |= MGS_BUILD_FLAG_WARNING;
		
		// record error
		[errors addObject:netRequest.error];
        
#ifdef MGS_DEBUG_CONTROLLER
        NSLog(@"NetRequest.error = %@", netRequest.error);
#endif
	}
	
	/*
	 
	 Get Compiled Source
	 
	 if compilation modifies source (eg: AppleScript) 
	 then extract source from payload.
	 
	 the source may be returned as rtf data or a string
	 
	 */
	if ((buildResultFlags & kMGSScriptSourceRTF) | 
		(buildResultFlags & kMGSScriptSource)) {
			
		NSString *stringSource = nil;
		
        //
		// RTF source
        //
		if ((buildResultFlags & kMGSScriptSourceRTF)) {
			
			// get compiled script RTF source from request dict
			NSData *rtfSource =[[payload dictionary] objectForKey:MGSScriptKeyCompiledScriptSourceRTF];

			// validate rtfSource if reqd
			if (rtfSource) {
			
                // attributed string source
				NSMutableAttributedString *attributedSource = [[NSMutableAttributedString alloc] initWithRTF:rtfSource documentAttributes:nil];
                
                // normalise the font name and size.
                // the string returned by the build may be formatted in a different
                // font to the one required by the editor.
                [scriptViewController applyDefaultFormatting:attributedSource];
                
                // the editor may require the attributed source that results from the build
                [[[_taskSpec script] scriptCode] setAttributedSourceFromBuild:attributedSource];
            
                // string source
                stringSource = [attributedSource string];
			
			} else {
				
				// if the build was not in error then we have an error
				if (self.buildStatusFlags == MGS_BUILD_NO_WARNINGS) {
					self.buildStatusFlags |= MGS_BUILD_FLAG_DATA_ERROR;
					[errors addObject:[MGSError clientCode:MGSErrorCodeCompiledScriptSourceRTFMissing]];
				} 
			}
		
		} 
		
        //
		// string source
        //
		if ((buildResultFlags & kMGSScriptSource) && !stringSource) {
		
			// get string source from request dict
			stringSource =[[payload dictionary] objectForKey:MGSScriptKeyScriptSource];
	
			// validate string source
			if (!stringSource) {
				
				// if the build was not in error then we have an error
				if (self.buildStatusFlags == MGS_BUILD_NO_WARNINGS) {
					self.buildStatusFlags |= MGS_BUILD_FLAG_DATA_ERROR;
					[errors addObject:[MGSError clientCode:MGSErrorCodeCompiledScriptSourceRTFMissing]];
				} 
			}
		}
		
		// update model with new source
		if (stringSource) {
			[[[_taskSpec script] scriptCode] setSource:stringSource];
		}

	}
		

	/*
	 
	 Get compiled data if flagged
	 
	 */		
	if ((buildResultFlags & kMGSCompiledScript)) {
		
		// get compiled script data and format
		NSData * compiledScriptData = [[payload dictionary] objectForKey:MGSScriptKeyCompiledScript];
		NSString *compiledScriptDataFormat = [[payload dictionary] objectForKey:MGSScriptKeyCompiledScriptDataFormat];
		
		// validate compiledScript
		if (compiledScriptData) {
			
			// set the compiled data
			[[[_taskSpec script] scriptCode] setCompiledData:compiledScriptData withFormat:compiledScriptDataFormat];

		} else {

			// if the build was not in error then we have an error
			if (self.buildStatusFlags == MGS_BUILD_NO_WARNINGS) {
				self.buildStatusFlags |= MGS_BUILD_FLAG_DATA_ERROR;
				[errors addObject:[MGSError clientCode:MGSErrorCodeCompiledScriptSourceRTFMissing]];
			} 
			
			// lack of compiled data is fatal
			self.buildStatusFlags |= MGS_BUILD_FLAG_FATAL_ERROR;
			
		}
	}

	/*
	 
	 process payload error dictionary
	 
	 */
	// get payload error dict.
	// this indicates that an error occurred in in the compiler process.
	NSDictionary *payloadErrorDictionary =  [[payload dictionary] objectForKey:MGSScriptKeyNSErrorDict];
    
	if (payloadErrorDictionary) {

#ifdef MGS_DEBUG_CONTROLLER
        NSLog(@"[payload dictionary] = %@", netRequest.error);
#endif		
		// process payload
		// this might require some work as payload error seems to duplicate request error.
		// but will this always be the case ?
		// for now we record this error only in the case that there are no other errors.
		if (self.buildStatusFlags == MGS_BUILD_NO_WARNINGS) {
			self.buildStatusFlags |= MGS_BUILD_FLAG_ERROR_PAYLOAD;
			[errors addObject:[MGSError errorWithDictionary:payloadErrorDictionary log:NO]];	// don't log as not an application error
		}
	}		
	/*
	 
	 handle build errors
	 
	 */
	if ([errors count] == 0) {

        //
        // we have no build errors
        //

		NSAssert(self.buildStatusFlags == MGS_BUILD_NO_WARNINGS, @"invalid build status");
		
		self.scriptBuilt = YES;

		// no errors generated so we can dismiss the build sheet
		[_buildTaskSheetController OKToCloseWindow:self];
		
		// console result
		self.buildConsoleResult = NSLocalizedString(@"Build succeeded (0 warnings)", @"script build complete");
		self.buildSheetMessage = self.buildConsoleResult;
		
		// execute if request pending
		if (pendingExecuteOnSuccessfulBuild) {
			[self performSelector:@selector(requestExecute) withObject:nil afterDelay:0];
		}
	} else {

        //
        // we have build errors
        //
        
		NSAssert(self.buildStatusFlags != MGS_BUILD_NO_WARNINGS, @"invalid build status");
				
		NSMutableString *errorString = [NSMutableString new];

		// we may be requested to ignore build warnings
		BOOL ignoreBuildWarning = [[options objectForKey:MGSIgnoreBuildError] boolValue];
		ignoreBuildWarning = YES; // override
		
		// if the build error is fatal we cannot ignore it
		if (self.buildStatusFlags & MGS_BUILD_FLAG_FATAL_ERROR) {
			ignoreBuildWarning = NO;
		}
		
		// determine if it is valid to ignore build warnings
		BOOL canIgnoreBuildWarnings = [[[_taskSpec script] languagePlugin] canIgnoreBuildWarnings];
		
		// only ignore build errors if requested and valid
		ignoreBuildWarning = (ignoreBuildWarning && canIgnoreBuildWarnings);
		
		// report errors
		for (MGSError *mgsError in errors) {
			
			// error message
			NSString *message = [mgsError localizedDescription];
			if (nil == message) {
				message = NSLocalizedString(@"unspecified build error", @"unspecified error build error");
			}
			
			// failure message
			NSString *failureMessage =[mgsError localizedFailureReason];
			if (nil == failureMessage) {
				failureMessage = NSLocalizedString(@"unspecified failure reason", @"unspecified failure");
			}
			
			// addtional error
			NSString *additionalError = [[mgsError userInfo] objectForKey:MGSAdditionalCodeErrorKey];
			
			// build the error
			NSMutableString *error = [NSMutableString new];
			if ([mgsError code] != MGSErrorCodeScriptBuild) {
				[error appendFormat:@"%@ ", message];
			}
			if (additionalError) {
				[error appendFormat:@"(%@): ", additionalError];
			}
			[error appendFormat:@"%@", failureMessage];
			
			// add to error string
			if ([errorString length] > 0) {
				[errorString appendString:@"\n"];
			}
			[errorString appendFormat:@"%@", error];
		}
		
		self.buildConsoleResult = errorString;
		
		/*
		 
		 we can ignore non fatal build warnings
		 
		 in this case we allow script execution, even though it may fail
		 
		 */
        BOOL fatalError = ((self.buildStatusFlags & MGS_BUILD_FLAG_FATAL_ERROR) > 0 ? YES : NO);
        BOOL buildSuccess = (ignoreBuildWarning && !fatalError);
        
        // the build has errors, even if non fatal.
        // it doesn't make sense to mark the script as successfully built.
        buildSuccess = NO;
        
		if (buildSuccess) {
			
			self.scriptBuilt = YES;
			self.buildSheetMessage = NSLocalizedString(@"See build console for details.", @"script compiling complete");
			
		} else {
			
			self.scriptBuilt = NO;
			self.buildSheetMessage = self.buildConsoleResult;			
		}
        
        // highlight error ranges
        NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:[errors count]];
        for (MGSError *mgsError in errors) {
            
            // get the error range
            NSString *rangeString = [[mgsError userInfo] objectForKey:MGSRangeErrorKey];
            if (rangeString) {
                NSRange range = NSRangeFromString(rangeString);
                [ranges addObject:[NSValue valueWithRange:range]];
            }
        }
        if ([ranges count] > 0) {
            NSDictionary *rangeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:YES], @"scrollVisible", nil];
            [scriptViewController setSelectedRanges:ranges options:rangeOptions];
        }
        
        // dismiss the build sheet if required
        BOOL dismissBuildSheet = NO;
        if (dismissBuildSheet) {
            [_buildTaskSheetController OKToCloseWindow:self];
        }

	}
		
	// get std error.
	// additional shell error/logging sent via stderr.
	//
	// the situation here seems quite complex. 
	// some process report errors on stdErr others do not so and in general
	// it seems easy to get duplicate data on stderr which is already availabe
	// in the request error.
	//
	// it's completely up to the build process what we receive back here.
	// so rather than just dumping everything into the console it might be better
	// to provide a separate channel for stdErr
	//
	NSString *stdErrString = [[payload dictionary] objectForKey:MGSScriptKeyStdError];
	if (stdErrString) {
		self.buildStderrResult = stdErrString;
	} else {
		self.buildStderrResult = @"";
	}
}
/*
 
 - setOutputText:append:
 
 */
- (void)setConsoleText:(NSString *)text append:(BOOL)append options:(NSDictionary *)options
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:consoleAttributes];
	
	// process options
	if (options) {
		
		// combine text attributes with console attributes
		NSDictionary *optionAttributes = [options objectForKey:@"attributes"];
		if (optionAttributes) {
			[attributes addEntriesFromDictionary:optionAttributes];
		}
	}
	
	NSAttributedString *attrMesg = [[NSAttributedString alloc] initWithString:text attributes:attributes];
	NSTextStorage *textStorage = [consoleTextView textStorage];
	
	NSRange endRange;
	endRange.location = [[consoleTextView textStorage] length];
    endRange.length = 0;
		
	[textStorage beginEditing];
	if (append) {
		[textStorage appendAttributedString:attrMesg];
	} else {
		[textStorage replaceCharactersInRange:NSMakeRange(0, [[consoleTextView textStorage] length]) withAttributedString:attrMesg];
	}
	[textStorage endEditing];
	endRange.length = [text length];
    [consoleTextView scrollRangeToVisible:endRange];
}
	 
/*
 
 commit pending edits
 
 */
- (BOOL)commitPendingEdits
{
    // the script source gets updated only when the editor resigns as first responder.
    // this will occur when the sheet is shown.
    // so we can  force updating by sending - textDidEndEditing
    [scriptViewController textDidEndEditing:nil];
    
	return YES;
}

#pragma mark -
#pragma mark Memory management
/*
 
 dispose
 
 */
- (void)dispose
{
	[scriptViewController dispose];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
 
 initial first responder
 
 */
- (NSView *)initialFirstResponder
{
	return [scriptViewController initialFirstResponder];
}

#pragma mark -
#pragma mark NSSplitView delegate messages

/*
 
 get additional drag rect for divider at index
 
 */
- (NSRect)splitView:(NSSplitView *)aSplitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
	#pragma unused(dividerIndex)
	
	NSRect leftFrame = [aSplitView convertRect:[buildResultSegment bounds] fromView:buildResultSegment];
	NSRect rightFrame = [aSplitView convertRect:[splitViewDragImage bounds] fromView:splitViewDragImage];
	
	CGFloat originX = leftFrame.origin.x + leftFrame.size.width;
	CGFloat originY = leftFrame.origin.y;
	CGFloat width = rightFrame.origin.x + rightFrame.size.width - originX;
	CGFloat height = leftFrame.size.height;
	NSRect dragFrame = NSMakeRect(originX, originY, width, height);
	
	return dragFrame;
}

/*
 
 splitview resized
 
 */
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize
{	
	MGSSplitviewBehaviour behaviour;
	
	NSSize size = [sender frame].size;
	CGFloat delta = oldSize.height - size.height;
	CGFloat topViewHeight = size.height + delta - [[[sender subviews] objectAtIndex:1] frame].size.height - [splitView dividerThickness];
	
	NSArray *minHeightArray = [NSArray arrayWithObjects:[NSNumber numberWithDouble:MIN_TOP_SPLITVIEW_HEIGHT], [NSNumber numberWithDouble:MIN_BOTTOM_SPLITVIEW_HEIGHT], nil];
	
	// if top view >= min size then resizing top view
	if (topViewHeight >= MIN_TOP_SPLITVIEW_HEIGHT) {
		behaviour = MGSSplitviewBehaviourOf2ViewsSecondFixed;
	} else {
		// resize bottom view
		behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;
	}
	
	// see the NSSplitView_Mugginsoft category
	[sender resizeSubviewsWithOldSize:oldSize withBehaviour:behaviour minSizes:minHeightArray];
}
/*
 
 splitview constrain max position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	#pragma unused(offset)
	
	proposedMax = [sender frame].size.height - MIN_BOTTOM_SPLITVIEW_HEIGHT - [sender dividerThickness];
	
	return proposedMax;
}
/*
 
 splitview constrain min position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	#pragma unused(sender)
	#pragma unused(offset)
	
	proposedMin = MIN_TOP_SPLITVIEW_HEIGHT;
	
	return proposedMin;
}

/*
 
 - requestExecuteWithoutBuild
 
 */
-(void)requestExecute
{	
	// send the execute task request up the responder chain
	[NSApp sendAction:@selector(requestExecuteTask:) to:nil from:self];
}

/*
 
 - requestBuild
 
 issue request for script build for current task
 
 */
-(void)requestBuild
{
	// need to view to be in window
	if (![[self view] window]) {
		return;
	}
	
	if (!_taskSpec) return;
	
	// validate if can build
	if (!_taskSpec.canBuild || !_taskSpec.netClient.isConnected) {
		NSBeginAlertSheet(
						  NSLocalizedString(@"Sorry, remote machine not available.", @"Alert sheet text"),	// sheet message
						  nil,              //  default button label
						  nil,             //  alternate button label
						  nil,              //  other button label
						  [[self view] window],	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  @selector(disconnectedAlertSheetDidEnd:returnCode:contextInfo:),					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  NULL,       // context info
						  NSLocalizedString(@"You will not be able to build this task until the remote machine becomes available again.", @"Alert sheet text"),	// additional text
						  nil);
		
		return;
	}
	
	// clear any existing compiled data that exists
	[[[_taskSpec script] scriptCode] setCompiledData:nil withFormat:nil];

    // clear any attributed source from last build
    [[[_taskSpec script] scriptCode] setAttributedSourceFromBuild:nil];
    
	// if we cannot build then execute
	if (!self.canBuildScript) {
		
		[self requestExecute];
		
		return;
	}

	[self commitEditing];
	
	MGSScript *script = [_taskSpec script];
	
	// update the build result output
	NSString *mesgFormat = NSLocalizedString(@"Building script '%@' as %@ on %@ ... ", @"script compiling message");
	NSString *mesg = [NSString stringWithFormat:mesgFormat, [script name], [script scriptType], [[_taskSpec netClient] serviceShortName]];
	self.buildConsoleResult = mesg;
	self.buildStderrResult = @"";

	// build task sheet controller
	_buildTaskSheetController = [[MGSBuildTaskSheetController alloc] init];
	[_buildTaskSheetController window]; // load it
	_buildTaskSheetController.taskSpecifier = _taskSpec;
	_buildTaskSheetController.delegate = self;
	_buildTaskSheetController.modalWindowWillCloseOnSave = YES;
	
	[_buildTaskSheetController addObserver:self forKeyPath:@"buildWarningsCheckBoxState" options:0 context:(void *)&MGSErrorCheckboxContext];
	
	// show the sheet.
	[NSApp beginSheet:[_buildTaskSheetController window] modalForWindow:[[self view] window] 
		modalDelegate:self 
	   didEndSelector:@selector(buildTaskSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
	
	self.buildStatusFlags = MGS_BUILD_INITIATED;
	
	// issue the build request
	[_buildTaskSheetController build:self];
}

#pragma mark -
#pragma mark Window sheet handling
/*
 
 -buildTaskSheetDidEnd:returnCode:contextInfo:
 
 */
- (void)buildTaskSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	#pragma unused(sheet)
	#pragma unused(contextInfo)
	
	switch (returnCode) {
			
		case NSOKButton:
			break;
			
		case NSCancelButton:
			self.buildConsoleResult = NSLocalizedString(@"Build cancelled", @"build cancelled");
			self.scriptBuilt = NO;
			break;
	}
	
	[scriptViewController makeFirstResponder:nil];
}

/*
 
 disconnected alert sheet ended
 
 */
- (void)disconnectedAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	#pragma unused(sheet)
	#pragma unused(contextInfo)
	
	switch (returnCode) {
			
		case NSOKButton:
			break;
			
		case NSCancelButton:
			break;
	}
	
}

@end
