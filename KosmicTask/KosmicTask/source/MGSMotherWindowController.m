//
//  MGSMotherWindowController.m
//  Mother
//
//  Created by Jonathan on 24/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSMotherWindowController.h"
#import "MGSSidebarViewController.h"
#import "NSView_Mugginsoft.h"
#import "NSSplitView_Mugginsoft.h"
#import "MGSNotifications.h"
#import "MGSMotherModes.h"
#import "MGSMainViewController.h"
#import "MGSNetClient.h"
#import "MGSScript.h"
#import "MGSScriptPlist.h"
#import "MGSTaskSpecifier.h"
#import "MGSConfigurationAccessWindowController.h"
#import "MGSAddServerWindowController.h"
#import "MGSRemoveServerWindowController.h"
#import "MGSClientRequestManager.h"
#import "MGSNetRequestPayload.h"
#import "MGSActionWindowController.h"
#import "MGSResult.h"
#import "MGSResultWindowController.h"
#import "NSWindow_Mugginsoft.h"
#import "MGSScriptViewController.h"
#import "MGSAppController.h"
#import "MGSImageBrowserViewController.h"
#import "MGSRequestTabViewController.h"
#import "MGSApplicationMenu.h"
#import "MGSLM.h"
#import "MGSActionDeleteWindowController.h"
#import "MGSPreferences.h"
#import "MGSWaitViewController.h"

static NSString *MGSRequestDuplicateAction = @"MGSRequestDuplicateAction";
static NSString *MGSRequestEditAction = @"MGSRequestEditAction";

// class extension
@interface MGSMotherWindowController()
- (void)addServerSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)removeServerSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)loadUserDefaults;
- (void)startupAnimation;
- (void)validatedConnectionLimit:(NSNotification *)aNote;
- (id)createNewAction:(NSNotification *)notification;
- (void)editSelectedAction:(NSNotification *)notification;
- (MGSEditWindowController *)editAction:(MGSTaskSpecifier *)action;
- (void)viewConfigChangeRequest:(NSNotification *)notification;
- (void)authenticateAccess:(NSNotification *)notification;
- (void)logOut:(NSNotification *)notification;
- (BOOL)editWindowExistsForAction:(MGSTaskSpecifier *)action orderFront:(BOOL)orderFront;
- (BOOL)editPendingForAction:(MGSTaskSpecifier *)action;
- (void)addEditPendingForAction:(MGSTaskSpecifier *)action;
- (void)removeEditPendingForAction:(MGSTaskSpecifier *)action;
- (MGSTaskSpecifier *)getActionPendingEditWithUUID:(NSString *)UUID;
- (void)duplicateSelectedAction:(NSNotification *)notification;
- (void)requestActionEdit:(MGSTaskSpecifier *)action;
- (void)netClientSelected:(NSNotification *)notification;
- (void)openActionInWindow:(NSNotification *)notification;
- (void)openResultInWindow:(NSNotification *)notification;
- (void)applicationTaskEditWarningAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)validatedConnectionLimitAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)deleteSelectedAction:(NSNotification *)notification;
@end

@implementation MGSMotherWindowController

const char MGSNetClientRunModeContext;
const char MGSContextStartupComplete;

@synthesize runMode = _runMode;

#pragma mark -
#pragma mark Instance control
/*
 
 init
 
 */
- (id)init
{
	/*
	 
	 Initialise with nib.
	 
	 Be clear that the nib does NOT get loaded.
	 
	 This will occur when the window property is first accessed.
	 We can check if the nib is loaded with NSWindowController - isWindowLoaded.
	 If the nib has not been loaded then if is now loaded.
	 The docs for -loadWindow state that invoking -window causes nib loading to occur
	 and -windowWillLoad and - windowDidLoad to be sent.
	 
	 - window conceptual only
	 
	 if (! [self isWindowLoaded]) {
		 [self windowWillLoad];
		 NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		 NSNib *nib = [[NSNib alloc] initWithNibNamed:[self nibName] bundle:bundle];
		 NSArray *topLevel = nil;
		 [nib instantiateNibWithOwner:self topLevelObjects:&topLevel];
		[self windowDidLoad];
	 }
	 
	 [NSWindowController setWindow]
	 #1	0x95d232ff in -[NSNibOutletConnector establishConnection]
	 #2	0x95d21a8b in -[NSIBObjectData nibInstantiateWithOwner:topLevelObjects:]
	 #3	0x95d1fba0 in loadNib
	 #4	0x95d1ef99 in +[NSBundle(NSNibLoading) _loadNibFile:nameTable:withZone:ownerBundle:]
	 #5	0x95d1eeaa in +[NSBundle(NSNibLoading) loadNibFile:externalNameTable:withZone:]
	 #6	0x95daeb67 in -[NSWindowController loadWindow]
	 #7	0x95d4592a in -[NSWindowController window]
	 #8	0x00008bba in -[MGSAppController loadMotherWindow] at MGSAppController.m:237
	 #9	0x0000ad4e in -[MGSAppController(NSApplicationDelegate) applicationDidFinishLaunching:] at MGSAppController.m:1117
	 
	 For NSBundle(NSNibLoading) see the NSBundle Additions Class reference
	 
	 NSViewController follows a similar pattern.
	 
	 */
	if ((self = [super initWithWindowNibName:@"MotherWindow"])) {
	}
	return self;
}

/* 
 
 awake from nib
 
 sent from [NSIBObjectData nibInstantiateWithOwner:topLevelObjects:]
 
 */
- (void)awakeFromNib
{
}


#pragma mark -
#pragma mark Window handling
/*
 
 - setWindow:
 
 */
- (void)setWindow:(NSWindow *)aWindow
{
	// when the nib is loaded and the connection is made the window
	// is instantiated and this method is called.
	[super setWindow:aWindow];
}
/*
 
 window did load
 
 */
