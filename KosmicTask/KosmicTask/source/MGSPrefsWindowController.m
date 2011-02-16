//
//  PrefsWindowController.m
//  mother
//
//  Created by Jonathan Mitchell on 12/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSPrefsWindowController.h"
#import "MGSDebugController.h"
#import "UKLoginItemRegistry.h"
#import "MGSImageManager.h"
#import "MGSPreferences.h"
#import "MGSClientRequestManager.h"
#import "MGSNetRequestPayload.h"
#import "MGSNetClientManager.h"
#import "MGSNetClient.h"
#import "MGSMotherServerLocalController.h"
#import "MGSDistributedNotifications.h"
#import "MGSPortMapper.h"
#import "MGSInternetSharing.h"
#import "MGSInternetSharingClient.h"
#import "NSBundle_Mugginsoft.h"
#import "MGSSecurity.h"

NSString *MGSMotherLaunchdPlist = @"com.mugginsoft.kosmictasklaunchd.plist";

// defaults keys
NSString *MGSDefaultStartAtLogin = @"MGSStartAtLogin";

@implementation MGSPrefsWindowController

/*
 
 setup toolbar
 
 */
- (void)setupToolbar
{
	_internetTabIdentifier = NSLocalizedString(@"Internet", @"Preferences tab name");
	
	[self addView:generalPrefsView label:NSLocalizedString(@"General", @"Preferences tab name")];
	[self addView:tabsPrefsView label:NSLocalizedString(@"Tabs", @"Preferences tab name") image:[NSImage imageNamed: @"TabsPreference"]];
	[self addView:securityPrefsView label:NSLocalizedString(@"Security", @"Preferences tab name") image:[[[MGSImageManager sharedManager] locked] copy]];
	[self addView:internetPrefsView label:_internetTabIdentifier image:[NSImage imageNamed: @"NSNetwork"]];
}

/*
 
 -initWithWindow: is the designated initializer for NSWindowController.
 
 */
- (id)initWithWindow:(NSWindow *)window
{
	#pragma unused(sender)
	
	if ([super initWithWindow:window]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		_startAtLogin = [defaults boolForKey:MGSDefaultStartAtLogin];
		
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:window];
	}
	return self;
}



/*
 
 start or stop internet sharing
 
 */
- (IBAction)toggleInternetSharing:(id)sender
{
	#pragma unused(sender)
	[[MGSInternetSharingClient sharedInstance] toggleStartStop:self];
}

/*
 
 refresh internet sharing
 
 */
- (IBAction)refreshInternetSharing:(id)sender
{
	#pragma unused(sender)
	
	[[MGSInternetSharingClient sharedInstance] requestStatusUpdate];
}
 
/*
 
 show window override
 
 */
- (IBAction)showWindow:(id)sender
{
	[super showWindow:sender];
	
	// precautionary sync
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// retrieve server preferences
	[self retrieveServerPreferences];
}


/*
 
 show internet preferences
 
 */
- (void)showInternetPreferences
{
	[self showWindow:self];
	[[[self window] toolbar] setSelectedItemIdentifier:_internetTabIdentifier];
	[self displayViewForIdentifier:_internetTabIdentifier animate:NO];
}

/*
 
 show debug panel
 
 */
- (IBAction) showDebugPanel:(id)sender
{
	#pragma unused(sender)
	
	unsigned int flags = [[NSApp currentEvent] modifierFlags];
    //if ((flags & NSCommandKeyMask) && (flags & NSAlternateKeyMask) && (flags & NSControlKeyMask)) {
	if (!(flags & NSControlKeyMask)) {
        return;
    }
	if (debugController == nil) {
		debugController = [[MGSDebugController alloc] init];
	}
	[debugController showWindow:self];
}

- (BOOL) startAtLogin
{
	return _startAtLogin;
}

/*
 
 publish services at login
 
 */
