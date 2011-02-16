//
//  MGSEditWindowController.m
//  Mother
//
//  Created by Jonathan on 14/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
//#import <Foundation/NSObjCRuntime.h>

// /Developer/SDKs/MacOSX10.5.sdk/usr/include/objc
//#import <objc/objc-runtime.h>

#import "MGSMother.h"
#import "MGSEditWindowController.h"
#import "MGSTaskSpecifier.h"
#import "MGSToolbarController.h"
#import "MGSNotifications.h"
#import "MGSActionEditViewController.h"
#import "MGSScriptEditViewController.h"
#import "MGSScriptViewController.h"
#import "MGSRequestViewController.h"
#import "MGSOutputRequestViewController.h"
#import "MGSScript.h"
#import "MGSScriptPlist.h"
#import "MGSNetClient.h"
#import "MGSClientScriptManager.h"
#import "MGSMotherModes.h"
#import "MGSImageManager.h"
#import "NSMutableDictionary_Mugginsoft.h"
#import "NSWindow_Mugginsoft.h"
#import "MGSRequestViewManager.h"
#import "MGSSaveActionSheetController.h"
#import "NSWindow_Mugginsoft.h"
#import "MGSClientRequestManager.h"
#import "MGSNetRequestPayload.h"
#import "MGSRequestTabScrollView.h"
#import "MGSAPLicenceCode.h"
#import "MGSApplicationMenu.h"

#define ACTION_TAB 0
#define SCRIPT_TAB 1
#define RUN_TAB 2


NSString *MGSScriptCompiledContext = @"MGSScriptCompiled";
NSString *MGSModelChangedContext = @"MGSModelChanged";
NSString *MGSScriptNameChangedContext = @"MGSScriptNameChanged";

// class extension
@interface MGSEditWindowController()
- (void)windowEditModeChanged:(NSNotification *)notification;
- (void)subViewModelEdited:(NSNotification *)notification;
- (void)windowEditModeWillChange:(NSNotification *)notification;
- (void)noSaveAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void)compileAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void)disconnectedAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void)saveActionSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)resourceSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)showTemplateSheet_:(id)sender;
- (void)changeEditMode:(eMGSMotherEditMode)mode;
@end

@interface MGSEditWindowController(Private)

@end


@implementation MGSEditWindowController

@synthesize taskSpec = _taskSpec;

#pragma mark -
#pragma mark Instance control
/*
 
 init
 
 */
- (id)init
{
	if ((self = [super initWithWindowNibName:@"EditWindow"])) {
		self.toolbarStyle = MGSToolbarStyleEdit;
		_editMode = kMGSMotherEditModeConfigure;
	}
	return self;
}

- (void)setDelegate:(id <MGSEditWindowDelegate>) object
{
	delegate = object;
}