- (void)windowWillLoad
{
	[super windowWillLoad];
}
/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	[super windowDidLoad];

	[[NSApp delegate] addObserver:self forKeyPath:@"startupComplete" options:0 context:(void *)&MGSContextStartupComplete];
	_suppressApplicationTaskEditAlertSheet = NO;
	
	// load the toolbar nib
	_toolbarController = [[MGSToolbarController alloc] init];
	_toolbarController.window = [self window];
	_toolbarController.style = MGSToolbarStyleMain;
	_toolbarController.identifier = @"AppMain";
	[_toolbarController loadNib];
	[_toolbarController setDelegate:self];


	[[self window] addViewToTitleBar:_feedbackButton xoffset:8];
	
	//
	// load the main splitview into the window main view
	//
	[windowSplitView setDelegate:self];
	[windowSplitView replaceSubview:windowMainView withViewSizedAsOld:[mainViewController view]];
	windowMainView = [mainViewController view];	
	[mainViewController loadUserDefaults];
	
	//
	// load the sidebar views
	// Note: there is a splitview in the nib.
	// the bottom panel is an activity viewer.
	// this will not be implamneted till v2.0 so swap splitview with sidebar for now
	_sidebarViewController = [[MGSSidebarViewController alloc] initWithNibName:@"SidebarView" bundle:nil];
	[[_sidebarViewController view] setFrame:[leftSplitView frame]];
	[leftView replaceSubview:leftSplitView with:[_sidebarViewController view]];
	
	//
	// load the left view into the window left view
	//
	[windowSplitView replaceSubview:windowLeftView withViewSizedAsOld:leftView];
	windowLeftView = leftView;
	_contentSubview = windowSplitView;
	
	// show the wait view until client data is obtained.
	// this is added above the existing content subviews
	_waitViewController = [[MGSWaitViewController alloc] initWithNibName:@"WaitView" bundle:nil];
	[[_waitViewController view] setFrame:[[[self window] contentView] frame]];
	[[[self window] contentView] addSubview:[_waitViewController view]];
	
	// array of edit window controllers
	_editWindowControllers = [NSMutableArray arrayWithCapacity:2];
	
	// array of action window controllers
	_actionWindowControllers = [NSMutableArray arrayWithCapacity:2];
	
	// array of result window controllers
	_resultWindowControllers = [NSMutableArray arrayWithCapacity:2];
	
	// register for notifications
	//
	// register for changes to the edit mode - either In Run or Configuration modes
	// in Configuration mode the toolbar will send out action notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editSelectedAction:) name:MGSNoteEditSelectedTask object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewConfigChangeRequest:) name:MGSNoteViewConfigChangeRequest object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientSelected:) name:MGSNoteClientSelected object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createNewAction:) name:MGSNoteCreateNewTask object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(duplicateSelectedAction:) name:MGSNoteDuplicateSelectedTask object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticateAccess:) name:MGSNoteShouldAuthenticateAccess object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logOut:) name:MGSNoteLogout object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openActionInWindow:) name:MGSNoteOpenTaskInWindow object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openResultInWindow:) name:MGSNoteOpenResultInWindow object:nil];

	//
	// connection limit exceeded
	//
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(validatedConnectionLimit:) name:MGSNoteConnectionLimitExceeded object:nil];

	// 
	// delete selected action
	//
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteSelectedAction:) name:MGSNoteDeleteSelectedTask object:nil];

	_actionsPendingEdit = [NSMutableDictionary dictionaryWithCapacity:2];
	
}



/*
 
 close edit windows silently for net client
 
 */
- (void)closeEditWindowsSilentlyForNetClient:(MGSNetClient *)netClient
{
	if (!netClient) return;
	
	// close edit windows without saving
	NSArray *editWindowControllers = [self editWindowControllersForNetClient:netClient];
	NSInteger editControllerCount = [editWindowControllers count];
	
	// close all open edit windows regardless of their document edit status
	while (editControllerCount--) {
		MGSEditWindowController *controller = [editWindowControllers objectAtIndex:editControllerCount];
		[controller closeWindowSilently];
	}
	
}

#pragma mark -
#pragma mark User defaults
/*
 
 - loadUserDefaults
 
 */
- (void)loadUserDefaults
{
	BOOL showMainSidebar = [[NSUserDefaults standardUserDefaults]boolForKey:MGSMainSidebarVisible];
	eMGSViewState viewState = showMainSidebar ? kMGSViewStateShow : kMGSViewStateHide;
	
	// post view mode change request
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInteger:kMGSMotherViewConfigSidebar], MGSNoteViewConfigKey,
						  [NSNumber numberWithInteger:viewState], MGSNoteViewStateKey,
						  nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:self userInfo:dict];
}

#pragma mark -
#pragma mark KVO
/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &MGSNetClientRunModeContext) {
		
		// run mode changed
		self.runMode = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
		
	} else if (context == &MGSContextStartupComplete) {
		
		// splitview frame is now correctly sized so we can load the user defaults
		[self loadUserDefaults];

		// run the startup animation
		[self performSelector:@selector(startupAnimation) withObject:nil afterDelay:0];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -
#pragma mark View handling
/*
 
 active result view controller
  
 */
- (MGSResultViewController *)activeResultViewController
{
	
	return [mainViewController selectedTabResultViewController]; 
}
/*
 
 active request view controller
 
 */
- (MGSRequestViewController *)activeRequestViewController
{
	
	return mainViewController.tabViewController.selectedRequestViewController; 
}

/*
 
 sidebar view is hidden
 
 */
- (BOOL)sidebarViewIsHidden
{
	// if subview contains a splitview then the view is not hidden.
	return _contentSubview == windowSplitView ? NO : YES;
}

#pragma mark -
#pragma mark Document handling
/*
 
 print document
 
 sent by the application menu.
 it will travel up the responder chain to here,
 
 
 not yet required
 
 */
- (void)printDocument:(id)sender
{
	#pragma unused(sender)
	
	// print the script view
	[mainViewController.scriptViewController printDocument:self];
}

/*
 
 new document
 
 */
- (void)newDocument:(id)sender
{
	#pragma unused(sender)
	[self createNewAction:nil];
}

/*
 
 open document
 
 */
- (void)openDocument:(id)sender
{
	// this can come up the responder chain so always validate the run mode
	if (_runMode == kMGSMotherRunModeConfigure) {
		
		#pragma unused(sender)
		[self editSelectedAction:nil];
	}
}

/*
 
 duplicate document
 
 */
- (void)duplicateDocument:(id)sender
{
	#pragma unused(sender)
	[self duplicateSelectedAction:nil];
}


/*
 
 delete document
 
 */
- (void)deleteDocument:(id)sender
{
	#pragma unused(sender)
		
	// browser will mark document for deletion
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteDeleteSelectedTask object:nil userInfo:nil];
}

/*
 
 save document
 
 */
