//
//  MGSToolbarController.m
//  Mother
//
//  Modified from Apple sample code.
// also see SimpleToolbar example in /developer/examples/appkit
//
//  Created by Jonathan on 02/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSToolbarController.h"
#import "MGSTaskSpecifier.h"
#import "MGSDisplayToolViewController.h"
#import "MGSModeToolViewController.h"
#import "MGSEditModeToolViewController.h"
#import "MGSViewToolViewController.h"
#import "MGSActionToolViewController.h"
#import "MGSScriptToolViewController.h"
#import "MGSBrowserToolViewController.h"
#import "MGSresultToolViewController.h"
#import "MGSMinimalViewToolViewController.h"
#import "MGSNotifications.h"
#import "MGSMotherModes.h"
#import "NSToolbar_Mugginsoft.h"
#import "MGSNetClient.h"
#import "MGSNetClientContext.h"
#import "MGSToolbarItem.h"

NSString *MGSToolbarEditMode = @"editmode";
NSString *MGSToolbarMode = @"mode";
NSString *MGSToolbarTransport = @"transport";
NSString *MGSToolbarDisplay = @"display";
NSString *MGSToolbarBrowser = @"browser";
NSString *MGSToolbarView = @"view";
NSString *MGSToolbarSearch = @"search";
NSString *MGSToolbarAction = @"action";
NSString *MGSToolbarScript = @"script";
NSString *MGSToolbarResult = @"result";
NSString *MGSToolbarMinimal = @"minimal";

const char MGSNetClientRunModeContext;

static void addToolbarItem(NSMutableDictionary *theDict,NSString *identifier,NSString *label,NSString *paletteLabel,NSString *toolTip,id target,SEL settingSelector, id itemContent,SEL action, NSMenu * menu, id delegate);

//class extension
@interface MGSToolbarController()
- (void)windowEditModeChanged:(NSNotification *)notification;
- (void)actionChanged:(NSNotification *)notification;
- (void)windowSizeModeChanged:(NSNotification *)notification;
- (void)netClientSelected:(NSNotification *)notification;
- (void)mainBrowserModeChanged:(NSNotification *)notification;
@end

@implementation MGSToolbarController

@synthesize window;
@synthesize actionSpecifier = _actionSpecifier;
@synthesize style = _style;
@synthesize identifier = _identifier;

@synthesize displayPanelController;
@synthesize modeViewController;
@synthesize actionViewController;
@synthesize editModeViewController;
@synthesize scriptViewController;
@synthesize resultViewController;
@synthesize minimalViewController;
@synthesize netClient = _netClient;

#pragma mark Instance handling
/*
 
 init
 
 note that we do not load views from nib initially
 this means we can preconfigure our toolbar
 
 */
- (id)init
{
	if ((self = [super init])) {
		_style = MGSToolbarStyleMain;
	}
	
	return self;
}
/*
 
 load the nib
 
 */
- (void)loadNib
{
	[NSBundle loadNibNamed:@"Toolbar" owner:self];
}

/*
 
 set delegate
 
 */
- (void)setDelegate:(id <MGSToolbarDelegate>)object
{
	_delegate = object;
	
	// normally toolbar items use an action/target model.
	// in this case a separate view controller handles the interaction with a delegate.
	// in general the delegate will be the window controller
	for (id controller in _utilisedControllers) {
		if ([controller respondsToSelector:@selector(setDelegate:)]) {
			[controller setDelegate:_delegate];
		}
	}
}


/*
 
 awake from nib
 
 */
