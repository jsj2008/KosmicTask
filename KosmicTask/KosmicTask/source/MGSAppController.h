/* AppController */

#import <Cocoa/Cocoa.h>
#import "MGSResultViewController.h"
#import <FeedbackReporter/FRFeedbackReporter.h>

@class MGSExceptionController;
@class MGSDebugController;
@class MGSDebugHandler;
@class MGSConfigWindowController;
@class MGSPrefsWindowController;
@class MGSMotherServerLocalController;
@class MGSMotherWindowController;
@class MGSErrorWindowController;
@class MGSConnectingWindowController;
@class MGSExportPluginController;
@class MGSSendPluginController;
@class MGSParameterPluginController;
@class ESSTimeTrialClass;
@class MGSStopActionSheetController;
@class MGSResultViewController;
@class OpenFeedback;
@class SUUpdater;
@class MGSNetClient;
@class MGSLRWindowController;

@interface MGSAppController : NSObject <MGSResultViewDelegate, FRFeedbackReporterDelegate>
{
	MGSExceptionController *_exceptionController;
	MGSDebugHandler *_debugHandler;
	MGSConfigWindowController *_configController;
	MGSMotherServerLocalController *_serverLocalController;
	MGSMotherWindowController *_motherWindowController;
	MGSErrorWindowController *_errorWindowController;
	MGSConnectingWindowController *_connectingWindowController;
	MGSExportPluginController *_exportPluginController;
	MGSSendPluginController *_sendPluginController;
	MGSParameterPluginController *_parameterPluginController;
	MGSLRWindowController *_reminderWindowController;
	
	IBOutlet OpenFeedback *_openFeedbackController;
	IBOutlet SUUpdater *_sparkleUpdater;
	IBOutlet NSMenu *_taskMenu;
	IBOutlet NSMenuItem *_sendToMenuItem;
	ESSTimeTrialClass *_suicideTimeTrial;	// suicide time trial timer
	
	MGSStopActionSheetController *_stopActionSheetController;
	
	BOOL _startupComplete;
	BOOL _alwaysTerminate;
	BOOL _promptToStopRunningTasks;
	
	NSOperationQueue *_operationQueue;
	BOOL _terminateAfterReviewChanges;
	MGSNetClient *_netClient;
}

+ (MGSAppController *)sharedInstance;

- (IBAction)showPreferencesPanel:(id)sender;
- (IBAction)showConfigurationPanel:(id)sender;
- (IBAction)showErrorWindow:(id)sender;
- (IBAction)showResourceBrowserWindow:(id)sender;
- (IBAction)orderFrontCustomAboutPanel: (id) sender;
- (IBAction)showLicencesWindow:(id)sender;
- (IBAction)showFeedbackWindow:(id)sender;
- (IBAction)showReleaseNotes:(id)sender;
- (IBAction)onlineHelp:(id)sender;
- (IBAction)onlineSupport:(id)sender;
- (IBAction)onlineForum:(id)sender;
- (IBAction)showGuide:(id)sender;
- (IBAction)showLicenceAgreement:(id)sender;
- (IBAction)sendLog:(id)sender;

- (IBAction)toggleRunState:(id)sender;
- (IBAction)viewMenuModeSelected:(id)sender;
- (IBAction)configureInternetSharing:(id)sender;
- (IBAction)configureLocalSharing:(id)sender;

- (void)loadMotherWindow;
- (void)showMotherWindow;
- (NSWindow *)applicationWindow;
- (NSString *)versionStringForDisplay;
- (NSString *)buildStringForDisplay;
- (NSString *)applicationName;
- (void)showFinderQuickLook:(NSString *)filePath;
- (void)queueShowFinderQuickLook:(NSString *)filePath;
- (BOOL)openFileWithDefaultApplication:(NSString *)fullPath;
- (void)queueOpenFileWithDefaultApplication:(NSString *)filePath;
- (NSApplicationTerminateReply)checkForUnsavedDocumentsOnClient:(MGSNetClient *)netClient terminating:(BOOL)terminating;
- (void)appRequest;

// result handling
- (IBAction)saveResult:(id)sender;
- (IBAction)sendResult:(id)sender;
- (IBAction)quicklook:(id)sender;
- (IBAction)viewMenuViewAsSelected:(id)sender;

// menu
- (NSMenu *)taskMenu;
- (NSMenu *)sendToMenu;
- (void)setSendToMenu:(NSMenu *)menu;

- (MGSResultViewController *)activeResultViewController;

@property (readonly) MGSConnectingWindowController *connectingWindowController;
@property BOOL startupComplete;
@property (readonly) MGSExportPluginController *exportPluginController;
@property (readonly) MGSSendPluginController *sendPluginController;
@property (readonly) MGSParameterPluginController *parameterPluginController;
@property (readonly) ESSTimeTrialClass *suicideTimeTrial;
@property (readonly) NSOperationQueue *operationQueue;
@end

// delegate category
@interface MGSAppController (NSApplicationDelegate)
- (void)reportException:(NSException *)theException;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)reviewSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void)stopActionSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
@end