#pragma mark -
#pragma mark Window handling
/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	
	_closeWindowAfterSave = YES;
	_silentClose = NO;
	
	[[statusTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];	// indent text
	[[actionUUIDTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];	// indent text
	
	// if window document marked as edited (even though we are not using NSDocument)
	// the window will display appropriate marker in red close button
	[[self window] setDocumentEdited:NO];
		
	// observe window edit mode changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowEditModeChanged:) name:MGSNoteWindowEditModeDidChange object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subViewModelEdited:) name:MGSNoteViewModelEdited object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowEditModeWillChange:) name:MGSNoteWindowEditModeChangeRequest object:[self window]];
	
	// note that laying out NSTabView in IB can be misleading
	// with regard to frame and layout
	[tabView setTabViewType:NSNoTabsNoBorder];
	
	// note that when these were defined as objects within the nib
	// it caused horrible intermittent crashes.
	// so having a controller in a nib which loads its own nib seems
	// to be a recipe for disaster.
	actionEditViewController = [[MGSActionEditViewController alloc] init];
	[actionEditViewController view];	// load it
	
	scriptEditViewController = [[MGSScriptEditViewController alloc] init];
	[scriptEditViewController view]; // load it
	scriptEditViewController.pendingWindow = [self window];	// view will become active in this window when tab selected
	
	// observe script compilation status
	[scriptEditViewController addObserver:self forKeyPath:@"canExecuteScript" options:0 context:MGSScriptCompiledContext];

	// note that assigning a tabs view does not add the view to the hierarchy until displayed.
	// so the views window will remain nil.
	// set the action tab view
	NSTabViewItem *tabViewItem =[tabView tabViewItemAtIndex:ACTION_TAB];
	[tabViewItem setView: [actionEditViewController view]];
	[tabViewItem setIdentifier:actionEditViewController];
	
	// set the script tab view
	tabViewItem =[tabView tabViewItemAtIndex:SCRIPT_TAB];
	[tabViewItem setView: [scriptEditViewController view]];
	[tabViewItem setIdentifier:scriptEditViewController];
	[tabViewItem setInitialFirstResponder:[scriptEditViewController initialFirstResponder]];
	
	// set the run tab view
	tabViewItem =[tabView tabViewItemAtIndex:RUN_TAB];
	[tabViewItem setView: [self.requestViewController view]];
	[tabViewItem setIdentifier:self.requestViewController];
	
	// size the scrollview document to accomodate the requestView.
	// normally this occurs when we resize the scrollview.
	// but here we need to call it manually as we are adding the new view to the tabview.
	// load the run view here so that its frame gets set.
	// the NSTabView won't add the view to a hierarchy until the tab is selected.
	// if we don't preselect the tab the view resizing behaviour goes astray
	[tabView selectTabViewItemAtIndex:RUN_TAB];
	[requestTabScrollView sizeDocumentWidthForRequestViewController:self.requestViewController withOldSize:[[self.requestViewController view] bounds].size];	
	
	[tabView selectTabViewItemAtIndex:ACTION_TAB];
	
	// do not send completed actions to the history
	self.requestViewController.sendCompletedActionSpecifierToHistory = NO;
}

/*
 
 update window title
 
 */
- (void)updateWindowTitle
{
	NSString *title = [NSString stringWithFormat:@"%@ %@ — %@", NSLocalizedString(@"Edit: ", @"Edit window title"),
					   [[_taskSpec netClient] serviceShortName], [[_taskSpec script] name]];
	[[self window] setTitle: title];		
}

#pragma mark -
#pragma mark Document handling
/*
 
 save document
 
 sent by the application menu.
 it will travel up the responder chain to here,
 
 */
- (void)saveDocument:(id)sender
{
	#pragma unused(sender)
	
	// ensure script is scheduled to be saved
	[[_taskSpec script] setScheduleSave];
	
	_closeWindowAfterSave = NO;
	[self askToSave:nil];
	
	if (_saveActionSheetController) {
		[_saveActionSheetController save:self];
	}
}

/*
 
 new document
 
 */
- (void)newDocument:(id)sender
{
	#pragma unused(sender)
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteCreateNewTask object:nil userInfo:nil];
}


/*
 
 print document
 
 sent by the application menu.
 it will travel up the responder chain to here,
 
 */
- (void)printDocument:(id)sender
{
	#pragma unused(sender)
	
	[scriptEditViewController printDocument:self];
}

/*
 
 - openDocument:
 
 */
- (void)openDocument:(id)sender
{
#pragma unused(sender)
	
	// this acts as a shortcut to script editing
	[self requestEditTask:self];
}

/*
 
 run page layout
 
 */
- (void)runPageLayout:(id)sender
{
	#pragma unused(sender)
	
	[NSApp runPageLayout:self];
}

/*
 
 open file
 
 */
- (IBAction)openFile:(id)sender
{
#pragma unused(sender)
	NSString *existingSource = [[[_taskSpec script] scriptCode] source];
	NSInteger textHandling = MGS_AV_APPEND_TEXT;
	if (!existingSource || [existingSource length] == 0) {
		textHandling = MGS_AV_REPLACE_TEXT;
	}
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [self window], @"window",
							 [NSNumber numberWithInteger:textHandling], @"textHandling",
							 [NSNumber numberWithBool:YES], @"textHandlingEnabled",
							 nil];
	[[self openPanelController] openSourceFile:self options:options];
	
}


#pragma mark -
#pragma mark MGSOpenPanelController notifications

/*
 
 - openPanelControllerDidClose:
 
 */
- (void)openPanelControllerDidClose:(NSNotification *)notification
{
	#pragma unused(notification)
	
	// set source selected
	NSString *source = [[notification userInfo] objectForKey:@"source"];
	if (!source) return;
	
	// get script type
	NSString *scriptType = [[notification userInfo] objectForKey:@"scriptType"];
	
	// update the model
	[[[_taskSpec script] scriptCode] setSource:@""];
	
	// update the script type
	if (scriptType && [MGSScript validateScriptType:scriptType]) {
		[[_taskSpec script] setScriptType:scriptType];
	}
	
	NSNumber *textHandling = [[notification userInfo] objectForKey:@"textHandling"];
	NSAssert(textHandling, @"text handling is not defined");
	NSInteger textHandlingMode = [textHandling integerValue];
	
	// update the source
	switch (textHandlingMode) {
		case MGS_AV_APPEND_TEXT:;
			NSString *existingSource = [[[_taskSpec script] scriptCode] source];
			source = [NSString stringWithFormat:@"%@\n%@", existingSource, source];
			break;
			
		case MGS_AV_REPLACE_TEXT:
			break;
			
		default:
			NSAssert(NO, @"invalid text handing mode");
			break;
	}
	
	// rep;lace the script source
	[[[_taskSpec script] scriptCode] setSource:source];

}
	