- (void)saveDocument:(id)sender
{
	#pragma unused(sender)
	// no action reqd, but this class must respond to this message
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
 
 window show document path popup in title bar
 
 */
- (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu 
{
	#pragma unused(window)
	#pragma unused(menu)
	
	return NO;
}

/*
 
 - publishDocument:
 
 */
- (IBAction)publishDocument:(id)sender
{
#pragma unused(sender)
	[mainViewController.browserViewController setSelectedActionSchedulePublished:YES];
}
/*
 
 - unpublishDocument:
 
 */
- (IBAction)unpublishDocument:(id)sender
{
#pragma unused(sender)
	[mainViewController.browserViewController setSelectedActionSchedulePublished:NO];
}

#pragma mark -
#pragma mark Animation

/*
 
 - startupAnimation
 
 */
- (void)startupAnimation
{
	
	NSView *contentView = [[self window] contentView];
	
	BOOL animate = [[NSUserDefaults standardUserDefaults] boolForKey:MGSAnimateUI];
	
	if (animate) {
		
		// we cannot capture the _contentSubview contents as it is behind the wait view
		[_contentSubview removeFromSuperview];
		
		// capture the offscreen _contentSubview as an image view.
		// this gives better animation than trying to animate the 
		// _contentSubview directly
		NSImageView *imageView = [_contentSubview mgs_captureImageView];
		//[imageView setWantsLayer:YES];
		
		// stop the wait view animation
		[_waitViewController clear];
		//[[_waitViewController view] setWantsLayer:YES];
		
		// add the imageView behind the wait view ready for animation
		[contentView addSubview:imageView positioned:NSWindowBelow relativeTo:[_waitViewController view]];
		
		[[_waitViewController view] mgs_fadeToSiblingView:imageView duration:0.5];
		
		// remove the wait view
		[[_waitViewController view] removeFromSuperview];
		
		// replace the image view with the content subview
		[contentView replaceSubview:imageView withViewFrameAsOld:_contentSubview];		 
	} else {
		[[_waitViewController view] removeFromSuperview];
	}
	
	_waitViewController = nil;
	
}

#pragma mark -
#pragma mark Menu action handling
/*
 
 validate menu item
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (![super validateMenuItem:menuItem]) {
		return NO;
	}
		
	SEL theAction = [menuItem action];
	MGSNetClient *netClient = nil;
	MGSRequestViewController *selectedRequestViewController = [[mainViewController tabViewController] selectedRequestViewController];
 
	// clicking print when the print message rises up the responder chain to the window
	// generates a print error so disbale the print menu under these circumstances
	if (theAction == @selector(printDocument:)) {
		netClient = [[mainViewController browserViewController] selectedClient];
		
		// only print if authenticated
		if (![netClient isAuthenticated]) return NO;
		
		// print if script controller permits
		return [mainViewController.scriptViewController documentPrintable];
	}
	
	// document modification
	else if (theAction == @selector(newDocument:) ||
				theAction == @selector(openDocument:) ||
			    theAction == @selector(openFile:) ||
				theAction == @selector(duplicateDocument:) ||
				theAction == @selector(deleteDocument:) ||
				theAction == @selector(publishDocument:) ||
				theAction == @selector(unpublishDocument:)) {
		
		netClient = [[mainViewController browserViewController] selectedClient];
		
		// must be authenticated
		if (![netClient isAuthenticated]) return NO;		
		
		// must be in config mode
		return _runMode == kMGSMotherRunModeConfigure ? YES : NO;
		
	}
	
	// save document
	else if (theAction == @selector(saveDocument:)) {
		
		// show default save menu title.
		// this is reqd as the title may have been modified by a subview.
		// if the message rises this far up the responder chain then it requires its default title
		[menuItem setTitle:	NSLocalizedString(@"Save", @"Save menu item")];
		return NO;
	
	// quick look
	}	else if (theAction == @selector(quicklook:)) {
		
		// show default quick look menu title.
		// this is reqd as the title may have been modified by a subview.
		// if the message rises this far up the responder chain then it requires its default title
		[menuItem setTitle:	NSLocalizedString(@"Quick Look", @"Quick look menu item")];
		return NO;
	

	// close tab, next, prev tab
	} else if (theAction == @selector(closeTaskTab:) ||
			   theAction == @selector(selectNextTaskTab:)||
			   theAction == @selector(selectPrevTaskTab:)) {
		
		// if no tabs then disable
		if (mainViewController.tabViewController.tabCount <= 1) {
			return NO;
		}
	
		// cannot close tab if processing
		if (theAction == @selector(closeTaskTab:) && [selectedRequestViewController isProcessing]) {
			return NO;
		}
	
	// menu view show
	} else if (theAction == @selector(viewMenuShowSelected:)) {
		NSString *title = @"";
		
		switch ([menuItem tag]) {
			case kMGS_MENU_TAG_VIEW_SHOW_TOP_BROWSER:;
				if ([mainViewController browserViewIsHidden]) {
					title = NSLocalizedString(@"Show Top Browser", @"Application view show menu");
				} else {
					title = NSLocalizedString(@"Hide Top Browser", @"Application view show menu");
				}
				break;
				
			case kMGS_MENU_TAG_VIEW_SHOW_BOTTOM_DETAIL:
				if ([mainViewController detailViewIsHidden]) {
					title = NSLocalizedString(@"Show Bottom Detail", @"Application view show menu");
				} else {
					title = NSLocalizedString(@"Hide Bottom Detail", @"Application view show menu");
				}
				break;
				
			case kMGS_MENU_TAG_VIEW_SHOW_SIDEBAR:
				if ([self sidebarViewIsHidden]) {
					title = NSLocalizedString(@"Show Sidebar", @"Application view show menu");
				} else {
					title = NSLocalizedString(@"Hide Sidebar", @"Application view show menu");
				}
				break;
				
			default:
				NSAssert(NO, @"invalid menu tag");
		}	
		[menuItem setTitle: title];
	}
	
	return YES;
}

/*
 
 create new task tab
 
 */
- (IBAction)addNewTaskTab:(id)sender
{
	[mainViewController addNewTaskTab:sender];
}
/*
 
 close task tab
 
 */
- (IBAction)closeTaskTab:(id)sender
{
	[mainViewController closeTaskTab:sender];
}

/*
 
 find task
 
 */
- (IBAction)findTask:(id)sender
{
	#pragma unused(sender)
	
	[mainViewController showSearchView];

}

/*
 
 select next task tab
 
 */
- (IBAction)selectNextTaskTab:(id)sender
{
#pragma unused(sender)
	
	[mainViewController.tabViewController selectNextTab];
}

/*
 
 select previous task tab
 
 */
- (IBAction)selectPrevTaskTab:(id)sender
{
#pragma unused(sender)
	
	[mainViewController.tabViewController selectPreviousTab];
}

/*
 
 view menu show selected
 
 */
- (IBAction)viewMenuShowSelected:(id)sender
{
	if (![sender isKindOfClass:[NSMenuItem class]]) {
		return;
	}
	NSMenuItem *menuItem = sender;
	eMGSMotherViewConfig viewName = -1;
	eMGSViewState viewState = kMGSViewStateToggleVisibility;
	
	switch ([menuItem tag]) {
			
		case kMGS_MENU_TAG_VIEW_SHOW_TOP_BROWSER:;
			viewName = kMGSMotherViewConfigBrowser;
			// it is possible just to toggle the view visibility.
			// this however makes it diffcult for all observers to determine the view state.
			viewState = [mainViewController browserViewIsHidden] ? kMGSViewStateShow : kMGSViewStateHide;
			break;
			
		case kMGS_MENU_TAG_VIEW_SHOW_BOTTOM_DETAIL:
			viewName = kMGSMotherViewConfigDetail;
			viewState = [mainViewController detailViewIsHidden] ? kMGSViewStateShow : kMGSViewStateHide;
			break;
			
		case kMGS_MENU_TAG_VIEW_SHOW_SIDEBAR:
			viewName = kMGSMotherViewConfigSidebar;
			viewState = [self sidebarViewIsHidden] ? kMGSViewStateShow : kMGSViewStateHide;
			break;
			
		default:
			NSAssert(NO, @"invalid menu tag");
	}

	// post view mode change request notification
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInteger:viewName], MGSNoteViewConfigKey, 
						  [NSNumber numberWithInteger:viewState], MGSNoteViewStateKey, 
						  nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:self userInfo:dict];
	
}

