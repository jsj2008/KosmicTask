#import "MGSAppController.h"
#import "MGSMother.h"
#import "MGSPrefsWindowController.h"
#import "MGSConfigWindowController.h"
#import "MGSExceptionController.h"
#import "MGSDebugController.h"
#import "MGSDebugHandler.h"
#import "MGSMotherServerController.h"
#import "MGSMotherServerLocalController.h"
#import "MGSMotherWindowController.h"
#import "MGSBrowserViewController.h"
#import "MGSNetClientManager.h"
#import "MGSNetClient.h"
#import "MGSErrorWindowController.h"
#import "MGSPreferences.h"
#import "MGSConnectingWindowController.h"
#import "MGSExportPluginController.h"
#import "MGSSendPluginController.h"
#import "MGSParameterPluginController.h"
#import "MGSAboutWindowController.h"
#import "ESSTimeTrialClass.h"
#import "NSBundle_Mugginsoft.h"
#import "MGSSystem.h"
#import "MGSLWindowController.h"
#import "MGSLM.h"
#import "MGSPath.h"
#import "MGSUser.h"
#import "UKCrashReporter.h"
#import "MGSScriptPlist.h"
#import "MGSRequestViewManager.h"
#import "MGSEditWindowController.h"
#import "MGSStopActionSheetController.h"
#import "MGSAddServerWindowController.h"
#import "NSImage+QuickLook.h"
#import <OpenFeedback/OpenFeedback.h>  
#import <Sparkle/SUUpdater.h> 
#import "MGSSaveConfigurationWindowController.h"
#import "MGSNetClientManager.h"
#import "MGSNotifications.h"
#import "MGSClientPowerManagement.h"
#import "MGSResultViewController.h"
#import "MGSApplicationMenu.h"
#import "MGSActionResultWindow.h"
#import "MGSLRWindowController.h"
#import "MGSAPLicenceCode.h"
#import "MGSAppTrial.h"
#import "MGSKosmicTask_vers.h"
#import "MGSLanguagePluginController.h"
#import <MGSFragaria/MGSFragaria.h>
#import "MGSResourceBrowserWindowController.h"
#import "MGSTempStorage.h"
#import "MGSBrowserViewControlStrip.h"
#import "MGSMainViewCOntroller.h"
#import "PLMailer.h"
#import "GRMustache.h"

// class extension
@interface MGSAppController()
- (void)doAppRequest:(id)sender;
- (void)restrictionAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void)closeSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (NSArray *)notableWindows;
- (BOOL)validateBundleVersion;
- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent;
- (NSDictionary*) customParametersForFeedbackReport;
@end

// private category
@interface MGSAppController (Private)
+ (void)initializeUserDefaults;
+ (void)initializePaths;
- (void)enableSuicide;
- (void)stopAllRunningActions;
- (void)reviewChangesAndQuitEnumeration:(NSNumber *)contNumber;
- (NSApplicationTerminateReply)checkForUnsavedDocumentsBeforeTerminating;
@end

@interface MGSAppController (Notifications)
- (void) appWillSleep:(NSNotification *)note;
- (void) appDidWake:(NSNotification *)note;
@end

@interface MGSAppController (PowerManagement)
- (BOOL)configurePowerManagement;
@end

@interface MGSAppController (Scriptability)
@end

@implementation MGSAppController

// synthesize properties
@synthesize connectingWindowController = _connectingWindowController;
@synthesize startupComplete = _startupComplete;
@synthesize exportPluginController = _exportPluginController;
@synthesize sendPluginController = _sendPluginController;
@synthesize parameterPluginController = _parameterPluginController;
@synthesize suicideTimeTrial = _suicideTimeTrial;
@synthesize operationQueue = _operationQueue;

#pragma mark Class methods
/*
 
 initialize the class
 
 */
+ (void)initialize
{
	// this gets called twice
	if ( self == [MGSAppController class] ) {
		// configure temp storage
		MGSTempStorage *storage = [MGSTempStorage sharedController];
		[storage deleteStorageFacility];
		
		[self initializeUserDefaults];
		[self initializePaths];
	}
}

/*
 
 + sharedInstance
 
 */
+ (MGSAppController *)sharedInstance
{
	return (MGSAppController *)[NSApp delegate];
}
#pragma mark Instance control

/*
 
 init
 
 */
- (id) init
{
	if ([super init]) {
		_debugHandler = [[MGSDebugHandler alloc] init];
		_startupComplete = NO;
		_suicideTimeTrial = nil;
		_alwaysTerminate = NO;
		_promptToStopRunningTasks = YES;
		
		}
	return self;
}

/*
 
 awake from nib
 
 */
- (void) awakeFromNib
{	
	_terminateAfterReviewChanges = NO;
	
	return;
}

#pragma mark -
#pragma mark Action handling
/*
 
 show preferences panel
 
 */
- (IBAction) showPreferencesPanel:(id)sender
{
	#pragma unused(sender)
	
	[[MGSPrefsWindowController sharedPrefsWindowController] showWindow:nil];
}

/*
 
 show licences window
 
 */
- (IBAction) showLicencesWindow:(id)sender
{
	#pragma unused(sender)
	
	[[MGSLWindowController sharedController] showWindow:nil];
}

/*
 
 show feedback window
 
 */
- (IBAction)showFeedbackWindow:(id)sender
{
	#pragma unused(sender)
	
	//[_openFeedbackController presentFeedbackPanelForSupport:self];
    if (YES) {
        [[OpenFeedback sharedController] presentFeedbackPanelForSupport:self];
    } else {
        [[FRFeedbackReporter sharedReporter] reportFeedback];
    }
}

/*
 
 - showReleaseNotes:
 
 */
- (IBAction)showReleaseNotes:(id)sender
{
#pragma unused(sender)
	
	if (NO) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"release-notes" ofType:@"txt"];
		[[NSWorkspace sharedWorkspace] openFile:path];
	} else {
		
		// get support URL string from app info.plist
		NSString *urlString = [NSBundle mainBundleInfoObjectForKey:@"MGSKosmicTaskReleaseNotesURL"];
		if (!urlString) return;
		
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
	}
}


/*
 
 - showGuide:
 
 */
- (IBAction)showGuide:(id)sender
{
#pragma unused(sender)
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"KosmicTask Guide" ofType:@"pdf"];
	[[NSWorkspace sharedWorkspace] openFile:path];
}

/*
 
 - showLicenceAgreement:
 
 */
- (IBAction)showLicenceAgreement:(id)sender
{
#pragma unused(sender)
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"KosmicTask EULA" ofType:@"pdf"];
	[[NSWorkspace sharedWorkspace] openFile:path];
}

/*
 
 - onlineHelp:
 
 */