#pragma mark -
#pragma mark Templates

/*
 
 - showTemplateSheet:
 
 */
- (IBAction)showTemplateSheet:(id)sender
{
#pragma unused(sender)
	
	// load the resource sheet controller.
	// use the cached controller if available and resources have not been modified
	if (!resourceSheetController || resourceSheetController.resourcesChanged) {
		resourceSheetController = [[MGSResourceBrowserSheetController alloc] init];
		[resourceSheetController window];
	}
	
	// hack in order for outline view to scroll to selected row
	[self performSelector:@selector(showTemplateSheet_:) withObject:self afterDelay:0];

}

/*
 
 - showTemplateSheet_:
 
 */
- (void)showTemplateSheet_:(id)sender
{
	#pragma unused(sender)
	
	// we require to preselect the default template for the current script type
	resourceSheetController.scriptType = [[_taskSpec script] scriptType];
	
	// show the sheet
	[NSApp beginSheet:[resourceSheetController window] 
	   modalForWindow:self.window 
		modalDelegate:self 
	   didEndSelector:@selector(resourceSheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:NULL];
}
/*
 
 - resourceSheetDidEnd:returnCode:contextInfo:
 
 */
- (void)resourceSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	#pragma unused(sheet)
	#pragma unused(contextInfo)
	
	switch (returnCode) {
		
			// quit
		case 0:
			break;
			
			// template selected
		case 1:;
			// update script type if it has changed
			NSString *scriptType = resourceSheetController.scriptType;
			if (![scriptType isEqualToString:[_taskSpec.script scriptType]]) {
				[_taskSpec.script setScriptType:scriptType];
			}

			// update the language property manager
			[_taskSpec.script updateLanguagePropertyManager:resourceSheetController.languagePropertyManager];

			// get the template text
			NSString *templateText = resourceSheetController.resourceText;
			
			// update the model
			[[[_taskSpec script] scriptCode] setSource:templateText];

			break;
		
			// open file
		case 2:
			[self openFile:self];
			break;
	}
}

#pragma mark -
#pragma mark View handling

/*
 
 active result view controller
 
 subclasses must override to return currently active result view controller
 
 */
- (MGSResultViewController *)activeResultViewController
{
	if (_editMode == kMGSMotherEditModeRun) {
		return self.requestViewController.outputViewController.resultViewController;
	}
	
	return nil;
}

#pragma mark -
#pragma mark Menu handling
/*
 
 validate menu item
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSCellStateValue state = NSOffState;
	BOOL enabled = YES;
	SEL theAction = [menuItem action];

	// action execution	
	// we need to override the superclass implementation
	if ((theAction == @selector(requestSuspendTask:)) ||
		(theAction == @selector(requestResumeTask:)) ||
		(theAction == @selector(requestTerminateTask:))) {
		
		if (!scriptEditViewController.scriptBuilt || _editMode != kMGSMotherEditModeRun) {
			return NO;
		}
		
		return [super validateMenuItem:menuItem];
		
	} else if (theAction == @selector(requestEditTask:) || theAction == @selector(openDocument:)) {
		if (![[self selectedActionSpecifier] canExecute]) {
			return NO;
		}
		
		return YES;
	} else if (theAction == @selector(requestExecuteTask:)) {
		
		if (!scriptEditViewController.canExecuteScript) {
		   return NO;
		} 
		
		// we can run in script mode !
		if (_editMode == kMGSMotherEditModeConfigure) {
			return NO;
		}
		
		return [super validateMenuItem:menuItem];
	
	} else if (theAction == @selector(newDocument:)) {
		
		return YES;
		
	} else if (theAction == @selector(openFile:)) {

		if (_editMode == kMGSMotherEditModeRun) {
			return NO;
		}
		
		[menuItem setTitle:NSLocalizedString(@"Open File for This Task...", @"Edit window File menu string")];
		
		return YES;
		
	// validate with super
	} else if (![super validateMenuItem:menuItem]) {
		return NO;
	}
	
	else if (theAction == @selector(saveDocument:)) {
		return [[self window] isDocumentEdited];
	}
	
	// document modification
	else if (theAction == @selector(newDocument:)) {
		
		return YES;	
		
		// application menu view edit mode selected
	} else if (theAction == @selector(viewMenuEditModeSelected:)) {
		
		// we need to reset the menu state every time as we may have selected a different client.
		switch ([menuItem tag]) {
			case kMGS_MENU_TAG_VIEW_EDIT_MODE_CONFIGURE:
				if (_editMode == kMGSMotherEditModeConfigure) state = NSOnState;
				break;
				
			case kMGS_MENU_TAG_VIEW_EDIT_MODE_SCRIPT:
				if (_editMode == kMGSMotherEditModeScript) state = NSOnState;
				break;
				
			case kMGS_MENU_TAG_VIEW_EDIT_MODE_RUN:
				if (scriptEditViewController.scriptBuilt) {
					if (_editMode == kMGSMotherEditModeRun) state = NSOnState;
				} else {
					enabled = NO;
				}
				break;
				
			default:
				NSAssert(NO, @"invalid menu tag");
		}
		[menuItem setState:state];
		
		// enabled if can edit
		if (enabled) {
			enabled = [[self selectedActionSpecifier] canEdit];
		}
	
	// compile document script
	} else if  (theAction == @selector(compileDocumentScript:) || 
				theAction == @selector(buildAndRunDocumentScript:)) {
		enabled = NO;
		
		// can only compile when script mode selected
		if (_editMode == kMGSMotherEditModeScript) {
			
			enabled = scriptEditViewController.canBuildScript;
			
		}
		
		// compile document script
	} else if  (theAction == @selector(showTemplateSheet:)) {
		enabled = NO;
		
		// can only compile when script mode selected
		if (_editMode == kMGSMotherEditModeScript) {
			
			enabled = YES;
			
		}
		
	}	
	
	
	return enabled;
}
/*
 
 view menu edit mode item selected
 
 */