#pragma mark -
#pragma mark Properties
/* 
 
 quick look
 
 */

- (IBAction)quicklook:(id)sender
{
	#pragma unused(sender)
	// no action reqd, but this class must respond to this message
}

/*
 
 selected action specifier
 
 */
- (MGSTaskSpecifier *)selectedActionSpecifier
{
	// return action within the selected tab
	return [mainViewController selectedTabMotherAction];
}

/*
 
 set the run mode
 
 */
- (void)setRunMode:(eMGSMotherRunMode)mode
{
	_runMode = mode;
}

/*
 
 array of edit window controllers
 
 */
- (NSArray *)editWindowControllers
{
	return [NSArray arrayWithArray:_editWindowControllers];
}
/*
 
 array of edit window controllers for net client
 
 */
- (NSArray *)editWindowControllersForNetClient:(MGSNetClient *)netClient
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
	for (MGSEditWindowController *editWindowController in _editWindowControllers) {
		if (editWindowController.taskSpec.netClient == netClient) {
			[array addObject:editWindowController];
		}
	}	
	return [NSArray arrayWithArray:array];
}

/*
 
 task tab count
 
 */
- (NSInteger)taskTabCount
{
	return mainViewController.tabViewController.tabCount;
}

#pragma mark -
#pragma mark NSSplitView delegate methods

/*
 size splitview subviews as required
*/
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize
{	
	MGSSplitviewBehaviour behaviour;
	
	// note that a view does not provide a -setTag method only -tag
	// so views cannot be easily tagged without subclassing.
	// NSControl implements -setTag;
	//
	if ([sender isEqual:windowSplitView]) {
		behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;
	} else if ([sender isEqual:leftSplitView]) {
		behaviour = MGSSplitviewBehaviourOf2ViewsSecondFixed;
	} else {
		NSAssert(NO, @"invalid splitview");
		return;
	}
	
	// see the NSSplitView_Mugginsoft category
	[sender resizeSubviewsWithOldSize:oldSize withBehaviour:behaviour];
}

/*
 
 splitview constrain split position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset
{
	#pragma unused(offset)
	if ([sender isEqual:windowSplitView]) {

		CGFloat maxWidth = [sender frame].size.width/2;

		// min left view width
		if (proposedPosition < 82) {
			proposedPosition = 82;
		} else if (proposedPosition > maxWidth){
			proposedPosition = maxWidth;
		}
	}
	return proposedPosition;
}


/*
 
 get additional rect to be used to drag splitview
 
 */
- (NSRect)splitView:(NSSplitView *)aSplitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
	NSView *subView = [[aSplitView subviews] objectAtIndex:dividerIndex];
	
	NSRect rect = [subView bounds];
	rect.origin.x = rect.size.width -15;
	rect.origin.y = 0;
	rect.size.height = 22;
	rect.size.width = 15;
	
	// rect must be in splitview co-ords
	return [aSplitView convertRect:rect fromView:subView];
}

#pragma mark -
#pragma mark Manual connection handling
/*
 
 manually add server
 
 */