-(void)awakeFromNib
{	
	// create the toolbar
	// Within the application all toolbars with the same identifier are synchronized to maintain the same state, 
	// including for example, the display mode and item order. The identifier is used as the autosave name for toolbars that save their configuration.
	// therefore, each tool bar needs its own identifier
	//
	NSAssert(_identifier, @"toolbar identifier is nil");
	toolbar=[[NSToolbar alloc] initWithIdentifier:_identifier];
    [toolbar setShowsBaselineSeparator:YES];
	[toolbar setSizeMode:NSToolbarSizeModeRegular];
	
    // Here we create the dictionary to hold all of our "master" NSToolbarItems.
    toolbarItems=[NSMutableDictionary dictionary];
	
	//
	// This implementation is complex and does not make us of the normal target-action pattern.
	// Indeed the action for these toolbaritems is not even set.
	// This means that the normal method of validating toolbaritems cannot be used.
	//
	// Having separate view controllers for the toolbar views makes things complicated.
	// These views send out notifications as opposed to sending actions to targets.
	// Probabl would have been better to use the responder chain or target the actions more directly
	// but some of the toolbar views have reasonably complicated behaviour so perhaps there would be escaping
	// the use of notifications.
	//
	switch (_style) {
		
		//*****************************
		// edit window style
		//*****************************
		case MGSToolbarStyleEdit:
			addToolbarItem(toolbarItems,MGSToolbarEditMode,nil,nil,nil,self,@selector(setView:), editModeViewController.view,NULL,nil,editModeViewController);
			addToolbarItem(toolbarItems,MGSToolbarScript,nil,nil,nil,self,@selector(setView:), scriptViewController.view,NULL,nil,scriptViewController);
			addToolbarItem(toolbarItems,MGSToolbarDisplay,nil,MGSToolbarDisplay,nil,self,@selector(setView:), displayPanelController.view,NULL,nil,displayPanelController);
		
			// initialise the toolviews
			[editModeViewController initialiseForWindow:window];
			[scriptViewController initialiseForWindow:window];
			[displayPanelController initialiseForWindow:window];
			
			// observe window edit mode changes for toolbar window
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowEditModeChanged:) name:MGSNoteWindowEditModeDidChange object:window];

			// register to receive action changed notification
			// this is sent when the selected action changes 
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionChanged:) name:MGSNoteActionSelectionChanged object:nil];
			
			[self setUtilisedControllers:[NSArray arrayWithObjects:editModeViewController, scriptViewController, displayPanelController, nil]];
			
			break;

		//*****************************
		// action window style
		//*****************************
		case MGSToolbarStyleAction:
			addToolbarItem(toolbarItems,MGSToolbarDisplay,nil,MGSToolbarDisplay,nil,self,@selector(setView:), displayPanelController.view,NULL,nil,displayPanelController);
			addToolbarItem(toolbarItems,MGSToolbarMinimal,nil,nil,nil,self,@selector(setView:), minimalViewController.view,NULL,nil,minimalViewController);
			
			// initialise the toolviews
			[displayPanelController initialiseForWindow:window];
			[minimalViewController initialiseForWindow:window];

			// observe window size mode changes for toolbar window
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowSizeModeChanged:) name:MGSNoteWindowSizeModeChanged object:window];

			// register to receive action changed notification
			// this is sent when the selected action changes within the main view
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionChanged:) name:MGSNoteActionSelectionChanged object:nil];
			
			[self setUtilisedControllers:[NSArray arrayWithObjects:displayPanelController, minimalViewController, nil]];
			
			break;

		//*****************************
		// result window style
		//*****************************
		case MGSToolbarStyleResult:

			addToolbarItem(toolbarItems,MGSToolbarResult,nil,MGSToolbarResult,nil,self,@selector(setView:), resultViewController.view,NULL,nil,resultViewController);
			
			// initialise the toolviews

			[resultViewController initialiseForWindow:window];

			[self setUtilisedControllers:[NSArray arrayWithObjects:resultViewController, nil]];

			break;
			
		//*****************************
		// app main window style
		//*****************************
		case MGSToolbarStyleMain:
		default:
			/*
			 
			 overflow menu note
			 
			 the overflow menu will be constructed automatically if required.
			 NSToolBarItem labels will be use in text only mode and in the overflow menu.
			 if an NSToolbarItem has an assocaited NSMenu representation then this will be used in the overflow menu.
			 
			 for more info search docs for "Setting a Toolbar Item’s Representation"
			 */
			addToolbarItem(toolbarItems,MGSToolbarMode,nil,nil,nil,self,@selector(setView:), modeViewController.view,NULL,nil,modeViewController);
			addToolbarItem(toolbarItems,MGSToolbarDisplay,nil,MGSToolbarDisplay,nil,self,@selector(setView:), displayPanelController.view,NULL,nil, displayPanelController);
			addToolbarItem(toolbarItems,MGSToolbarAction,nil,nil,nil,self,@selector(setView:), actionViewController.view,NULL,nil,actionViewController);
			addToolbarItem(toolbarItems,MGSToolbarSearch,NSLocalizedString(@"Search", @"Search toolbar label"),nil,nil,self,@selector(setView:), searchView, NULL,nil,nil);
			
			// the tool views are manually initialised.
			// they nolonger respond to awakeFromNib as 
			// as unutilised views were sending off unnrequired notifications
			[modeViewController initialiseForWindow:window];
			[displayPanelController initialiseForWindow:window];
			[actionViewController initialiseForWindow:window];
			
			// register to receive action changed notification
			// this is sent when the selected action changes within the main view
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionChanged:) name:MGSNoteActionSelectionChanged object:nil];
			
			// register for client selected notification
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientSelected:) name:MGSNoteClientSelected object:nil];

			// register for activate search notification
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainBrowserModeChanged:) name:MGSNoteMainBrowserModeChanged object:nil];

			[self setUtilisedControllers:[NSArray arrayWithObjects:modeViewController, displayPanelController, actionViewController, nil]];
			
			break;
	}
	
		
    // the toolbar wants to know who is going to handle processing of NSToolbarItems for it.  This controller will.
    [toolbar setDelegate:self];

	
    // If you pass NO here, you turn off the customization palette.  The palette is normally handled automatically
    // for you by NSWindow's -runToolbarCustomizationPalette: method; you'll notice that the "Customize Toolbar"
    // menu item is hooked up to that method in Interface Builder.  Interface Builder currently doesn't automatically 
    // show this action (or the -toggleToolbarShown: action) for First Responder/NSWindow (this is a bug), so you 
    // have to manually add those methods to the First Responder in Interface Builder (by hitting return on the First Responder and 
    // adding the new actions in the usual way) if you want to wire up menus to them.
    [toolbar setAllowsUserCustomization:NO];
	
    // tell the toolbar that it should save any configuration changes to user defaults.  ie. mode changes, or reordering will persist. 
    // specifically they will be written in the app domain using the toolbar identifier as the key. 
    [toolbar setAutosavesConfiguration: NO]; 
    
    // tell the toolbar to show icons only by default
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];

    // install the toolbar.
    [window setToolbar:toolbar];
}