- (IBAction)viewMenuEditModeSelected:(id)sender
{
	
	if (![sender isKindOfClass:[NSMenuItem class]]) {
		return;
	}
	NSMenuItem *menuItem = sender;
	eMGSMotherEditMode mode = kMGSMotherEditModeConfigure;
	
	switch ([menuItem tag]) {
		case kMGS_MENU_TAG_VIEW_EDIT_MODE_CONFIGURE:
			mode = kMGSMotherEditModeConfigure;
			break;
			
		case kMGS_MENU_TAG_VIEW_EDIT_MODE_SCRIPT:
			mode = kMGSMotherEditModeScript;
			break;
			
		case kMGS_MENU_TAG_VIEW_EDIT_MODE_RUN:
			mode = kMGSMotherEditModeRun;
			break;
			
		default:
			NSAssert(NO, @"invalid menu tag");
	}
	
	[self changeEditMode: mode];
}

/*
 
 - changeEditMode:
 
 */
- (void)changeEditMode:(eMGSMotherEditMode)mode
{
	// make window the first responder.
	// this should conclude any current edits.
	// this is required as objects may get copied when the edit mode changes.
	// therefore we need to make sure that our models are up to date.
	// both manual updating and bindings rely on the first responder resiging to commit edits.
	// when the user manual changes edit mode this will occur.
	// when changing the mode programatically we need to prompt the first responder to resign its status.
	[[self window] endEditing];
	
	// post notification requesting edit mode change
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:mode], MGSNoteModeKey,
						  [NSNumber numberWithInt:_editMode], MGSNotePrevModeKey, 
						  nil];
	
	// send change request
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteWindowEditModeChangeRequest object:[self window] userInfo:dict];
	
}

#pragma mark -
#pragma mark MGSTaskSpecifier handling

/*
 
 - setTaskSpec:
 
 */
- (void)setTaskSpec:(MGSTaskSpecifier *)aTaskSpec
{
	_taskSpec = aTaskSpec; 
	
	// schedule script for save
	[[_taskSpec script] setScheduleSave];
	
	actionEditViewController.action = _taskSpec;
	scriptEditViewController.taskSpec = _taskSpec;
	
	// observe changes to the script data
	[_taskSpec addObserver:self forKeyPath:@"script.modelDataKVCModified" options:0 context:MGSModelChangedContext];
	[_taskSpec addObserver:self forKeyPath:@"script.name" options:0 context:MGSScriptNameChangedContext];
	
	// set net client
	self.netClient = [_taskSpec netClient];
	
	// set status text
	[statusTextField setStringValue: [NSString stringWithFormat:@"%@", [[_taskSpec netClient] serviceShortName]]];
	[actionUUIDTextField setStringValue: [NSString stringWithFormat:NSLocalizedString(@"Task ID: %@", @"Task edit window footer text."), [[_taskSpec script] UUID]]];

	[self updateWindowTitle];
}

/*
 
 selected action specifier
 
 */
- (MGSTaskSpecifier *)selectedActionSpecifier
{
	switch (_editMode) {
		case kMGSMotherEditModeRun:
			return [super selectedActionSpecifier];
			
		default:
			return _taskSpec;
	}
}

/*
 
 - requestExecuteTask:
 
 */