- (IBAction)onlineHelp:(id)sender
{
	#pragma unused(sender)
	
	// get help URL string from app info.plist
	NSString *urlString = [NSBundle mainBundleInfoObjectForKey:@"MGSHelpURL"];
	if (!urlString) return;
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];	
}


/*
 
 - onlineSupport:
 
 */
- (IBAction)onlineSupport:(id)sender
{
#pragma unused(sender)
	
	// get support URL string from app info.plist
	NSString *urlString = [NSBundle mainBundleInfoObjectForKey:@"MGSSupportURL"];
	if (!urlString) return;
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];	
}

/*
 
 - onlineForum:
 
 */
- (IBAction)onlineForum:(id)sender
{
#pragma unused(sender)
	
	// get support URL string from app info.plist
	NSString *urlString = [NSBundle mainBundleInfoObjectForKey:@"MGSForumURL"];
	if (!urlString) return;
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];	
}
/*
 
 show Configuration panel 
 */
- (IBAction) showConfigurationPanel:(id)sender
{	
	#pragma unused(sender)
	/*if (!_configController) {
		_configController = [[MGSConfigWindowController alloc] initWithServerController:self.server];
	}
	[_configController showWindow:nil];
	 */
}

/*
 
 configure internet sharing
 
 */
- (IBAction)configureInternetSharing:(id)sender
{
#pragma unused(sender)
	
	[[MGSPrefsWindowController sharedPrefsWindowController] showInternetPreferences];
}

/*
 
 configure local sharing
 
 */
- (IBAction)configureLocalSharing:(id)sender
{
#pragma unused(sender)
	
	[[MGSPrefsWindowController sharedPrefsWindowController] showLocalNetworkPreferences];
}
/*
 
 send log
 
 */
- (IBAction)sendLog:(id)sender
{
#pragma unused(sender)
	
	PLMailer *mailer = [[PLMailer alloc] init];
	
	NSString *email = [NSBundle mainBundleInfoObjectForKey:@"MGSSupportEmail"];
	if (!email) {
		email = @"support@mugginsoft.com";
	}
	[mailer setTo:email];
	[mailer setSubject:@"KosmicTask log"];
	
	NSString *bodyLeader = @"Problem description:\n\n\n\nLog:\n\n";
	NSMutableAttributedString *body = [[NSMutableAttributedString alloc] initWithString:bodyLeader];
	NSString *logText = [[MLog sharedController] logFileText];
	[body appendAttributedString:[[NSAttributedString alloc] initWithString:logText]];
	[mailer setBody:body];
	[mailer setType:PLMailerUrlType];
	[mailer send:self];
}


#pragma mark -
#pragma mark Window handling
/*
 
 load the main application window
 
 */
- (void)loadMotherWindow
{
	if (!_motherWindowController) {
		_motherWindowController = [[MGSMotherWindowController alloc] init];
	}
	[_motherWindowController window];	// load the window
	
	[_motherWindowController showWindow:self];
}

/*
 
 show mother window
 
 */
- (void)showMotherWindow
{
	[[_motherWindowController window] makeKeyAndOrderFront:self];
}

/*
 
 application window
 
 */
- (NSWindow *)applicationWindow
{
	return [_motherWindowController window];
}

/*
 
 show the application wide error window
 
 */
- (void)showErrorWindow:(id)sender
{
	#pragma unused(sender)
	[_errorWindowController showWindow:self];
}

/*
 
 show the application wide resource browser
 
 */
- (void)showResourceBrowserWindow:(id)sender
{
#pragma unused(sender)
	[[MGSResourceBrowserWindowController sharedController] showWindow:self];
}

/*
 
 order front about window
 
 */
- (IBAction) orderFrontCustomAboutPanel: (id) sender
{
	#pragma unused(sender)
	[[MGSAboutWindowController sharedInstance] window];
	[[MGSAboutWindowController sharedInstance] showWindow:self];
}

/*
 
 show finder quicklook
 
 */
- (void)showFinderQuickLook:(NSString *)filePath
{
	// show finder quicklook
	[NSImage showFinderQuickLook:filePath];
}

/*
 
 array of notable application windows
 
 notable windows are those that cause an optional prompt
 to be displayed when more than one is open and the app is closed
 
 */
- (NSArray *)notableWindows
{
	NSMutableArray *openWindows = [NSMutableArray arrayWithCapacity:10];
	for (NSWindow *window in [NSApp windows]) {
		if ([window isKindOfClass:[MGSActionExecuteWindow class]] ||
			[window isKindOfClass:[MGSActionResultWindow class]]) {
			
			if ([window isVisible]) {
				[openWindows addObject:window];
			}
		}
	}
	
	return [openWindows copy];
}


#pragma mark -
#pragma mark Instance methods
/*
 
 startup complete
 
 */
- (void)setStartupComplete:(BOOL)value
{
	_startupComplete = value;
	
	// if startup complete then show main window and hide connecting window
	if (_startupComplete) {
		[self showMotherWindow];	// may already be visible if launch window not displayed
		
		// hide connecting window
		if ([self connectingWindowController]) {
			[[self connectingWindowController] hideWindow:self];
		}
	}
	
    /*
    
     FRFeedbackReporter can also report crashes but only for
     the main app not for auxiliary executables.
     
     */
    
	// check if crash occurred.
	// not sure what will occur if two components crash at the same time!
	// check for application crash
	UKCrashReporterCheckForCrash(nil, MLogFilePath());
	
	// check for server crash
	UKCrashReporterCheckForCrash(@"KosmicTaskServer", MLogFilePath());
	
    /* 
     
     Note that when the plugins are loaded we could check for 
     crashes in each of the task runners
     
     */
    for (MGSLanguagePlugin *plugin in [[MGSLanguagePluginController sharedController] instances]) {
        
        // determine if plugin is a Cocoa lang
        MGSLanguageProperty *langProp = [[plugin languagePropertyManager] propertyForKey:MGS_LP_IsCocoaBridge] ;
        BOOL isCocoaLang = [[langProp value] boolValue];
        
        // do we want to send Cocoa crash reports
        BOOL sendCocoaCrashReport = [[NSUserDefaults standardUserDefaults] boolForKey:MGSSendCocoaTaskCRashReports];
        
        // Cocoa based languages can be crashed relatively easily causing
        // crash reports to be returned that relate to problems with the user's task script
        // rather than with the applciation.
        if (!isCocoaLang || sendCocoaCrashReport) {
            NSString *process = plugin.taskProcessName;
            UKCrashReporterCheckForCrash(process, nil);
        }
    }
    
}


/*
 
 application name
 
 */
- (NSString *)applicationName
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleName"];
}

/*
 
 toggle the run state
 
 no modifier key
 
 if the action is running terminate it.
 if the action is stopped/paused run it.
 
 command modifier key
 if the action is running pause it
 
 */