- (void) setStartAtLogin:(BOOL)value
{
	// set the user default value
	_startAtLogin = value;	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:_startAtLogin forKey:MGSDefaultStartAtLogin];

	// Paths
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSBundle *bundle = [NSBundle mainBundle];
	
	// path to agent/daemon executable
	// NOTE:
	// Placing motherd in pathForAuxiliaryExecutable (which is just in /contents/MACOS) causes a curious problem.
	// When an AppleScript is run the componentInstance contacts the windowServer and if it is being run from
	// the bundle's /contents/MACOS it shows a dock icon for it!
	// Moving the executable to the resource folder solves the problem
	//
	NSString *serverPath = [bundle pathForCustomAuxiliaryExecutable:MGSMotherServerDaemonName];
	//NSString *serverPath = [[NSBundle mainBundle] pathForResource:MGSMotherServerDaemonName ofType:nil];
	
	// path to the bundle launchd template plist
	NSString *templatePlistPath = [bundle pathForResource:MGSMotherLaunchdPlist	ofType:nil];
	
	// path to the users launchd agent folder
	NSString *plistFolder = [@"~/Library/LaunchAgents" stringByExpandingTildeInPath];
	
	// path to the users launchd agent file
	NSString *plistPath = [plistFolder stringByAppendingPathComponent:MGSMotherLaunchdPlist];
	
	// the LaunchAgents folder may not exist within the users library.
	// create if absent
	if (NO == [fileManager fileExistsAtPath:plistFolder]) {
		if (NO == [fileManager createDirectoryAtPath:plistFolder withIntermediateDirectories:YES attributes:nil error:NULL]) {
			MLog(DEBUGLOG, @"could not create launchd agent folder at: %@", plistFolder);
			return;
		}
	}
	 
	// remove the existing launchd plist
	if (YES == [fileManager fileExistsAtPath:plistPath]) {
		if (NO == [fileManager removeItemAtPath:plistPath error:NULL]) {
			MLog(DEBUGLOG, @"could not delete launchd plist at: %@", plistPath);
			return;
		}
	}
	
	// create launchd plist file
	if (_startAtLogin) {
		
		// load the template
		// if launchd plist KeepALive -> SuccessfulExit = false then server will be restarted if crashes or killed.
		//
		// we it perhaps be better to make use of launchctl here?
		//
		NSMutableDictionary *launchDict = [NSMutableDictionary dictionaryWithContentsOfFile:templatePlistPath];
		
		// write the program path to the dict
		NSArray *programArray = [NSArray arrayWithObjects:serverPath, nil];
		[launchDict setObject:programArray	forKey:@"ProgramArguments"];
		
		// save it
		if (NO == [launchDict writeToFile:plistPath atomically:YES]) {
			MLog(DEBUGLOG, @"could not write launchd plist");
		}
	} 
	
	//int indexForLoginItem = [UKLoginItemRegistry indexForLoginItemWithPath: bundlePath];
	// user login items cannot run an agent unix executable properly
	// note that the LaunchServices sub framework can also accomplish this.
	// perhaps a better bet for leopard
	/*if (_startAtLogin) {
		//if (indexForLoginItem == -1) {
			[UKLoginItemRegistry addLoginItemWithPath: serverPath hideIt:NO];
		//}
	} else {
		//if (indexForLoginItem != -1) {
			[UKLoginItemRegistry removeLoginItemWithPath: serverPath];
	//	}
	}
	 */
}

- (void) dealloc
{
	[debugController release];
	[super dealloc];
}

/*
 
 window closing
 
 */
- (void)windowWillClose:(NSNotification *)notification
{
	if ([notification object] != [self window]) {
		return;
	}
	
	// need to sync the changes so that server can retrieve prefs from MGSPreferences
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// update server
	[self updateServerPreferences];
	
	return;
}

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	
	MGSInternetSharingClient *internetSharingClient = [MGSInternetSharingClient sharedInstance];
	
	//  prefs internet sharing controls bound to internetSharingObjectController
	[internetSharingObjectController setContent:internetSharingClient];
}