- (IBAction)requestExecuteTask:(id)sender
{
	// validate that we can execute
	if (!scriptEditViewController.canExecuteScript) {
		return;
	}
	
	// change to run mode
	if (_editMode != kMGSMotherEditModeRun) {
		[self changeEditMode:kMGSMotherEditModeRun];
	}
	
	// super implementation will execute
	[super requestExecuteTask:sender];
}

/*
 
 - requestEditTask:
 
 */
- (IBAction)requestEditTask:(id)sender
{	
#pragma unused(sender)
	if (_editMode != kMGSMotherEditModeScript) {
		[self changeEditMode:kMGSMotherEditModeScript];
	}
}

#pragma mark -
#pragma mark Operations
/*
 
 execute selected action
 
 */
- (void)executeSelectedAction:(NSNotification *)notification
{	
	if (scriptEditViewController.canExecuteScript) {
		[super executeSelectedTask:notification];
	}
}

/*
 
 compile document script
 
 this will come up the responder chain
 
 */
- (IBAction)compileDocumentScript:(id)sender
{
	#pragma unused(sender)
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteBuildScript object:[self window] userInfo:nil];
}

/*
 
 - buildAndRunDocumentScript:
 
 this will come up the responder chain
 
 */
- (IBAction)buildAndRunDocumentScript:(id)sender
{
#pragma unused(sender)

	// option key requests run after build
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], MGSNoteRunKey, nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteBuildScript object:[self window] userInfo:options];

}


/*
 
 commit pending edits in all views
 
 */
- (BOOL)commitPendingEdits
{
	if (![actionEditViewController commitPendingEdits]) {
		return NO;
	}
	if (![scriptEditViewController commitPendingEdits]) {
		return NO;
	}	
	if (![self.requestViewController commitEditing]) {
		return NO;
	}
	return YES;
}

#pragma mark -
#pragma mark MGSRequestTabScrollView delegate messages
/*
 
 view will resize subviews with old size
 
 its easier for the delegate to compute what's required than it is for the view
 
 */
- (void)view:(NSView *)senderView willResizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{	
	if (senderView == requestTabScrollView) {
		
		[requestTabScrollView sizeDocumentWidthForRequestViewController:self.requestViewController withOldSize:oldBoundsSize];
	}
}
/*
 
 view did resize subviews with old size
 
 its easier for the delegate to compute what's required than it is for the view
 
 */
- (void)view:(NSView *)senderView didResizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{	
	if (senderView == requestTabScrollView) {		
		[requestTabScrollView resetDocumentWidthForRequestViewController:self.requestViewController withOldSize:oldBoundsSize];
	}	
}

/*
 
 close window silently without any prompts regardless of edited state
 
 */
- (void)closeWindowSilently
{
	_silentClose = YES;
	[[self window] close];
}

#pragma mark -
#pragma mark MGSEditWindowDelegate messages
/*
 
 document edited for window
 
 marking the document as edited marks the script as requiring save
 
 */
- (void)documentEdited:(BOOL)flag forWindow:(NSWindow *)window
{
	NSAssert(window == [self window], @"wrong window");
	
	// mark script as requiring save
	if (flag) {
		if (![[_taskSpec script]scheduleSave]) {
			[[_taskSpec script] setScheduleSave];
		}
	} else {
		[[_taskSpec script] acceptScheduleSave];
	}
}

/*
 
 - shiftLeftAction:
 
 */
- (void)shiftLeftAction:(id)sender
{
	[scriptEditViewController.scriptViewController shiftLeftAction:sender];
}
#pragma mark -
#pragma mark NSWindow delegate messages

/*
 
 window did resign key
 
 */
- (void)windowDidResignKey:(NSNotification *)notification
{
	#pragma unused(notification)
	
	if (_silentClose) return;
	
	[[self window] endEditing];
}


/* 
 
 window should close
 
 */
- (BOOL)windowShouldClose:(id)window
{	
	if (![super windowShouldClose:window]) {
		return NO;
	}
	
	if (_silentClose) return YES;
	
	// commit any edits.
	// this is klutzy. see line below.
	if (![self commitPendingEdits]) {
		return NO;
	}

	// make window the first responder.
	// this should conclude and current edits.
	[[self window] endEditing];
	
	// if not dirty then no save required
	if (NO == [[self window] isDocumentEdited]) {
		return YES;
	}

	_closeWindowAfterSave = YES;
	[self askToSave:nil];

	// did end selector will close window if required
	return NO;
}

#pragma mark -
#pragma mark Sheet callbacks
/*
 
 ask to save
 
 */