- (IBAction)toggleRunState:(id)sender
{
	NSUInteger flags = [[NSApp currentEvent] modifierFlags];
	BOOL modify = (flags & NSCommandKeyMask) > 0;
	NSString *noteName = nil;
	
	// toggle
	if (modify) {
		// toggle play/stop
		noteName = MGSNoteAppToggleExecuteTerminateTask;
	} else {
		// toggle play/pause
		noteName = MGSNoteAppToggleExecutePauseTask;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:noteName object:sender userInfo:nil];
}

#pragma mark Trial Version Restrictions

/*
 
 restriction was applied
 
 non descriptive sensitive message name
 */
- (void)appRequest {
	[self performSelector:@selector(doAppRequest:) withObject:self afterDelay:0];
}
/*
 
 show restriction alert
 
 */
- (void)doAppRequest:(id)sender
{
	#pragma unused(sender)
	NSBeginAlertSheet(
					  NSLocalizedString(@"Sorry, trial version usage limit has been reached.", @"Alert sheet text"),	// sheet message
					  nil,             //  default button label
					   NSLocalizedString(@"Purchase...", @"Alert sheet button text"),             //  alternate button label
					  nil,              //  other button label
					  [self applicationWindow],	// window sheet is attached to
					  self,                   // we’ll be our own delegate
					  @selector(restrictionAlertSheetDidEnd:returnCode:contextInfo:),					// did-end selector
					  NULL,                   // no need for did-dismiss selector
					  NULL,       // context info
					  NSLocalizedString(@"Restart the application to continue using the trial version.\n\nPlease purchase to remove trial limitations.", @"Alert sheet text"),	// additional text
					  nil);
	return;
}

#pragma mark Sheet handling
/*
 
 restriction alert sheet ended
 
 */
- (void)restrictionAlertSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	#pragma unused(contextInfo)
	
	[sheet orderOut:self];
	
	switch (returnCode) {
			
			// close and don't save 
		case NSAlertDefaultReturn:
		case NSAlertOtherReturn:
			break;
			
			// purchase
		case NSAlertAlternateReturn:
			[MGSLM buyLicences];
			break;
	}
}


/*
 
 close window sheet ended
 
 */
- (void)closeSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
#pragma unused(contextInfo)
	
	[sheet orderOut:self];
	
	if (returnCode == YES) {
		[NSApp replyToApplicationShouldTerminate:YES];
	} else {
		[NSApp replyToApplicationShouldTerminate:NO];
	}
	
}

#pragma mark Versioning

/*
 
 - validateBundleVersion
 
 */
- (BOOL)validateBundleVersion
{
	/*
	 
	 validate the compiled in version matches bundle version.
	
	 the bundle version may be updated in the info plist but the compiled in version
	 requires agvtool to be run. this important because it is the compiled in version
	 change that triggers application task updating by the server component.
	 
	 a release bug occured when the info.plist was updated by hand and the compilied in version
	 remained as was. this meant that the application tasks were not updated.
	 
	 
	 */
	NSString *bundleVersion = [NSBundle mainBundleInfoObjectForKey:@"CFBundleVersion"];
	NSString *compiledInVersion = [NSString stringWithFormat:@"%ld", (long)MGSKosmicTaskVersionNumber];
	
	/*
	 
	 if the versions do not match then the build is bad
	 
	 */
	if (![bundleVersion isEqualToString:compiledInVersion]) {
		NSRunAlertPanel(@"BUILD ERROR", @"Bundle version does not match compiled in version. Application tasks will not update correctly.", nil, nil, nil, nil);
		
		if (NO) {
			[NSApp terminate:self];
		}
	}
	
	return YES;
}
/*
 
 build string for display 
 
 */
- (NSString *)buildStringForDisplay 
{
	// get version from bundle info.plist
	NSString *buildLabel = NSLocalizedString(@"Build", @"Application build label");
    NSString *buildNumber = [NSBundle mainBundleInfoObjectForKey:@"MGSBuildNumber"];

#if __LP64__
    NSString *buildArch = @"64 bit";
#else
    NSString *buildArch = @"32 bit";
#endif
    
	NSString *buildString = [NSString stringWithFormat: @"%@: %@ %@" , buildLabel, buildNumber, buildArch];
    
    // sandboxing
	NSString *sandboxLabel = NSLocalizedString(@"Sandboxed", @"Application sandbox label");
    NSString *sandboxState = ( self.inSandbox  ? @"Yes" : @"No");
	NSString *sandboxString = [NSString stringWithFormat: @"%@: %@" , sandboxLabel, sandboxState];
	
#ifdef MGS_SUBVERSION_INFO_AVAILABLE
    
	// if subversion revision found then append it
    NSString *revisionString = [NSBundle mainBundleInfoObjectForKey:@"MGSSubversionRevision"];
    if (revisionString) {
        buildString = [NSString stringWithFormat:@"%@ (%@)", buildString, revisionString];
    }
    
#endif
    
    NSString *valueString = [NSString stringWithFormat:@"%@\n%@", buildString, sandboxString];
    
	return valueString;
}

/*

 - inSandbox
 
 */
- (BOOL)inSandbox
{
    NSDictionary* environ = [[NSProcessInfo processInfo] environment];
    BOOL inSandbox = (nil != [environ objectForKey:@"APP_SANDBOX_CONTAINER_ID"]);
    
    return inSandbox;
}
/*
 
 application version string suitable for displaying
 
 */
- (NSString *)versionStringForDisplay
{
	// get version from bundle info.plist
	NSString *format = NSLocalizedString(@"Version: %@", @"Application version format string");
	NSString *versionString = [NSString stringWithFormat: format, [NSBundle mainBundleInfoObjectForKey:@"CFBundleShortVersionString"]];

	// if bundle version found then append it
	NSString *bundleString = [NSBundle mainBundleInfoObjectForKey:@"CFBundleVersion"];
	if (bundleString) {
		versionString = [NSString stringWithFormat:@"%@ (%@)", versionString, bundleString];
	}
	
	// if code is suicidal then confirm this
	if (_suicideTimeTrial) {
		format = NSLocalizedString(@" (Expires: %@)", @"Application expiry date format string");
		
		// format suicide date
		NSDate *date = [_suicideTimeTrial endDate];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		NSString *formattedDateString = [dateFormatter stringFromDate:date];
	   
		versionString = [versionString stringByAppendingFormat:format, formattedDateString];
	}
	
	return versionString;
}

#pragma mark Operation queue handling
/*
 
 operation queue
 
 */
- (NSOperationQueue *)operationQueue
{
	// lazy allocation
	if (!_operationQueue) {
		_operationQueue = [[NSOperationQueue alloc] init];
	}
	
	return _operationQueue;
}

/*
 
 queue show finder quick look
 
 */