#pragma mark NSToolbarItem handling


// This method is required of NSToolbar delegates.  It takes an identifier, and returns the matching NSToolbarItem.
// It also takes a parameter telling whether this toolbar item is going into an actual toolbar, or whether it's
// going to be displayed in a customization palette.
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
#pragma unused(toolbar)
#pragma unused(flag)
	
    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    NSToolbarItem *newItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    NSToolbarItem *item=[toolbarItems objectForKey:itemIdentifier];
    
    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=NULL)
    {
		[newItem setView:[item view]];
    }
    else
    {
		[newItem setImage:[item image]];
    }
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
	
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view]!=NULL)
    {
		NSSize size = [[item view] bounds].size;
		[newItem setMinSize:size];
		[newItem setMaxSize:size];
    }
	
    return newItem;
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
// set of toolbar items.  It can also be called by the customization palette to display the default toolbar.    
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
#pragma unused(toolbar)
	
	NSArray *array;
	
	switch (_style) {
		case MGSToolbarStyleEdit:
			array = [NSArray arrayWithObjects:MGSToolbarEditMode, nil];
			break;
			
		case MGSToolbarStyleAction:
			array = [NSArray arrayWithObjects:NSToolbarFlexibleSpaceItemIdentifier, MGSToolbarDisplay, MGSToolbarMinimal, NSToolbarFlexibleSpaceItemIdentifier, nil];
			break;
			
		case MGSToolbarStyleResult:
			array = [NSArray arrayWithObjects:MGSToolbarResult, NSToolbarFlexibleSpaceItemIdentifier,  nil];
			break;
			
		case MGSToolbarStyleMain:
		default:
			//array = [NSArray arrayWithObjects:MGSToolbarMode, MGSToolbarDisplay, MGSToolbarBrowser, MGSToolbarSearch, nil];
			array = [NSArray arrayWithObjects:MGSToolbarMode, NSToolbarFlexibleSpaceItemIdentifier, MGSToolbarDisplay, NSToolbarFlexibleSpaceItemIdentifier,MGSToolbarView, MGSToolbarSearch, nil];
			break;
	}
	
	return array;
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
// toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)aToolbar
{
	return [self toolbarDefaultItemIdentifiers:aToolbar];
}



/*
 
 set utilsed controllers

 as this controller loads all our toolbar controllers it is efficient
 to discard that will  not be required
 
 */
- (void)setUtilisedControllers:(NSArray *)controllers
{
	_utilisedControllers = controllers;

	if (![_utilisedControllers containsObject:displayPanelController]) displayPanelController = nil;
	if (![_utilisedControllers containsObject:modeViewController]) modeViewController = nil;
	if (![_utilisedControllers containsObject:actionViewController]) actionViewController = nil;
	if (![_utilisedControllers containsObject:editModeViewController]) editModeViewController = nil;
	if (![_utilisedControllers containsObject:scriptViewController]) scriptViewController = nil;
	if (![_utilisedControllers containsObject:resultViewController]) resultViewController = nil;
	if (![_utilisedControllers containsObject:minimalViewController]) minimalViewController = nil;
}