- (void)askToSave:(SEL)callback
{
	// if licence is trial then cannot save
	if (MGSAPLicenceIsRestrictiveTrial() && TRIAL_RESTRICTS_FUNCTIONALITY) {
		NSBeginAlertSheet(
						  NSLocalizedString(@"Sorry, trial version cannot save tasks.", @"Alert sheet text"),	// sheet message
						  NSLocalizedString(@"Don't Save", @"Alert sheet button text"),             //  default button label
						  NSLocalizedString(@"Purchase...", @"Alert sheet button text"),             //  alternate button label
						  NSLocalizedString(@"Cancel", @"Alert sheet button text"),              //  other button label
						  [self window],	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  @selector(noSaveAlertSheetDidEnd:returnCode:contextInfo:),					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  (void *)callback,       // context info
						  NSLocalizedString(@"Please purchase to enable saving.", @"Alert sheet text"),	// additional text
						  nil);
		return;
	}
	
	// for compiled languages the script must be compiled before save can occur
	if (NO == [scriptEditViewController canSaveScript]) {
		
		NSBeginAlertSheet(
						  NSLocalizedString(@"Sorry, cannot save uncompiled script.", @"Alert sheet text"),	// sheet message
						  NSLocalizedString(@"Build", @"Alert sheet button text"),              //  default button label
						  NSLocalizedString(@"Don't Save", @"Alert sheet button text"),             //  alternate button label
						  NSLocalizedString(@"Cancel", @"Alert sheet button text"),              //  other button label
						  [self window],	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  @selector(compileAlertSheetDidEnd:returnCode:contextInfo:),					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  (void *)callback,       // context info
						  NSLocalizedString(@"If you want to save this task then build it now.", @"Alert sheet text"),	// additional text
						  nil);
		return;
	}
	
	// check if can save
	if (!_taskSpec.canSave || !_taskSpec.netClient.isConnected) {
		
		NSBeginAlertSheet(
						  NSLocalizedString(@"Sorry, remote machine not available.", @"Alert sheet text"),	// sheet message
						  nil,              //  default button label
						  NSLocalizedString(@"Don't Save", @"Alert sheet button text"),             //  alternate button label
						  nil,              //  other button label
						  [self window],	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  @selector(disconnectedAlertSheetDidEnd:returnCode:contextInfo:),					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  (void *)callback,       // context info
						  NSLocalizedString(@"You will not be able to save this task until the remote machine becomes available again.", @"Alert sheet text"),	// additional text
						  nil);
		return;
	}
	
	// increment the version revision if required
	if ([[_taskSpec script] versionRevisionAuto]) {
		[[_taskSpec script] incrementVersionRevision];
	}
	
	// update the modified date if required
	if ([[_taskSpec script] modifiedAuto]) {
		[[_taskSpec script] setModified:[NSDate date]];
	}
	
	// save action controller
	_saveActionSheetController = [[MGSSaveActionSheetController alloc] init];
	[_saveActionSheetController window]; // load it
	_saveActionSheetController.action = _taskSpec;
	_saveActionSheetController.delegate = self;
	_saveActionSheetController.modalWindowWillCloseOnSave = _closeWindowAfterSave;
	
	// show the sheet.
	[NSApp beginSheet:[_saveActionSheetController window] modalForWindow:[self window] 
		modalDelegate:self 
	   didEndSelector:@selector(saveActionSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:(void *)callback];
	
	return;
}

/*
 
 compile alert sheet ended
 
 */
- (void)compileAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	[sheet orderOut:self];

	BOOL continueWithReviewChanges = NO;

	switch (returnCode) {
			
			// compile
		case NSAlertDefaultReturn:
		
			// post edit mode should change notification to activate the script edit mode for this window
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteWindowEditModeShouldChange object:[self window] 
					userInfo:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kMGSMotherEditModeScript], MGSNoteModeKey, nil]];
			
			// post compile request notification
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteBuildScript object:[self window] userInfo:nil];

			break;
			
			// close and don't save or compile
		case NSAlertAlternateReturn:
			[self close];
			continueWithReviewChanges = YES;
			break;
			
			// cancel compile
		case NSAlertOtherReturn:
			break;
	}
	
	// context info may contain NSApp delegate selector when this method called as part of changes review
	if (contextInfo && [[NSApp delegate] respondsToSelector:(SEL)contextInfo]) {
		// the call to objc_msgSend works.
		// perform selector though has the same effect.
		//((void (*)(id, SEL, BOOL))objc_msgSend)([NSApp delegate], (SEL)contextInfo, continueWithReviewChanges);
		[[NSApp delegate] performSelector:(SEL)contextInfo withObject:[NSNumber numberWithBool:continueWithReviewChanges]];
	}
}
/*
 
 no save alert sheet ended
 
 */