- (IBAction)addServer:(id)sender
{
	#pragma unused(sender)
	
	MGSAddServerWindowController *addServer = [[MGSAddServerWindowController alloc] init];
	[addServer window];	// load nib
	addServer.delegate = [mainViewController browserViewController];
	
	// show the sheet
	[NSApp beginSheet:[addServer window] modalForWindow:[self window] 
		modalDelegate:self 
	   didEndSelector:@selector(addServerSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

/*
 
 modal server sheet did end
 
 */
- (void)addServerSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	#pragma unused(sheet)
	#pragma unused(returnCode)
	#pragma unused(contextInfo)
	// delegation used to detect successful client connection
}

/*
 
 manually remove server
 
 */
- (IBAction)removeServer:(id)sender
{
	#pragma unused(sender)
	MGSRemoveServerWindowController *removeServer = [[MGSRemoveServerWindowController alloc] init];
	[removeServer window];	// load nib
	removeServer.delegate = [mainViewController browserViewController];
	
	// show the sheet
	[NSApp beginSheet:[removeServer window] modalForWindow:[self window] 
		modalDelegate:self 
	   didEndSelector:@selector(removeServerSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

/*
 
 modal server sheet did end
 
 */
- (void)removeServerSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	#pragma unused(sheet)
	#pragma unused(returnCode)
	#pragma unused(contextInfo)
	// delegation used to detect successful client connection
}

#pragma mark -
#pragma mark NSWindow delegate methods

/*
 
 window should close.
 
 closing the window will terminate the application.
 
 */
- (BOOL)windowShouldClose:(id)window
{
	#pragma unused(window)

	[NSApp terminate:self];
	return NO;
}

/*
 
 window will close
 
 */
- (void)windowWillClose:(NSNotification *)notification
{
	[super windowWillClose:notification];

	[mainViewController windowClosing];
	[[self window] setDelegate:nil];
}

/*
 
 window did resign key
 
 */
- (void)windowDidResignKey:(NSNotification *)notification
{
	#pragma unused(notification)

	[[self window] endEditing];
}

#pragma mark -
#pragma mark MGSEditWindowController controller delegate

/*
 
 edit window will close
 
 */
- (void)editWindowWillClose:(MGSEditWindowController *)editWindowController
{
	[_editWindowControllers removeObject:editWindowController];
}

#pragma mark -
#pragma mark MGSActionWindowController controller delegate

// action window closing
- (void)actionWindowWillClose:(MGSActionWindowController *)actionWindowController
{
	[_actionWindowControllers removeObject:actionWindowController];
}

#pragma mark -
#pragma mark MGSResultWindowController controller delegate

// result window closing
- (void)resultWindowWillClose:(MGSResultWindowController *)resultWindowController
{
	[_resultWindowControllers removeObject:resultWindowController];
}

#pragma mark -
#pragma mark MGSClientRequestManager delegate

/*
 
 net request response
 
 */
-(void)netRequestResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	NSString *requestCommand = netRequest.kosmicTaskCommand;

	//
	// script request
	//
	if (NSOrderedSame == [requestCommand caseInsensitiveCompare:MGSScriptCommandGetScriptUUID]) {
		
		// get script from request dict
		NSMutableDictionary *scriptDict =[[payload dictionary] objectForKey:MGSScriptKeyScript];
		BOOL markDocumentAsEdited = NO;
		MGSTaskSpecifier *action = nil;
		
		// if script dict is available
		if (scriptDict) {
			
			// get script
			MGSScript *script = [[MGSScript alloc] init];
			[script setDict:scriptDict];
			[script setScheduleSave];	
			
			//
			// duplicate action
			//
			if (netRequest.ownerString == MGSRequestDuplicateAction) {
				action = netRequest.ownerObject;
				
				// duplicate the script.
				// this will give it a new UUID.
				script = [script duplicate];
				[script appendStringToName:NSLocalizedString(@" (duplicate)", @"Text appended to task name when duplicated")];
				
				// duplicated action must be marked as edited to force save prompt
				markDocumentAsEdited = YES;
				
			} 
			//
			// edit action
			//
			else if (netRequest.ownerString == MGSRequestEditAction) {
				action = netRequest.ownerObject;
				
				// cannot edit a bundled script so duplicate it.
				// duplicate scripts are automatically marked as not bundled
				if (![netRequest.netClient canEditScript:script]) {
					
					script = [script duplicate];
					[script appendStringToName:NSLocalizedString(@" (user)", @"Text appended to task name when edit application task")];

					// duplicated action must be marked as edited to force save prompt
					// hmm. not sure whether to mark as edited or not...
					// if mark as edited then user gets prompted to save even when they have made no changes
					// though it is true that the script name has already been changed.
					// if user makes any further edits then doc gets marked as dirty.
					if (1) {
						markDocumentAsEdited = YES;
					}
				}
				
				// clear pending edit 
				[self removeEditPendingForAction:action];
			} else {
				MLog(RELEASELOG, @"invalid request owner string");
				return;
			}
			
			// action must be valid
			if (!action) {
				MLog(RELEASELOG, @"action is nil");
				return;
			}
			
			// set action script
			[action setScript:script];
			
			// now edit action
			MGSEditWindowController *editWindowController = [self editAction:action];
			if (!editWindowController) {
				return;
			}
			
			// set document edited status
			[[editWindowController window] setDocumentEdited:markDocumentAsEdited];
			
		} 
		
		// script dict not found
		else {	

			if (netRequest.ownerString == MGSRequestDuplicateAction) {
				action = netRequest.ownerObject;
				MLog(RELEASELOG, @"Could not duplicate script UUID: %@", [[action script] UUID]);
			}
			
			else if (netRequest.ownerString == MGSRequestEditAction) {
				action = netRequest.ownerObject;
				[self removeEditPendingForAction:action];
				MLog(RELEASELOG, @"Could not edit script UUID: %@", [[action script] UUID]);
			}
			
		}
		
		return;
	}
	
	// check for errors
	if (payload.requestError) {
		return;
	}
}

#pragma mark -
#pragma mark MGSToolbar controller delegate
/*
 
 save client before change run mode
 
 this message will be sent before the run mode for the 
 currently selected netClient changes.
 
 it gives the app the chance to save data before switching run modes.
 
 */
- (BOOL)saveClientBeforeChangeToRunMode:(NSInteger)mode
{
	#pragma unused(mode)
	
	// ask app delegate to check for unsaved documents on client.
	if ([[NSApp delegate] checkForUnsavedDocumentsOnClient:self.netClient terminating:NO] == NSTerminateNow) {
		
		// close all open edit windows regardless of their document edit status
		[self closeEditWindowsSilentlyForNetClient:self.netClient];
		return NO;
	} else {
		// we need to save
		return YES;
	}
}

/*
 
 confirm deletion of selected action
 
 */
- (void)confirmDeleteSelectedAction:(BOOL)delete
{
	if (!delete) {
		return;
	}
	
	[mainViewController.browserViewController deleteSelectedAction];
}

#pragma mark -
#pragma mark Notification methods

/*
 
 validated connection limit exceeded
 
 */
- (void)validatedConnectionLimit:(NSNotification *)aNote
{
	#pragma unused(aNote)
	
	NSString *fmt = NSLocalizedString(@"Sorry, cannot complete this request.", @"connections sheet message");
	NSString *alertMessage = [NSString stringWithFormat:fmt, nil];
	fmt = NSLocalizedString(@"Your licensed connection count of %i has been exceeded.\n\nPlease install another licence file.", @"connections sheet info");
	NSString *alertInfo = [NSString stringWithFormat:fmt, [[MGSLM sharedController] seatCount]];
	NSAlert *alert = [NSAlert alertWithMessageText: alertMessage
									 defaultButton: nil
								   alternateButton: nil
									   otherButton: nil
						 informativeTextWithFormat: alertInfo];
	
	// run dialog
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(validatedConnectionLimitAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	
}


/*
 
 net client selected
 
 */
- (void)netClientSelected:(NSNotification *)notification
{
	
	NSDictionary *userInfo = [notification userInfo];
	MGSNetClient *netClient= [userInfo objectForKey:MGSNoteNetClientKey];
	NSAssert(netClient, @"net client is nil");
	
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleName"];
	[[self window] setTitle:[NSString stringWithFormat:@"%@ — %@", [netClient serviceShortName], appName]];
	
	self.netClient = netClient;	
}

/*
 
 action view mode has changed
 
 */
- (void)viewConfigChangeRequest:(NSNotification *)notification
{ 
	// get view id
    NSNumber *number = [[notification userInfo] objectForKey:MGSNoteViewConfigKey];
	if (!number) return;
	eMGSMotherViewConfig mode = [number integerValue];
	
	// get view state
	eMGSViewState viewState = kMGSViewStateToggleVisibility;
	number = [[notification userInfo] objectForKey:MGSNoteViewStateKey];
	if (number) {
		viewState = [number integerValue];
	}
	NSView *view = [[self window] contentView];
	
	switch (mode) {
		
		//
		// toggle the sidebar visibility
		//
		case kMGSMotherViewConfigSidebar:;
			
			BOOL visible = ![self sidebarViewIsHidden];
			
			// toggle the subview visibility.
			// if splitview displayed then sidebar is displayed.
			// pull the rightmost view out of the splitview and replace windowMainView
			if (visible) {
				
				if (viewState == kMGSViewStateShow) return;
				
				NSView *tabView = windowMainView;
				
				// must have at least two views in splitview.
				// if want to display a single view from the splitview
				// then have to replace the splitview
				_dummyView = [[NSView alloc] initWithFrame:[windowMainView frame]];
				
				// swap out the tabview from the splitview and replace thesplitview with the tabview
				[windowSplitView replaceSubview:windowMainView with:_dummyView];
				[windowMainView setFrame:[view bounds]];
				[view replaceSubview:windowSplitView with:windowMainView];
				
				_contentSubview = tabView;
			} else {
				
				if (viewState == kMGSViewStateHide) return;

				// side bar is not visible.
				// put the current windowMainView back into the splitview and redisplay
				[view replaceSubview:_contentSubview with:windowSplitView];
				[windowSplitView setFrame:[view bounds]];
				[windowSplitView replaceSubview:_dummyView with:_contentSubview];
				_contentSubview = windowSplitView;
				_dummyView = nil;
			}
			
			// save user default
			[[NSUserDefaults standardUserDefaults] setBool:!visible forKey:MGSMainSidebarVisible];
			
			// display group list
			if ([[NSUserDefaults standardUserDefaults] boolForKey:MGSDisplayGroupListWhenSidebarHidden]) {
				
				// post view mode change request
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInteger:kMGSMotherViewConfigGroupList], MGSNoteViewConfigKey,
									  [NSNumber numberWithInteger: (viewState == kMGSViewStateHide ? kMGSViewStateShow : kMGSViewStateHide)], MGSNoteViewStateKey,
									  nil];
				[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:self userInfo:dict];
				
			}
			
			break;
						
		default:
			return;
	}
	
	
	// send out completed change notification.
	// this is quite cumbersome: send out a change request note and receive a did change note.
	// seems like the only way to ensure sync endures as the request is allowed to fail.
	// actually, this is over engineered as the controllers observing this notification are available locally.
	NSNotification *noteDone = [NSNotification notificationWithName:MGSNoteViewConfigDidChange 
															 object:[self window]
														   userInfo:[notification userInfo]];
	[[NSNotificationCenter defaultCenter] postNotification:noteDone];
}

/*
 
 authenticate access on current client
 
 */
- (void)authenticateAccess:(NSNotification *)notification
{
	NSNumber *modeNumber = [[notification userInfo] objectForKey:MGSNoteModeKey];
	if (nil == modeNumber) {
		MLog(RELEASELOG, @"access mode is nil");
		return;
	}
	NSInteger accessMode = [modeNumber integerValue];

	// cannot authenticate if connection not validated
	MGSNetClient *netClient = [[mainViewController browserViewController] selectedClient];
	if (!netClient.validatedConnection) {
		
		[[NSNotificationCenter defaultCenter] 
		 postNotificationName:MGSNoteConnectionLimitExceeded 
		 object:netClient 
		 userInfo:nil];
		
		return;
	}	

	// authenticate using configurationa access controller
    MGSConfigurationAccessWindowController *accessController = [[MGSConfigurationAccessWindowController alloc] init];
	[accessController window];	// load the window
	accessController.modalForWindow = [self window];	
	[accessController authenticateNetClient:netClient forAccess:accessMode];
}

/*
 
 log out user on current client
 
 */
- (void)logOut:(NSNotification *)notification
{
	#pragma unused(notification)
	
	MGSNetClient *netClient = [[mainViewController browserViewController] selectedClient];
	
	// clear the authentication dictionary
	[netClient setAuthenticationDictionary:nil];

}

/*
 
 duplicate selected action
 
 */
- (void)duplicateSelectedAction:(NSNotification *)notification
{
	#pragma unused(notification)
	
	// get currently selected action
	MGSTaskSpecifier *taskSpec =  [[mainViewController browserViewController] selectedAction];
	if (!taskSpec) {
		MLog(DEBUGLOG, @"selected task is nil");
		return;
	}
	
	// get our UUID
	NSString *UUID = [[[taskSpec script] UUID] copy];
	
	// copy the action
	taskSpec = [taskSpec mutableDeepCopyAsNewInstance];

	
	// at this stage the script does not contain its code.
	// request entire script with UUID
	MGSNetRequest *netRequest = [[MGSClientRequestManager sharedController] requestScriptWithUUID:UUID netClient:[taskSpec netClient] withOwner:self options:nil];
	netRequest.ownerString = MGSRequestDuplicateAction;
	netRequest.ownerObject = taskSpec;
}


/*
 
 edit the selected action
 
 */
- (void)editSelectedAction:(NSNotification *)notification
{
	#pragma unused(notification)
	
	// get currently selected action
	MGSTaskSpecifier *action =  [[mainViewController browserViewController] selectedAction];
	if (!action) {
		MLog(DEBUGLOG, @"selected task is nil");
		return;
	}
	
	// check if action is already being edited
	if ([self editWindowExistsForAction:action orderFront:YES]) {
		return;
	}

	// check if edit is pending
	if ([self editPendingForAction:action]) {
		return;
	}

	// if cannot edit then  optionally show alert
	if (![action.netClient canEditScript:[action script]] && _suppressApplicationTaskEditAlertSheet == NO) {
		
		NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Application task \"%@\" on %@ cannot be edited.", @"application task edit sheet message"), [[action script] name], action.netClient.serviceShortName];
		NSAlert *alert = [NSAlert alertWithMessageText: alertMessage
										 defaultButton: NSLocalizedString(@"Duplicate", @"Duplicated button text")
									   alternateButton: NSLocalizedString(@"Cancel", @"Cancel button text")
										   otherButton: nil
							 informativeTextWithFormat: NSLocalizedString(@"Application tasks must be duplicated before they can be edited.", @"application task edit sheet info text")];
		[alert setShowsSuppressionButton:YES];
		[[alert suppressionButton] setTitle: NSLocalizedString(@"Do not show in future.", @"application task edit warning suppression button title")];
		
		// run dialog
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(applicationTaskEditWarningAlertDidEnd:returnCode:contextInfo:) contextInfo:action];
		
		return;		
	}
	
	[self requestActionEdit:action];
	
}