/*
 
 update those preferences that relate to the server.
 the client does not update these preferences directly.
 send them to the server and let it apply them
 
 note that it might have been a lot easier to use 
 distributed notifications for this
 
 */
- (void)updateServerPreferences
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// form server preferences change dictionary
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:2];

	// ssl 
	BOOL useSSL = ([useSSLCheckbox state] == NSOnState ? YES : NO);
	if (useSSL != [defaults boolForKey:MGSEnableServerSSLSecurity]) {
		[dictionary setObject:[NSNumber numberWithBool:useSSL] forKey:MGSEnableServerSSLSecurity];
	}
	
	// user name disclosure
	NSInteger usernameDisclosureMode = [[userNameDisclosureRadioButtons selectedCell] tag];
	switch (usernameDisclosureMode) {

		case DISCLOSE_USERNAME_TO_LOCAL:
			break;
			
		case DISCLOSE_USERNAME_TO_ALL:
			break;
			
		case DISCLOSE_USERNAME_TO_NONE:
		default:
			break;			
	}
	if (usernameDisclosureMode != [defaults integerForKey:MGSUsernameDisclosureMode]) {
		[dictionary setObject:[NSNumber numberWithInteger:usernameDisclosureMode] forKey:MGSUsernameDisclosureMode];
	}
	
	// send valid changes
	if ([dictionary count] > 0) {
		
			// send out a distributed notification
			// note we could also use CFMessagePort
			[[NSDistributedNotificationCenter defaultCenter] 
			 postNotificationName:MGSDistNoteServerPreferencesRequest
			 object:@"KosmicTask" 
			 userInfo:dictionary
			 deliverImmediately:YES];
			
		return;
	}
	
}

/*
 
 retrieve server preferences
 these preferences are maintained by the server not by the client.
 hence they are not bound.
 when modified the prefs are sent to the server to be applied
 
 */
- (void)retrieveServerPreferences
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	BOOL useSSL = [defaults boolForKey:MGSEnableServerSSLSecurity];
	[useSSLCheckbox setState:useSSL];

	NSInteger usernameDisclosureMode = [defaults integerForKey:MGSUsernameDisclosureMode];
	[userNameDisclosureRadioButtons selectCellWithTag:usernameDisclosureMode];
}

/*
 
 net request response
 
 */
-(void)netRequestResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	#pragma unused(netRequest)
	#pragma unused(payload)
	
}

/*
 
 control did fail to format string
 
 */

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error
{
	#pragma unused(string)
	#pragma unused(error)
	
	NSString *localErrorDescription, *recoverySuggestion;
	if (control == externalPort) {
		localErrorDescription = NSLocalizedString(@"Please enter a valid port number.", @"External port formatter error title");
		recoverySuggestion = NSLocalizedString(@"Valid port numbers are %i through %i.", @"External port formatter error string");
		recoverySuggestion = [NSString stringWithFormat:recoverySuggestion, MGS_MIN_INTERNET_SHARING_PORT, MGS_MAX_INTERNET_SHARING_PORT];
	} else {
		return YES;
	}
	
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:localErrorDescription, NSLocalizedDescriptionKey, 
						  recoverySuggestion, NSLocalizedRecoverySuggestionErrorKey,
						  nil];
	NSError *err = [NSError	errorWithDomain:MGSErrorDomainMotherClient code:0 userInfo:info];
	
	// present control error
	[control presentError:err modalForWindow:[self window] delegate:nil didPresentSelector:NULL contextInfo:NULL];

	return YES;
}

/*
 
 show SSL certficate
 
 */
- (IBAction)showSSLCertficate:(id)sender
{
	#pragma unused(sender)
	
	[MGSSecurity showCertificate];
}
@end