- (void)queueShowFinderQuickLook:(NSString *)filePath
{
	// create our invocation object
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
									selector:@selector(showFinderQuickLook:) object:filePath];
	
	if (theOp) {
		
		MLog(DEBUGLOG, @"quicklook preview operation queued for: %@", filePath);
		
		// queue the op
		[self.operationQueue addOperation:theOp];
	} else {
		MLog(DEBUGLOG, @"quicklook preview operation NOT queued for: %@",filePath);
	}
}

/*
 
 queue show finder quick look
 
 */
- (void)queueOpenFileWithDefaultApplication:(NSString *)filePath
{
	// create our invocation object
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
									selector:@selector(openFileWithDefaultApplication:) object:filePath];
	if (theOp) {
		
		MLog(DEBUGLOG, @"open file with default app operation queued for: %@", filePath);
		
		// queue the op
		[self.operationQueue addOperation:theOp];
	} else {
		MLog(DEBUGLOG, @"open file with default app NOT queued for: %@",filePath);
	}
}

#pragma mark File handling
/*
 
 open file with default application associated with its type
 
 */
- (BOOL)openFileWithDefaultApplication:(NSString *)fullPath
{
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	
	return [workspace openFile:fullPath];
}

/*
 
 check for unsaved documents on net client.
 
 if net client is nil then all unsaved documents are checked
 
 */
- (NSApplicationTerminateReply)checkForUnsavedDocumentsOnClient:(MGSNetClient *)netClient terminating:(BOOL)terminating
{
	//
	// check for unsaved configuration on client
	//
	if ([[MGSNetClientManager sharedController] checkForUnsavedConfigurationOnClient:netClient 
		 terminating:terminating] == NSTerminateCancel) {
		return NSTerminateCancel;
	}
	
	_netClient = netClient;
		
	//==========================================
	// check for unsaved documents on net client
	//==========================================	
	NSArray *editWindowControllers = _netClient != nil ? [_motherWindowController editWindowControllersForNetClient:_netClient] :
						[_motherWindowController editWindowControllers];
	
    NSUInteger editControllerCount = [editWindowControllers count];
    NSUInteger needsSaving = 0;
	
    // Determine if there are any unsaved documents...
    while (editControllerCount--) {
        MGSEditWindowController *controller = [editWindowControllers objectAtIndex:editControllerCount];
        if ([[controller window] isDocumentEdited]) needsSaving++;
    }
	
	// if terminating then terminate when review complete
	_terminateAfterReviewChanges = terminating;
	
    if (needsSaving > 0) {
		
		// If we only have 1 unsaved document,
		// we skip the "review changes?" panel
		if (needsSaving > 1) { 
			
			NSString *alertTitleFormat = nil;
			if (_terminateAfterReviewChanges) {
				alertTitleFormat =  NSLocalizedString(@"You have %d documents with unsaved changes. Do you want to review these changes before quitting?", 
													  @"Title of alert panel which comes up when user chooses Quit and there are multiple unsaved documents.");

			} else {
				alertTitleFormat =  NSLocalizedString(@"You have %d documents with unsaved changes. Do you want to review these changes before leaving configuration?", 
													  @"Title of alert panel which comes up when user chooses Quit and there are multiple unsaved documents.");
			}
			
			NSString *title = [NSString stringWithFormat: alertTitleFormat, needsSaving];
			NSBeginAlertSheet(title,
							  NSLocalizedString(@"Review Changes...", 
												@"Choice (on a button) given to user which allows him/her to review all unsaved documents if he/she quits the application without saving them all first."),              //  default button label
							  NSLocalizedString(@"Discard Changes",
												@"Choice (on a button) given to user which allows him/her to quit the application even though there are unsaved documents."),             //  alternate button label
							  NSLocalizedString(@"Cancel", @"Alert sheet button text"),              //  other button label
							  [_motherWindowController window],	// window sheet is attached to
							  self,                   // we’ll be our own delegate
							  @selector(reviewSheetDidEnd:returnCode:contextInfo:),					// did-end selector
							  NULL,                   // no need for did-dismiss selector
							  nil,                 // context info
							  NSLocalizedString(@"If you don't review your documents, all changes will be lost.", 
												@"Warning in the alert panel which comes up when user chooses Quit and there are unsaved documents."),	// additional text
							  nil);
			
        } else {
			// review changes
			[self reviewChangesAndQuitEnumeration:[NSNumber numberWithBool:YES]];
		}
		
		return NSTerminateCancel;
    }
	
	// terminate approved
	return NSTerminateNow;
}

#pragma mark Menu handling

/*
 
 set send to menu.
 this is constructed dynamically
 
 */
- (void)setSendToMenu:(NSMenu *)menu 
{
	for (NSMenuItem *menuItem in [menu itemArray]) {
		[menuItem setTarget:self];
	}
	[_sendToMenuItem setSubmenu:menu];
}
/*
 
 send to menu
 
 */
- (NSMenu *)sendToMenu
{
	return [_sendToMenuItem submenu];
}
/*
 
 task menu
 
 */
- (NSMenu *)taskMenu {
	return _taskMenu;
}

/*
 
 validate menu item.
 
 this will be called for nil target menu actions
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL theAction = [menuItem action];
	NSCellStateValue state = NSOffState;
	eMGSMotherRunMode runMode = [_motherWindowController runMode];
	
	//
	// result actions
	//
	// a result may be displayed. if so use it as the target.
	// message will have risen up the responder chain.
	//
	// save result
	// quick look result
	//
	if (theAction == @selector(saveResult:) || 
		theAction == @selector(sendResult:) || 
		theAction == @selector(quicklook:) ||
		theAction == @selector(viewMenuViewAsSelected:)
		) {

		// get the current result view controller.
		// dynamic.
		MGSResultViewController *resultViewController = [self activeResultViewController];

		if (resultViewController) {
			return [resultViewController validateMenuItem:menuItem];
		}
		
		return NO;
		
	// application menu view mode selected
	} else if (theAction == @selector(viewMenuModeSelected:)) {
		
		// we need to reset the menu state every time as we may have selected a different client.
		switch ([menuItem tag]) {
			case kMGS_MENU_TAG_VIEW_MODE_PUBLIC:
				if(runMode == kMGSMotherRunModePublic) state = NSOnState;
				break;
				
			case kMGS_MENU_TAG_VIEW_MODE_TRUSTED:
				if(runMode == kMGSMotherRunModeAuthenticatedUser) state = NSOnState;
				break;
				
			case kMGS_MENU_TAG_VIEW_MODE_CONFIGURATION:
				if(runMode == kMGSMotherRunModeConfigure) state = NSOnState;
				break;
				
			default:
				NSAssert(NO, @"invalid menu tag");
		}
		[menuItem setState:state];
	
	// Resource browser window
	} else if (theAction == @selector(showResourceBrowserWindow:)) {
		
		// only available to authenticated users ?
		if (runMode == kMGSMotherRunModePublic && NO) {
			return NO;
		}
	}
	
	return YES;
}

/*
 
 view menu mode item selected
 
 */