/*
 
 discard unutilsed controller
 
 as this controller loads all our toolbar controllers it is efficient
 to discard that will  not be required
 
 */
- (void)discardUnutilisedController:(id *)controller
{
	if (![_utilisedControllers containsObject:*controller])  {
		controller = nil;
	}
}

#pragma mark Accessors
/*
 
 set run mode
 
 */
- (void)setRunMode:(NSInteger)mode
{
	switch (mode) {
			
			// configure actions
		case kMGSMotherRunModeConfigure:
			[toolbar removeItemWithItemIdentifier:MGSToolbarDisplay];
			
			if ([toolbar indexOfItemWithItemIdentifier:MGSToolbarAction] == -1) {
				[toolbar insertItemWithItemIdentifier:MGSToolbarAction atIndex:2];
			}
			break; 
			
			// run actions
			case kMGSMotherRunModePublic:
			case kMGSMotherRunModeAuthenticatedUser:
			[toolbar removeItemWithItemIdentifier:MGSToolbarAction];
			
			if ([toolbar indexOfItemWithItemIdentifier:MGSToolbarDisplay] == -1) {
				[toolbar insertItemWithItemIdentifier:MGSToolbarDisplay atIndex:2];
			}
			break;
	}
}

/*
 
 set the currently selected action
 
 */
- (void)setActionSpecifier:(MGSTaskSpecifier *)action
{
	_actionSpecifier = action;
	
	for (id controller in _utilisedControllers) {
		if ([controller respondsToSelector:@selector(setActionSpecifier:)]) {
			[controller setActionSpecifier:action];
		}
	}
}

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
	
	_netClient = netClient;
	
	// add observer
	[self.netClient addObserver:self forKeyPath:MGSNetClientKeyPathRunMode options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:(void *)&MGSNetClientRunModeContext];
	
	[self setRunMode:[netClient contextForWindow:[self window]].runMode];
}
#pragma mark NSNotificationCenter callbacks
/*
 
 action changed notification
 
 */
- (void)actionChanged:(NSNotification *)notification
{
	if ([notification object] != self.window) return;
	
	MGSTaskSpecifier *action = [[notification userInfo] objectForKey:MGSActionKey];
	[self setActionSpecifier:action];	
}

/*
 
 toolbar window edit mode changed
 
 */
- (void)windowEditModeChanged:(NSNotification *)notification
{
	int mode = [[[notification userInfo] objectForKey:MGSNoteModeKey] intValue];
	
	switch (_style) {
			
			//*****************************
			// edit window style
			//*****************************
		case MGSToolbarStyleEdit:
			// reset tool bar
			[toolbar removeItemsStartingAtIndex:1];
			
			switch (mode) {
					
					// configure action
				case kMGSMotherEditModeConfigure:
					break; 
					
					// script action
				case kMGSMotherEditModeScript:
					[toolbar insertItemWithItemIdentifier:MGSToolbarScript atIndex:1];
					break;
					
					// run action
				case kMGSMotherEditModeRun:
					[toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:1];
					[toolbar insertItemWithItemIdentifier:MGSToolbarDisplay atIndex:2];
					[toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:3];
					
					// add spaces to right to compensate for the segment control on the left.
					// this helps to keep the display item centred within the toolbar
					[toolbar insertItemWithItemIdentifier:NSToolbarSpaceItemIdentifier atIndex:4];
					[toolbar insertItemWithItemIdentifier:NSToolbarSpaceItemIdentifier atIndex:5];
					[toolbar insertItemWithItemIdentifier:NSToolbarSpaceItemIdentifier atIndex:6];
					break;	
			}
			break;
			
		default:
			break;
	}
}

/*
 
 toolbar window size mode changed
 
 */
- (void)windowSizeModeChanged:(NSNotification *)notification
{
	int mode = [[[notification userInfo] objectForKey:MGSNoteModeKey] intValue];
	
	switch (_style) {
			
			//*****************************
			// action toolbar style
			//*****************************
		case MGSToolbarStyleAction:
			
			switch (mode) {
					
					// normal size
				case kMGSMotherSizeModeNormal:
					[toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:2];
					[toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:0];
					break;
					
					// minimal size
				case kMGSMotherSizeModeMinimal:
					[toolbar removeItemAtIndex:3];
					[toolbar removeItemAtIndex:0];
					break;	
			}
			break;
			
		default:
			break;
	}
	
}