- (void)noSaveAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	[sheet orderOut:self];
	
	BOOL continueWithReviewChanges = NO;
	
	switch (returnCode) {
			
			// close and don't save 
		case NSAlertDefaultReturn:
			[self close];
			continueWithReviewChanges = YES;
			break;
			
			// cancel 
		case NSAlertOtherReturn:
			break;
			
			// purchase
		case NSAlertAlternateReturn:
			[MGSLM buyLicences];
			break;
	}
	
	// context info may contain NSApp delegate selector when this method called as part of changes review
	if (contextInfo && [[NSApp delegate] respondsToSelector:(SEL)contextInfo]) {
		[[NSApp delegate] performSelector:(SEL)contextInfo withObject:[NSNumber numberWithBool:continueWithReviewChanges]];
	}
}
/*
 
 disconnected alert sheet ended
 
 */
- (void)disconnectedAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	[sheet orderOut:self];
	
	BOOL continueWithReviewChanges = NO;
	
	switch (returnCode) {
			
			// okay
		case NSAlertDefaultReturn:
						
			break;
			
			// close and don't save 
		case NSAlertAlternateReturn:
			[self close];
			continueWithReviewChanges = YES;
			break;

	}
	
	// context info may contain NSApp delegate selector when this method called as part of changes review
	if (contextInfo && [[NSApp delegate] respondsToSelector:(SEL)contextInfo]) {
		[[NSApp delegate] performSelector:(SEL)contextInfo withObject:[NSNumber numberWithBool:continueWithReviewChanges]];
	}
}

/*
 
 save alert panel ended
 
 */
- (void)saveActionSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	BOOL continueWithReviewChanges = YES;
	
	[sheet orderOut:self];

	switch (returnCode) {
		
		//
		// save attempted
		//
		case 1:
			
			//
			// save completed successfully
			//
			if (_saveActionSheetController.saveCompleted) {
				
				// mark document as no longer edited
				[[self window] setDocumentEdited:NO];
				
				// tell the script that it will exist on the server.
				// this will enable the script viewer to attempt and retrieve the
				// script source when required.
				[[_taskSpec script] setScriptStatus:MGSScriptStatusExistsOnServer];
				
				// update the task controllers copy of the script.
				// if the script does not yet exist in the controller
				// it is added.
				[_taskSpec.netClient.taskController updateScript:[_taskSpec script]];
				
				// post the saved notification
				[[NSNotificationCenter defaultCenter] 
					postNotificationName:MGSNoteActionSaved 
					object:_taskSpec 
					userInfo:nil];
			}
			
			if (_closeWindowAfterSave) {
				[self close];
			}
		break;
		
		//
		// save cancelled
		//
		case 0:
			continueWithReviewChanges = NO;
		break;
	}

	_saveActionSheetController = nil;

	// context info may contain NSApp delegate selector when this method called as part of changes review
	if (contextInfo && [[NSApp delegate] respondsToSelector:(SEL)contextInfo]) {
		[[NSApp delegate] performSelector:(SEL)contextInfo withObject:[NSNumber numberWithBool:continueWithReviewChanges]];
	}
	
}

/*
 
 prepare for save
 
 called when a save has been confirmed and save request is about to be sent
 
 */
- (void)prepareForSave
{
	// post notification that window is to be saved.
	// this notification will be received by the parameter edit view controllers which
	// will update their plists
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteEditWindowUpdateModel object:[self window]];
}

#pragma mark -
#pragma mark Notifications
/*
 
 windowWillClose notification
 
 NSWindowController will have registered us for this notification
 
 */
- (void)windowWillClose:(NSNotification *)notification
{
	[super windowWillClose:notification];
	
	if (delegate && [delegate respondsToSelector:@selector(editWindowWillClose:)]) {
		[delegate editWindowWillClose:self];
	}
	
	// remove observers
	@try {
		[_taskSpec removeObserver:self forKeyPath:@"script.modelDataKVCModified"];
		//[scriptEditViewController removeObserver:self forKeyPath:@"scriptCompiled"];
		[_taskSpec removeObserver:self forKeyPath:@"script.name"];
	} 
	@catch (NSException *e) {
		MLog(RELEASELOG, @"%@", [e reason]);
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];	// if do not remove crashing may occur - not sure if this is the case with GC
	
	// it is advised not to unregister from noticcation centre in finalize method 
	// so implement a dispose to clean up notifications etc
	[actionEditViewController dispose];
	[scriptEditViewController dispose];
	[self.requestViewController dispose];
	
	// remove our request view controller from singleton handler
	[[MGSRequestViewManager sharedInstance] removeObject:self.requestViewController];
}


/*
 
 window edit mode changed
 
 */