- (IBAction)viewMenuModeSelected:(id)sender
{
	if (![sender isKindOfClass:[NSMenuItem class]]) {
		return;
	}
	NSMenuItem *menuItem = sender;
	eMGSMotherRunMode mode = kMGSMotherRunModePublic;
	
	switch ([menuItem tag]) {
		case kMGS_MENU_TAG_VIEW_MODE_PUBLIC:
			mode = kMGSMotherRunModePublic;
			break;
			
		case kMGS_MENU_TAG_VIEW_MODE_TRUSTED:
			mode = kMGSMotherRunModeAuthenticatedUser;
			break;
			
		case kMGS_MENU_TAG_VIEW_MODE_CONFIGURATION:
			mode = kMGSMotherRunModeConfigure;
			break;
			
		default:
			NSAssert(NO, @"invalid menu tag");
	}
		
	// post notification requesting app run mode change
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:mode], MGSNoteModeKey , nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAppRunModeShouldChange object:[self applicationWindow] userInfo:dict];
}



#pragma mark View handling

/*
 
 active result view controller
 
 get active result view controller for current window
 
 */
- (MGSResultViewController *)activeResultViewController
{
	// get key window
	NSWindow *window = [NSApp keyWindow];
	if ([window delegate] == (id)self) return nil; // no loops please
	
	// get active result view controller from the window delegate if available.
	// windows that contain results must implement the MGSResultWindowDelegate protocol 
	if ([window delegate] && [[window delegate] respondsToSelector:@selector(activeResultViewController)]) {
		return [[window delegate] performSelector:@selector(activeResultViewController)];
	}
		
	return nil;
}

#pragma mark Result handling
/*
 
 these result orientated messages may rise up the responder chain to here.
 dispatch them to the active request view for handling.
 
 note that we also -validateMenuItem: for the same actions.
*/
/*
 
 save result
 
 */
- (IBAction)saveResult:(id)sender
{
	[[self activeResultViewController] saveResult:sender];
}

/*
 
 send result
 
 */
- (IBAction)sendResult:(id)sender
{
	[[self activeResultViewController] sendResult:sender];
}


/*
 
 quicklook result
 
 */
- (IBAction)quicklook:(id)sender
{
	[[self activeResultViewController] quicklook:sender];
}

/*
 
 view menu view as selected
 
 */
- (IBAction)viewMenuViewAsSelected:(id)sender
{
	[[self activeResultViewController] viewMenuViewAsSelected:sender];
}

#pragma mark -
#pragma mark URL handling

/*
 
 - handleURLEvent:withReplyEvent:
 
 */
- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
#pragma unused(replyEvent)
	
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];

	[[MGSResourceBrowserWindowController sharedController] resolveURL:url];
}

#pragma mark -
#pragma mark FRFeedbakReporter delegate
- (NSDictionary*) customParametersForFeedbackReport
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:@"KosmicTask" forKey:@"application"];
    
    return dict;
}

@end

#pragma mark -
#pragma mark NSApplicationDelegate category

@implementation MGSAppController (NSApplicationDelegate)

/*
 
 open registered file type
 
 */
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	#pragma unused(theApplication)
	
	// licence file
	if (NSOrderedSame == [[filename pathExtension] caseInsensitiveCompare:@"ktlic"]) {

		// add it
		if ([[MGSLM sharedController] addItemAtPath:filename withDictionary:nil]) {
			[[MGSLM sharedController] showSuccess];
		} else {
			[[MGSLM sharedController] showLastError];
		}
		
		return YES;
	}
	
	// mother document
	if (NSOrderedSame == [[filename pathExtension] caseInsensitiveCompare:MGSScriptPlistExt]) {
		return YES;
	}
	
	// cannot handle other file types
	return NO;
}

// terminate app when last window closes
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	#pragma unused(theApplication)
	
	return YES;
}

- (void)reportException:(NSException *)theException
{	
	MLog(DEBUGLOG, @"Exception name: %@ reason: %@", [theException name], [theException reason]);

	// show panel if reqd
	if ([[NSUserDefaults standardUserDefaults] boolForKey:MGSEnableExceptionPanel]) {
		if (_exceptionController == nil) {
			_exceptionController = [[MGSExceptionController alloc] init];
		}
		[_exceptionController showWindow:self];
	} 
}

/*
 
 application did finish launching
 
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{	
    [[FRFeedbackReporter sharedReporter] setDelegate:self];
    
	//
	// validate that min os is present
	//
	if (![[MGSSystem sharedInstance] OSVersionIsSupported]) {
		
		NSString *title = NSLocalizedString(@"Unsupported Operating System Version", @"Invalid OS version alert title");
		NSString *format =  NSLocalizedString(@"KosmicTask requires at least OS X version %@.\n\nApplication will terminate.", @"Invalid OS version alert message");
		NSString *message =  [NSString stringWithFormat:format, [[MGSSystem sharedInstance] minOSVersionSupported]];
		
		NSRunAlertPanel(title, message, @"OK",nil,nil);
		[NSApp terminate:nil];
	}
	
	//
	// validate bundle version
	//
	[self validateBundleVersion];
	
	//
	// beta release code must die
	//
	[self enableSuicide];
	
	//
	// show licence reminder for trial
	//
	if (MGSAPLicenceIsRestrictiveTrial()) {
		_reminderWindowController = [[MGSLRWindowController alloc] init];
		
		//
		// if trial expired then we go no further.
		// if a window is not currently displayed the app will exit.
		//
		if ([NSApp runModalForWindow:[_reminderWindowController window]] == MGS_APP_TRIAL_EXPIRED) {
			return;
		}
	} else {
		
		// cleanup the trial.
		MGSAppTrialCleanup();
	}
		
	// configure power management
	[self configurePowerManagement];

	// load the connecting window and show 
	if (NO) {
		//if ([[NSUserDefaults standardUserDefaults] boolForKey:MGSDisplayLaunchWindow]) {
			_connectingWindowController = [[MGSConnectingWindowController alloc] init];
			[_connectingWindowController showWindow:self];
		//} 
	}
	
	// initialize the debug handler
	[_debugHandler applicationDidFinishLaunching:aNotification];
	
	// load the error window controller
	_errorWindowController = [[MGSErrorWindowController alloc] init];
	[_errorWindowController window]; // load the window
	[MGSError setWindowController:_errorWindowController];
	
	// launch the local server
	_serverLocalController = [[MGSMotherServerLocalController alloc] init];
	[_serverLocalController launchIfNotRunning];
	
	// start searching for network services
	[[MGSNetClientManager sharedController] searchForServices];

	// load language plugins
	[[MGSLanguagePluginController sharedController] loadAllPlugins];
	[[MGSLanguagePluginController sharedController] loadPluginResources];
	
	// load export plugins
	_exportPluginController = [[MGSExportPluginController alloc] init];
	[_exportPluginController loadAllPlugins];
	
	// load send plugins
	_sendPluginController = [[MGSSendPluginController alloc] init];
	[_sendPluginController loadAllPlugins];	
	
	// load parameter plugins
	_parameterPluginController = [[MGSParameterPluginController alloc] init];
	[_parameterPluginController loadAllPlugins];	
	
	
	// load the main app window
	[self loadMotherWindow];	
	
	// start the logging timer
	[[MLog sharedController] startTimer];
	
	// register url handler for the getURL event.
	// see the info.plist for the custom url schemes that we will respond to
	[[NSAppleEventManager sharedAppleEventManager] 
		setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) 
		forEventClass:kInternetEventClass 
		andEventID:kAEGetURL];
    
    // configure text rendering
    [GRMustacheConfiguration defaultConfiguration].contentType = GRMustacheContentTypeText;
}

/*
 
 application will terminate
 
 */
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	#pragma unused(aNotification)
	
	// save plugin settings
	[[MGSLanguagePluginController sharedController] savePluginSettings];
	
	// save preferences?
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// kill the local server if not starting server at login
	if (![[NSUserDefaults standardUserDefaults] boolForKey:MGSDefaultStartAtLogin]) {
		[_serverLocalController kill];
	}

	[[MGSTempStorage sharedController] deleteStorageFacility];
}