/*
 
 net client selected in browser
 
 */
- (void)netClientSelected:(NSNotification *)notification
{	
	NSDictionary *userInfo = [notification userInfo];
	MGSNetClient *netClient = [userInfo objectForKey:MGSNoteNetClientKey];

	self.netClient = netClient;
}

/*
 
 main browser mode changed
 
 */
- (void)mainBrowserModeChanged:(NSNotification *)notification
{	
	NSDictionary *userInfo = [notification userInfo];
	
	NSInteger mode = [[userInfo objectForKey:MGSNoteViewConfigKey] integerValue];
	
	// if search displayed make search field the first responder
	if (mode == kMGSMainBrowseModeSearch) {
		[[self window] makeFirstResponder:searchField];
	}
}

// This is an optional delegate method, called when a new item is about to be added to the toolbar.
// This is a good spot to set up initial state information for toolbar items, particularly ones
// that you don't directly control yourself (like with NSToolbarPrintItemIdentifier here).
// The notification's object is the toolbar, and the @"item" key in the userInfo is the toolbar item
// being added.
- (void) toolbarWillAddItem: (NSNotification *) notif
{
#pragma unused(notif)
	
	// NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
    // Is this the printing toolbar item?  If so, then we want to redirect it's action to ourselves
    // so we can handle the printing properly; hence, we give it a new target.
    /*if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier])
	 {
	 [addedItem setToolTip: @"Print your document"];
	 [addedItem setTarget: self];
	 }*/
}  



#pragma mark KVO

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &MGSNetClientRunModeContext) {
		
		// run mode changed
		NSInteger runMode = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
		[self setRunMode:runMode];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Menu handling
/*
 
 validate menu item
 
 */
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	#pragma unused(menuItem)
	
	return YES;
}

/*
 
 validate toolbar item
 
 */
 - (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	#pragma unused(theItem)
	
	// most of the validation is performed by the NSToolbarItems view controller.
	// in fact most of our NSToolbarItems don't even have an action defined.
	
    return YES;
}

#pragma mark Target actions
/*
 
 update search filter
 
 */
- (IBAction)updateSearchFilter:(id)sender
{
    NSString *searchString = [sender stringValue];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:searchString, MGSNoteValueKey , nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteSearchFilterChanged object:self userInfo:dict];
}
@end


// All NSToolbarItems have a unique identifer associated with them, used to tell your delegate/controller what 
// toolbar items to initialize and return at various points.  Typically, for a given identifier, you need to 
// generate a copy of your "master" toolbar item, and return it autoreleased.  The function below takes an
// NSMutableDictionary to hold your master NSToolbarItems and a bunch of NSToolbarItem paramenters,
// and it creates a new NSToolbarItem with those parameters, adding it to the dictionary.  Then the dictionary
// can be used from -toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar: to generate a new copy of the 
// requested NSToolbarItem (when the toolbar wants to redraw, for instance) by simply duplicating and returning
// the NSToolbarItem that has the same identifier in the dictionary.  Plus, it's easy to call this function
// repeatedly to generate lots of NSToolbarItems for your toolbar.
// -------
// label, palettelabel, toolTip, action, and menu can all be NULL, depending upon what you want the item to do
static void addToolbarItem(NSMutableDictionary *theDict,NSString *identifier,NSString *label,NSString *paletteLabel,NSString *toolTip,id target,SEL settingSelector, id itemContent,SEL action, NSMenu * menu, id delegate)
{
    NSMenuItem *mItem;
	
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    MGSToolbarItem *item = [[MGSToolbarItem alloc] initWithItemIdentifier:identifier];
	item.delegate = delegate;
	
	// label is used for text only menu representation and for overflow menu
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
	
    // the settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
    // one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
    // (in the itemContent parameter).  Then this next line will do the right thing automatically.
    [item performSelector:settingSelector withObject:itemContent];
    [item setAction:action];
	if (!action) {
		//item.autovalidates = NO;	// we are not setting an action
	}
	
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
    // we set it up here.  Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
    // so we create a dummy NSMenuItem that has our real menu as a submenu.
    if (menu!=NULL)
    {
		// we actually need an NSMenuItem here, so we construct one
		mItem=[[NSMenuItem alloc] init];
		[mItem setSubmenu: menu];
		[mItem setTitle: [menu title]];
		[item setMenuFormRepresentation:mItem];
    }
	
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
}