- (void)windowEditModeChanged:(NSNotification *)notification
{
	int mode = [[[notification userInfo] objectForKey:MGSNoteModeKey] intValue];
	//int prevMode = [[[notification userInfo] objectForKey:MGSNotePrevModeKey] intValue];
	_editMode = mode;
	
	NSAssert(mode >=0 && mode < [tabView numberOfTabViewItems], @"tabview invalid edit mode");
	
	// select tabview item for mode
	[tabView selectTabViewItemAtIndex:mode];

	// new mode
	switch (mode) {
			
		case kMGSMotherEditModeConfigure:
			break;
			
		case kMGSMotherEditModeScript:;
			
			NSString *scriptSource = [[[_taskSpec script] scriptCode] source];
			
			// show template sheet if no source
			if (!scriptSource || [scriptSource length] == 0) {
				[self showTemplateSheet:self];
			}
			
			break;
			
		case kMGSMotherEditModeRun:			
			break;
	}
}	

/*
 
 window edit mode will change
 
 */
- (void)windowEditModeWillChange:(NSNotification *)notification
{
	int mode = [[[notification userInfo] objectForKey:MGSNoteModeKey] intValue];
	int prevMode = [[[notification userInfo] objectForKey:MGSNotePrevModeKey] intValue];
	_editMode = mode;
	
	// previous mode
	switch (prevMode) {
			
			// configuration mode
		case kMGSMotherEditModeConfigure:
			//
			// update the edit window model parameter data.
			//
			// the loaded parameter view controllers register for this notification and update the windows action accordingly.
			//
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteEditWindowUpdateModel object:[self window]];
			
			// action changed notification for this window
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteActionSelectionChanged object:[self window] 
															  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_taskSpec, MGSActionKey, nil]];
			
			break;
			
			// script edit mode
		case kMGSMotherEditModeScript:
			// nothing required
			break;
	
			// mother run mode
		case kMGSMotherEditModeRun:	
			// nothing required
			break;
	}
	
	// new mode
	switch (mode) {
			
		case kMGSMotherEditModeConfigure:
			break;
			
		case kMGSMotherEditModeScript:
			break;
			
		case kMGSMotherEditModeRun:	
			// update request view controller.
			// whenever an action is successfuly run the MGSInputRequestView controller makes a deep copy of the completed action
			// and collects it so that previously run actions can re recalled.
			// MGSRequestViewController does not maintain a reference to its actionSpecifier.
			// the ref is maintained by the enclosed MGSInputRequestView instance.
			// thus when an action has been executued querying MGSRequestViewController for its action returns whatever completed action
			// is selected within the input view.
			// hence we need to reset the actual action we are editing here.
			self.requestViewController.actionSpecifier = [_taskSpec mutableDeepCopyAsNewInstance];	
			
			// post action change notification
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteActionSelectionChanged object:[self window]  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.requestViewController.actionSpecifier, MGSActionKey, nil]];

			break;
	}
	
	// edit mode changed
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteWindowEditModeDidChange object:[self window] userInfo:[notification userInfo]];

}

/*
 
 subview model data has been changed
 
 */
- (void)subViewModelEdited:(NSNotification *)notification
{
	#pragma unused(notification)
	
	// mark document as edited
	[[self window] setDocumentEdited:YES];
}

#pragma mark -
#pragma mark Tabview delegate methods
/*
 
 tab view did select tab view item
 
 */
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	#pragma unused(tabView)
	
	if ([tabViewItem identifier] == actionEditViewController) {
	} else if ([tabViewItem identifier] == scriptEditViewController) {
		
		// set first responder
		[[self window] makeFirstResponder:[tabViewItem initialFirstResponder]];

		
	} else if ([tabViewItem identifier] == self.requestViewController) {
	} else {
		NSAssert(NO, @"invalid tab view item identifier");
	}
}

#pragma mark -
#pragma mark Observing
/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	// model changed
	if (context == MGSModelChangedContext) {
		[[self window] setDocumentEdited:YES];
	}
	
	// script compiled
	else if (context == MGSScriptCompiledContext) {
		// note on multiple methods named xxxx
		// see http://www.cocoabuilder.com/archive/message/cocoa/2007/10/5/190367
		// this warning will appear when a message that is defined in two classes is send to an id.
		// in order to prompt the compiler it is necessary to define which class is being referenced.
		// note that [MGSImageManager sharedManager] returns an id
		NSImage *image = scriptEditViewController.scriptBuilt ? [[(MGSImageManager *)[MGSImageManager sharedManager] scriptCompiled] copy] 
																	: [[[MGSImageManager sharedManager] scriptNotCompiled] copy];
		
		[scriptStatusImageView setImage:image];
	}
	
	// script name changed
	else if (context == MGSScriptNameChangedContext) {
		[self updateWindowTitle];
	}
}
@end

@implementation MGSEditWindowController(Private)

@end