/*
 
 application should terminate
 
 */
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	#pragma unused(sender)
	
	// note that the licence manager may wish to force termination of the application
	// so make sure that it occurs.	
	if (_alwaysTerminate) {
		return NSTerminateNow;
	}
	
	//===============================================
	// if actions processing 
	//
	// prompt user to quit executing actions
	//
	//===============================================
	NSInteger processingCount = [[MGSRequestViewManager sharedInstance] processingCount];
	if (processingCount > 0 && _promptToStopRunningTasks) {
		
		// this is probably nuts.
		// most likely easier to use NSBeginAlertSheet than define a controller + NIB etc
		if (!_stopActionSheetController) {
			_stopActionSheetController = [[MGSStopActionSheetController alloc] init];
			[_stopActionSheetController window];
		}
		_stopActionSheetController.processingCount = processingCount;
		
		// show the sheet.
		// NOTE:
		//
		// NSRunAlertPanel will block the run loop to the window while it is displayed.
		// NSBeginAlertSheet will not.
		//
		[NSApp beginSheet:[_stopActionSheetController window] modalForWindow:[_motherWindowController window] 
			modalDelegate:self 
		   didEndSelector:@selector(stopActionSheetDidEnd:returnCode:contextInfo:)
			  contextInfo:NULL];
 
		// if return NSTerminateLater then window events seem to be blocked.
		// indeed returning NSTerminateLater stops the main run loop!!!
		// http://www.cocoabuilder.com/archive/message/cocoa/2006/5/3/162656
		// things never recover after that.
		// just return NSTerminateCancel and quit manually later.
		//
		// release notes for 10.4 state:
		/*
		NSApplication
		
		With the addition of the document-modal state implied by sheets, it has become difficult for application delegates
		 to respond with YES or NO to -applicationShouldTerminate:. Frequently when asked to terminate, an application wants 
		 to present document-modal alerts (sheets) for dirty documents, giving the user the opportunity to save the documents, 
		 quit without saving, or cancel the termination.
			
		In order to allow applications to do this without needing to enter some outer modal loop, applicationShouldTerminate:, 
		 has been redefined. This method now returns an emumerated type rather than a BOOL. Possible values are: 
		 NSTerminateNow to allow the termination to proceed, NSTerminateCancel to cancel the termination, 
		 or NSTerminateLater to postpone the decision. If a delegate returns NSTerminateLater, 
		 NSApplication will enter a modal loop waiting for a call to -replyToApplicationShouldTerminate. 
		 The delegate must call -replyToApplicationShouldTerminate with YES or NO once it is decided whether the 
		 application can terminate. NSApplication will run the runloop in NSModalPanelRunLoopMode while waiting 
		 for the delegate to make this call.
				
		Unfortunately, this implementation does not allow -[NSApplication terminate:] to be called from a secondary thread. 
		 If your application does this, you will get a console error message, and the call to terminate: will have no effect. 
		 You can workaround this limitation by messaging the main thread of your application to perform the call to terminate:.
		
		For binary compatibility, a return value of NO is recognized as NSTerminateCancel, and a return value of 
		 YES as NSTerminateNow.
		// return values for -applicationShouldTerminate:
		enum {
			NSTerminateNow,
			NSTerminateCancel,
			NSTerminateLater
		} NSApplicationTerminateReply;
		@interface NSObject(NSApplicationDelegate)
		(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
		...
		@end
		 */
		return NSTerminateCancel;
	}

	// if running task prompting was off reactivate for the next
	// terminate request
	_promptToStopRunningTasks = YES;
	
	//===============================================
	// if docs unsaved 
	//
	// check for unssaved dicuments
	//
	//===============================================
	if ([self checkForUnsavedDocumentsBeforeTerminating] == NSTerminateCancel) {
		return NSTerminateCancel;
	}
	
	//===============================================
	// if multiple tabs or windows open 
	//
	// prompt user to confirm close
	//
	//===============================================
	BOOL openTabOrWindowAlertPref = [[NSUserDefaults standardUserDefaults] boolForKey:MGSConfirmClosingMultipleTabsOrWindows];
	NSUInteger windowCount = [[self notableWindows] count];
	NSInteger taskTabCount = [_motherWindowController taskTabCount];
	BOOL confirmClose = openTabOrWindowAlertPref && (windowCount > 1 || taskTabCount > 1);
	if (confirmClose) {
		
		NSString *message =@"";

		if (windowCount > 1 && taskTabCount == 1) {
			message = NSLocalizedString(@"Multiple windows are still open.", @"Close window text");
		} else if (windowCount == 1 && taskTabCount > 1) {
			message = NSLocalizedString(@"Multiple tabs are still open.", @"Close window text");
		} else {
			message = NSLocalizedString(@"Multiple tabs and windows are still open.", 
										@"Close window text when multiple tabs/windows are open.");
		}
		
		NSBeginAlertSheet( NSLocalizedString(@"Are you sure you want to close this window?", @"Alert sheet title"),
						  nil, // defaults to OK
						  nil,
						  NSLocalizedString(@"Cancel", @"Alert sheet button text"),              //  other button label
						  [_motherWindowController window],	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  @selector(closeSheetDidEnd:returnCode:contextInfo:),					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  nil,                 // context info
						  message,
						  nil);
		
		// end of the chain
		return NSTerminateLater;
	}
	
	return NSTerminateNow;
}

/*
 
 prompt to review alert sheet ended
 
 */