/*
 
 delete the selected action
 
 */
- (void)deleteSelectedAction:(NSNotification *)notification
{
	#pragma unused(notification)
	
	MGSTaskSpecifier *actionSpec = [self selectedActionSpecifier];
	NSAssert(actionSpec, @"actionSpec is nil");
	MGSNetClient *netClient  = actionSpec.netClient;
	
	// check if action is already being edited
	if ([self editWindowExistsForAction:actionSpec orderFront:YES]) {
		NSBeginAlertSheet([NSString stringWithFormat:NSLocalizedString(@"Cannot delete application task \"%@\" on %@.", @"Sheet text."), [actionSpec name],[netClient serviceShortName]],
						  NSLocalizedString(@"OK", 
											@"Choice (on a button) given to user."),              //  default button label
						  nil,             //  alternate button label
						  nil,              //  other button label
						  [NSApp mainWindow],	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  NULL,					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  nil,                 // context info
						  NSLocalizedString(@"This window must be closed before the task can be deleted.", 
											@"Warning in the alert panel when user attempts to delete an task being edited."),	// additional text
						  nil);
		return;
	}
	
	//
	// cannot delete bundled scripts
	//
	if (![netClient canEditScript:actionSpec.script]) {
		
		NSBeginAlertSheet([NSString stringWithFormat:NSLocalizedString(@"Cannot delete application task \"%@\" on %@.", @"Sheet text."), [actionSpec name],[netClient serviceShortName]],
						  NSLocalizedString(@"OK", 
											@"Choice (on a button) given to user."),              //  default button label
						  nil,             //  alternate button label
						  nil,              //  other button label
						  [self window],	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  NULL,					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  nil,                 // context info
						  NSLocalizedString(@"Application tasks cannot be deleted.", 
											@"Warning in the alert panel when user attempts to delete an application task."),	// additional text
						  nil);
		
		return;
	}
	
	// prompt to delete
	// note that for a while I thought that windowDidLoad would be called asynschronously
	// but this code seems to work okay
	if (!_deleteController) {
		// load the delete controller
		_deleteController = [[MGSActionDeleteWindowController alloc] init];
		[_deleteController window];	// NSWindowController is lazy - force the window to load
		_deleteController.modalForWindow = [self window];
		_deleteController.delegate = self;
	}
	
	[_deleteController promptToDeleteAction:[actionSpec name] onService:[netClient serviceShortName]];
}