- (void)reviewSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{	
	#pragma unused(sheet)
	#pragma unused(contextInfo)
	
	// review cancelled
	switch (returnCode) {
			
		// review cancelled
		case NSAlertOtherReturn:
			return;
			
		// discard changes
		case NSAlertAlternateReturn:
			
			// is termination required
			if (_terminateAfterReviewChanges) {
			
				// ensure termination completes
				_alwaysTerminate = YES;
				[NSApp terminate:self];
			} else {
				
				// we are not terminating so close all edit windows silently
				[_motherWindowController closeEditWindowsSilentlyForNetClient:_netClient];
				
			}
			
			return;
			
		// review changes 
		case NSAlertDefaultReturn:
			[self reviewChangesAndQuitEnumeration:[NSNumber numberWithBool:YES]];
			break;
	}
	
}

/*
 
 prompt to stop action alert sheet ended
 
 */
- (void)stopActionSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	#pragma unused(sheet)
	#pragma unused(contextInfo)
	
	// discard our controller.
	// the sheet may have been modified so its best
	// just to start with a new instance if required.
	_stopActionSheetController = nil;
	
	// default to always prompt to stop tunning
	_promptToStopRunningTasks = YES;
	
	switch (returnCode) {
			
		// stop cancelled
		case 0:
		return;
			
			// continue - all tasks were stopped
		case 1:
			break;
			
			// continue - all tasks could not be stopped
		case 2:
			_promptToStopRunningTasks = NO;
			break;			
	}
	
	// continue -  now try and terminate again
	[NSApp terminate:self];
}
@end


#pragma mark -
#pragma mark Private Methods Category
@implementation MGSAppController (Private)

/*
 
 check for unsaved documents before terminating
 
 */
- (NSApplicationTerminateReply)checkForUnsavedDocumentsBeforeTerminating
{
	return [self checkForUnsavedDocumentsOnClient:nil terminating:YES];
}
/*
 
 review changes and quit enumeration
 
 */
- (void)reviewChangesAndQuitEnumeration:(NSNumber *)contNumber 
{
	BOOL cont = [contNumber boolValue];
	
    if (cont) {
		//==========================================
		// check for unsaved documents on net client
		//==========================================	
		NSArray *editWindowControllers = _netClient != nil ? [_motherWindowController editWindowControllersForNetClient:_netClient] :
																[_motherWindowController editWindowControllers];

		NSUInteger editControllerCount = [editWindowControllers count];
        while (editControllerCount--) {
			MGSEditWindowController *controller = [editWindowControllers objectAtIndex:editControllerCount];
			if ([[controller window] isDocumentEdited]) {
				[controller askToSave:@selector(reviewChangesAndQuitEnumeration:)];
				return;
            }
        }
		
		// we have finished our review so try to terminate again
		if (_terminateAfterReviewChanges) {
			[NSApp terminate:self];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteClientSaveSucceeded object:self userInfo:nil];
		}
		
    } else {
		//NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_accessType], MGSNoteModeKey , nil];
		//[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteClientSaveCancelled object:self userInfo:nil];
	}

	_netClient = nil;

}

/*
 
 initialize user defaults
 
 */
+ (void)initializeUserDefaults
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];

	// net client defaults
	double heartbeatInterval = -1.0;	// no heartbeats
	if (NO) {
		heartbeatInterval = 60.0;
	} 
	[appDefaults setObject:[NSNumber numberWithDouble:heartbeatInterval] forKey:MGSDefaultHeartBeatInterval];	// time between heartbeats 
	[appDefaults setObject:[NSNumber numberWithDouble:30.0] forKey:MGSDefaultStartDelay];	// delay to wait for client connections 
	[appDefaults setObject:[NSNumber numberWithInt:3] forKey:MGSDefaultBadHeartbeatLimit];	// bad heartbeat count before manual client marked as disconnected
	
	// preferences defaults
	[appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSDefaultStartAtLogin];
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSModClickOpensNewWindow];
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSModClickOpensNewTab];
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSConfirmClosingMultipleTabsOrWindows];
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSNewTabKeepTaskDisplayed];
	
	// debug handler defaults
	[appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSEnableCoreDumps];
	[appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSAllowEditApplicationTasks];
	
	// task result display locking
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSTaskResultDisplayLocked];

	// display group list when sidebar hidden
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSDisplayGroupListWhenSidebarHidden];

	// client connection behaviour
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSDeferRemoteClientConnections];	// YES to use client deferring
	[appDefaults setObject:[NSNumber numberWithDouble:3] forKey:MGSRemoteClientConnectionDelay];	// delay to use when connecting to remote clients
	[appDefaults setObject:[NSNumber numberWithDouble:20] forKey:MGSDeferredClientConnectionTimeout];	// timeout for deferred clients - connection to deferred clients will occur after this time
	
	// task history
	[appDefaults setObject:[NSNumber numberWithInteger:100] forKey:MGSTaskHistoryCapacity];
	
	// script parameters
	[appDefaults setObject:@"_" forKey:MGSAppleScriptParameterPrefix];
	[appDefaults setObject:@"" forKey:MGSAppleScriptParameterSuffix];
	
	// script language
	// this must be a valid script language type
	[appDefaults setObject:@"AppleScript" forKey:MGSDefaultScriptType];

	// main window browser modes
	[appDefaults setObject:[NSNumber numberWithInteger:BROWSER_CLOSE_SEGMENT_INDEX] forKey:MGSTaskBrowserMode];
	[appDefaults setObject:[NSNumber numberWithInteger:TASK_DETAIL_CLOSE_SEGMENT_INDEX] forKey:MGSTaskDetailMode];
	
	// sidebar visibilty
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSMainSidebarVisible];

	// group list visibilty
	[appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSMainGroupListVisible];

	// animate the UI
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSAnimateUI];
	[appDefaults setObject:[NSNumber numberWithDouble:0.5] forKey:MGSTaskLoadingAnimationDelay];
    
	// keep executed tasks displayed
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSKeepExecutedTasksDisplayed];
	
	// result view defaults
	[appDefaults setObject:[NSArchiver archivedDataWithRootObject:[NSColor blackColor]] forKey:MGSResultViewColor];
	[appDefaults setObject:@"Menlo" forKey:MGSResultViewFontName];
	[appDefaults setObject:[NSNumber numberWithFloat:13] forKey:MGSResultViewFontSize];
	
	// use a separate network thread.
	// this thread acts to supply and retrieve data from the network requests
	// support for this is still experimental
	// see: http://projects.mugginsoft.net/view.php?id=866
	[appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSUseSeparateNetworkThread];
	
    // send crash reports for Cocoa tasks
    [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSSendCocoaTaskCRashReports];
    
    // Fragaria
    [appDefaults setObject:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Menlo" size:11]] forKey:MGSFragariaPrefsTextFont];

    // request timeouts
    [appDefaults setObject:[NSNumber numberWithInteger:30] forKey:MGSRequestWriteConnectionTimeout];
    [appDefaults setObject:[NSNumber numberWithInteger:15] forKey:MGSHeartbeatRequestTimeout];
    [appDefaults setObject:[NSNumber numberWithInteger:60] forKey:MGSDefaultRequestTimeout]; // for non task execute requests
    
    // local task timeouts
    [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSApplyTimeoutToLocalUserTasks];
    [appDefaults setObject:[NSNumber numberWithInteger:60] forKey:MGSLocalUserTaskTimeout];
    [appDefaults setObject:[NSNumber numberWithInteger:0] forKey:MGSLocalUserTaskTimeoutUnits];

    // machine task timeouts
    [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSApplyTimeoutToMachineTasks];
    [appDefaults setObject:[NSNumber numberWithInteger:60] forKey:MGSMachineTaskTimeout];
    [appDefaults setObject:[NSNumber numberWithInteger:0] forKey:MGSMachineTaskTimeoutUnits];
    
    // access control
    // see MGSPreferences for prefs managed by server
    if (NO) {
        [appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSAllowLocalAccess];
        [appDefaults setObject:[NSNumber numberWithBool:YES] forKey:MGSAllowLocalUsersToAuthenticate];
        [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSAllowInternetAccess];
        [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSAllowRemoteUsersToAuthenticate];
        [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSEnableInternetAccessAtLogin];
    }
    
    // port mapper 
    [appDefaults setObject:@YES forKey:MGSShowPortMapperRouterIncompatible];
    [appDefaults setObject:@YES forKey:MGSShowPortMapperRouterNotFound];

    // task editing preferences
    [appDefaults setObject:[NSNumber numberWithInteger:kMGSScriptHelperTemplateBrowser] forKey:MGSTaskEmptyScriptHelper];
    [appDefaults setObject:[NSNumber numberWithInteger:kMGSScriptHelperCodeAssistant] forKey:MGSTaskInputChangeScriptHelper];
    
    // code assistant preferences
    [appDefaults setObject:@"a the but is" forKey:MGSTaskInputArgumentExclusions];
    [appDefaults setObject:@"" forKey:MGSTaskInputArgumentPrefix];
    
	//
	// register app defaults
	//
	[userDefaults registerDefaults:appDefaults];

	//
	// see MGSFragariaPreferences.h for details
	//
	[userDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSFragariaPrefsAutocompleteSuggestAutomatically];
	[userDefaults setObject:[NSNumber numberWithBool:NO] forKey:MGSFragariaPrefsLineWrapNewDocuments];
    
	// the app defaults will not be visible to server so 
	// register these through MGSPreferences.
	// unlike NSUserDefaults these defaults will be actually written out
	// to the preference plist
	[[MGSPreferences standardUserDefaults] registerDefaults];
	
	// need to sync
	[userDefaults synchronize];
    
    // register initial values with the defaults controller.
    // when the controller is reset these values will be re-applied
    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    
    // keep existing content
    NSMutableDictionary *initialValues = [NSMutableDictionary dictionaryWithDictionary:[defaultsController initialValues]];
    
    [initialValues setObject:@YES forKey:MGSShowPortMapperRouterIncompatible];
    [initialValues setObject:@YES forKey:MGSShowPortMapperRouterNotFound];
	[defaultsController setInitialValues:initialValues];
}

/*
 
 + resetUserDefaults
 
 */
+ (void)resetUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // these values
    [defaults setObject:@YES forKey:MGSShowPortMapperRouterIncompatible];
    [defaults setObject:@YES forKey:MGSShowPortMapperRouterNotFound];
}
/*
 
 stop all running actions
 
 */
- (void)stopAllRunningActions
{
}

/* 
 
 initialize paths
 
 */
+ (void) initializePaths
{
	// user application support path
	[MGSPath verifyUserApplicationSupportPath];
		
	[MGSLM initializePaths];
}

/*
 
 enable suicide
 
 */
-(void)enableSuicide
{
// see http://www.red-sweater.com/blog/371/suicidal-code

// EXPIREAFTERDAYS defined in beta-expiring.xcconfig
#if EXPIREAFTERDAYS
	// Idea from Brian Cooke.
	
	// __DATE__ is build date
	NSString* nowString = [NSString stringWithUTF8String:__DATE__];
	NSCalendarDate* nowDate = [NSCalendarDate dateWithNaturalLanguageString:nowString];
	NSCalendarDate* expireDate = [nowDate addTimeInterval:(60*60*24* EXPIREAFTERDAYS)];

	NSString *endMessage = NSLocalizedString(@"Please contact the developer for another release copy.", @"Time trial expired message");
	
	_suicideTimeTrial = [ESSTimeTrialClass timeTrialWithEndDate:expireDate endMessage:endMessage];
	
	// log it
	MLogInfo(@"THIS SOFTWARE WILL EXPIRE ON: %@", expireDate);
#endif
	
}


@end

#pragma mark -
#pragma mark Notifications category

@implementation MGSAppController (Notifications)

/*
 
 application will sleep
 
 can delay sleep up to 30 secs
 
 */
- (void) appWillSleep:(NSNotification*) note
{
	MLog(DEBUGLOG, @"appWillSleep: %@", [note name]);
	
	// stop all actions.
	// connections to them will be lost during sleep.
	if (NO) {
		[[MGSRequestViewManager sharedInstance] stopAllRunningActions:self];
	}
}

- (void) appDidWake:(NSNotification*) note
{
	MLog(DEBUGLOG, @"appDidWake: %@", [note name]);
}
@end

#pragma mark -
#pragma mark Power Management category

@implementation MGSAppController (PowerManagement)

/*
 
 configure power management
 
 */
- (BOOL)configurePowerManagement
{
	
	//
	// Register for sleep notifications
	//
	// These notifications are filed on NSWorkspace's notification center, not the default notification center. 
	//  You will not receive sleep/wake notifications if you file with the default notification center.
	if (0) {
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self 
														   selector: @selector(appWillSleep:) name: NSWorkspaceWillSleepNotification object: NULL];
	}
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self 
														   selector: @selector(appDidWake:) name: NSWorkspaceDidWakeNotification object: NULL];
	
	// register for IO KIT notifications
	[[MGSClientPowerManagement sharedController] registerForIOKitSleepNotification];
	 
	return YES;
}
@end

/*
 
 scriptability category
 
 */
@implementation MGSAppController (Scriptability)

/*
 
 application:delegateHandlesKey:
 
 */
- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
# pragma unused(sender)
# pragma unused(key)
	
	// signal acceptance of AS properties
	return NO;
	/*
    if ([key isEqual:@"temppath"]) {
        return YES;
	} else if ([key isEqual:@"POSIXtemp"]) {
		 return YES;
    } else {
        return NO;
    }
	 */
}

@end