//===================================================
//
// create a new action
//
// create new action and display edit window
//
//===================================================
- (id)createNewAction:(NSNotification *)notification
{
	
	MGSNetClient *netClient = [[mainViewController browserViewController] selectedClient];
	if (nil == netClient) {
		MLog(DEBUGLOG, @"net client is nil");
		return nil;
	}
	
	MGSEditWindowController *editWindowController = [[MGSEditWindowController alloc] init];
	[editWindowController setDelegate:self];
	[editWindowController window];
	[_editWindowControllers addObject:editWindowController];
	
	// create a new script 
	MGSScript *newScript = [MGSScript new]; 
	
	// set script properties
	NSString *source = [[notification userInfo] objectForKey:@"source"];
	if (source) {
		[[newScript scriptCode] setSource:source];
	}
	NSString *scriptType = [[notification userInfo] objectForKey:@"scriptType"];
	if (scriptType) {
		[newScript setScriptType:scriptType];
	}
	
	// set group to that of the currently selected action
	MGSTaskSpecifier *selectedAction =  [[mainViewController browserViewController] selectedAction];
	NSString *selectedActionGroup = [[selectedAction script] group];
	if (selectedActionGroup) {
		[newScript setGroup:selectedActionGroup];
	}
	
	// follow HIG guidelines for naming new documents
	if ([_editWindowControllers count] > 1) {
		NSString *newName = [NSString stringWithFormat:@"%@ %i", [newScript name], [_editWindowControllers count]];
		[newScript setName:newName];
	}
	
	// create task spec
	MGSTaskSpecifier *taskSpec = [[MGSTaskSpecifier alloc] init];	
	taskSpec.taskStatus = MGSTaskStatusNew;
	taskSpec.script = newScript;
	taskSpec.netClient = [[mainViewController browserViewController] selectedClient];
	editWindowController.taskSpec = taskSpec;
	
	// mark new document as edited to prompt save
	[[editWindowController window] setDocumentEdited:YES];
	
	// show edit window
	[editWindowController showWindow:self];
	
	return editWindowController;
}


#pragma mark -
#pragma mark MGSOpenPanelController notifications

/*
 
 - openPanelControllerDidClose:
 
 */
- (void)openPanelControllerDidClose:(NSNotification *)notification
{
	// create new action with selected source file
	[self createNewAction:notification];
}

#pragma mark -
#pragma mark NSWindow notifications
//===================================================
//
// open action in a window
//
//===================================================
- (void)openActionInWindow:(NSNotification *)notification
{
	MGSTaskSpecifier *action = [notification object];
	if (!action) {
		MLog(DEBUGLOG, @"action is nil");
		return;
	}
	
	MGSNetClient *netClient = [action netClient];
	if (nil == netClient) {
		MLog(DEBUGLOG, @"net client is nil");
		return;
	}
	
	MGSActionWindowController *actionWindowController = [[MGSActionWindowController alloc] init];
	[_actionWindowControllers addObject:actionWindowController];
	
	// set window title
	NSString *title = [NSString stringWithFormat:@"%@ %@ — %@", NSLocalizedString(@"Task: ", @"Task window title"),
					   [netClient serviceShortName], [action name]];
	[[actionWindowController window] setTitle: title];	// this will trigger loading
	[actionWindowController setDelegate:self];
	
	// set the window action
	[actionWindowController setAction:action];
	
	// show window
	[actionWindowController showWindow:self];
}

//===================================================
//
// open result in a window
//
//===================================================
- (void)openResultInWindow:(NSNotification *)notification
{
	MGSResult *result = [notification object];
	if (!result) {
		MLog(DEBUGLOG, @"result is nil");
		return;
	}
	
	MGSTaskSpecifier *action = [result action];
	if (!action) {
		MLog(DEBUGLOG, @"action is nil");
		return;
	}
	
	MGSNetClient *netClient = [action netClient];
	if (nil == netClient) {
		MLog(DEBUGLOG, @"net client is nil");
		return;
	}
	
	// get initial view mode
	NSInteger viewMode = [[[notification userInfo] objectForKey:MGSNoteViewConfigKey] integerValue];
	
	// create result window
	MGSResultWindowController *resultWindowController = [[MGSResultWindowController alloc] init];
	[_resultWindowControllers addObject:resultWindowController];
	
	// set window title
	NSString *title = [NSString stringWithFormat:@"%@ %@ — %@", NSLocalizedString(@"Result: ", @"Result window title"),
					   [netClient serviceShortName], [action name]];
	[[resultWindowController window] setTitle: title];	// this will trigger loading
	[resultWindowController setDelegate:self];
	
	// set the window result
	[resultWindowController setResult:result];
	
	
	// change the view mode
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInteger:kMGSViewStateShow], MGSNoteViewStateKey,
						  [NSNumber numberWithInteger:viewMode], MGSNoteViewConfigKey, 
						  nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:[resultWindowController window] userInfo:dict];
	
	// show window
	[resultWindowController showWindow:self];
	
}

#pragma mark -
#pragma mark Properties
/*
 
 set net client
 
 */
- (void)setNetClient:(MGSNetClient *)netClient
{
	// remove observers
	if (self.netClient) {
		@try {
			[self.netClient removeObserver:self forKeyPath:MGSNetClientKeyPathRunMode];		
		} 
		@catch (NSException *e)
		{
			MLog(RELEASELOG, @"%@", [e reason]);
		}
	}
	
	[super setNetClient:netClient];
	
	// add observer
	[self.netClient addObserver:self forKeyPath:MGSNetClientKeyPathRunMode options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:(void *)&MGSNetClientRunModeContext];
}

#pragma mark -
#pragma mark Sheet callbacks
/*
 
 application task edit warning did end
 
 */
- (void) applicationTaskEditWarningAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertAlternateReturn) {
		return;
	}
	
	// suppress alert in future
	_suppressApplicationTaskEditAlertSheet = ([[alert suppressionButton] state] == NSOnState) ? YES : NO;
	
	// sanity check the contextinfo
	if ([(id)contextInfo isKindOfClass:[MGSTaskSpecifier class]]) {
		[self requestActionEdit:contextInfo];
	}
}

/*
 
 validated Connection Limit Alert Did End
 
 */
- (void)validatedConnectionLimitAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	#pragma unused(alert)
	#pragma unused(returnCode)
	#pragma unused(contextInfo)
	
}

#pragma mark -
#pragma mark Action handling
/*
 
 request action edit
 
 */
- (void)requestActionEdit:(MGSTaskSpecifier *)action
{

	// get our UUID
	NSString *UUID = [[[action script] UUID] copy];
	
	// copy the action
	action = [action mutableDeepCopyAsNewInstance];
	
	// at this stage the script does not contain its code.
	// request entire script with UUID
	MGSNetRequest *netRequest = [[MGSClientRequestManager sharedController] requestScriptWithUUID:UUID netClient:[action netClient] withOwner:self options:nil];
	netRequest.ownerString = MGSRequestEditAction;
	netRequest.ownerObject = action;
	
	// add edit pending for this action
	[self addEditPendingForAction:action];
	
}

/*
 
 add edit pending for action
 
 */
- (void)addEditPendingForAction:(MGSTaskSpecifier *)action
{
	NSString *UUID = [[action script] UUID];
	[_actionsPendingEdit setObject:action forKey:UUID];
}

/*
 
 remove edit pending for action
 
 */
- (void)removeEditPendingForAction:(MGSTaskSpecifier *)action
{
	NSString *UUID = [[action script] UUID];
	[_actionsPendingEdit removeObjectForKey:UUID];
}

/*
 
 edit pending for action
 
 */
- (BOOL)editPendingForAction:(MGSTaskSpecifier *)action
{
	NSString *UUID = [[action script] UUID];
	return [self getActionPendingEditWithUUID:UUID] ? YES : NO;
}

/*
 
 get action edit pending with UUID
 
 */
- (MGSTaskSpecifier *)getActionPendingEditWithUUID:(NSString *)UUID
{
	return [_actionsPendingEdit objectForKey:UUID];
}

/* 
 
 edit window exists for action
 
 */
- (BOOL)editWindowExistsForAction:(MGSTaskSpecifier *)action orderFront:(BOOL)orderFront
{
	NSString *UUID = [action UUID];	// unique identifier from script
	for (MGSEditWindowController *editWindowController in _editWindowControllers) {
		if ([[editWindowController.taskSpec UUID] isEqualToString:UUID]) {
			
			if (orderFront) {
				[[editWindowController window] makeKeyAndOrderFront:self];
			}
			
			return YES;
		}
	}	
	
	return NO;
}
		
/*
 
 edit the action
 
 */
- (MGSEditWindowController *)editAction:(MGSTaskSpecifier *)action
{
	if (!action) {
		MLog(RELEASELOG, @"action is nil");
		return nil;
	}
		
	// check if action is already being edited
	if ([self editWindowExistsForAction:action  orderFront:YES]) {
		return nil;
	}
	
	// get a deep copy of the action
	action = [action mutableDeepCopyAsNewInstance];	
	
	// create edit window
	MGSEditWindowController *editWindowController = [[MGSEditWindowController alloc] init];
	[editWindowController setDelegate:self];	
	[editWindowController window]; // this will trigger loading
	[_editWindowControllers addObject:editWindowController];
	
	// set action
	editWindowController.taskSpec = action;
	
	// mark document as not yet edited
	[[editWindowController window] setDocumentEdited:NO];
	
	// show window
	[editWindowController showWindow:self];
	
	return editWindowController;
}



@end



