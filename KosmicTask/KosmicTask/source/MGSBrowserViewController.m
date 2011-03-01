//
//  MGSBrowseViewController.m
//  Mother
//
//  Created by Jonathan on 24/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSBrowserViewController.h"
#import "MGSNetClient.h"
#import "MGSNetClientContext.h"
#import "MGSNetRequestManager.h"
#import "MGSNetMessage.h"
#import "MGSClientScriptManager.h"
#import "MGSClientTaskController.h"
#import "MGSScriptPlist.h"
#import "MGSScript.h"
#import "NSView_Mugginsoft.h"
#import "MGSClientRequestManager.h"
#import "MGSTaskSpecifierManager.h"
#import "MGSTaskSpecifier.h"
#import "iTableColumnHeaderCell.h"
#import "NSTableView_Mugginsoft.h"
#import "NSSplitView_Mugginsoft.h"
#import "MGSNotifications.h"
#import "MGSMotherModes.h"
#import "MGSImageManager.h"
#import "MGSBrowserSplitView.h"
#import "MGSScriptManager.h"
#import "MGSSaveConfigurationWindowController.h"
#import "MGSActionDeleteWindowController.h"
#import "MGSEditWindowController.h"
#import "MGSNetRequestPayload.h"
#import "MGSAttachedWindowController.h"
#import "MGSLM.h"
#import "MGSImageAndText.h"
#import "MGSImageAndTextCell.h"
#import "MGSResourceImages.h"
#import "FVColorMenuView.h"
#import "MGSCapsuleTextCell.h"
#import "MGSLabelTextCell.h"
#import "MGSPreferences.h"

#define LMTestInterval 5 * 60	// licence manager test interval


// table column names
NSString *MGSTableColumnIdentifierMachine = @"machine";
NSString *MGSTableColumnIdentifierService = @"service";
NSString *MGSTableColumnIdentifierUser = @"user";
NSString *MGSTableColumnIdentifierName = @"name";
NSString *MGSTableColumnIdentifierAction = @"action";
NSString *MGSTableColumnIdentifierSecurity = @"secure";
NSString *MGSTableColumnIdentifierAuthenticate = @"authenticate";
NSString *MGSTableColumnIdentifierDescription = @"description";
NSString *MGSTableColumnIdentifierPublished = @"published";
NSString *MGSTableColumnIdentifierBundled = @"bundled";
NSString *MGSTableColumnIdentifierPublishCheckbox = @"check";
NSString *MGSTableColumnIdentifierStatus = @"status";
NSString *MGSTableColumnIdentifierUUID = @"UUID";
NSString *MGSTableColumnIdentifierRating = @"rating";

// class extension
@interface MGSBrowserViewController()
- (void)tableViewDoubleClick:(id)aTableView;
- (void)appRunModeChanged:(NSNotification *)notification;
- (void)netClientSelected:(NSNotification *)notification;
- (void)netClientItemSelected:(NSNotification *)notification;
- (void)suggestExitEditMode:(NSNotification *)notification;
- (void)viewConfigChangeRequest:(NSNotification *)notification;
- (void)groupIconWindowItemSelected:(NSNotification *)notification;
- (void)LMTimerExpired:(NSTimer*)theTimer;
- (void)refreshAction:(NSNotification *)notification;
@end

@interface MGSBrowserViewController (Private)
- (void)setDeselectGroupAndActionTableViews:(BOOL)deselect;
- (void)makeTableColumnCheck:(NSTableColumn *)tableColumn withTarget:(id)target withSelector:(SEL)selector;
- (void)makeTableColumnIcon:(NSTableColumn *)tableColumn;
- (void)updateStatusBarCaption;
- (void)reloadAllTableData;
- (void)reloadGroupTableData;
- (void)reloadActionTableData;
- (void)reloadMachineTableData;
- (void)dispatchSelectedAction;
- (void)dispatchTaskSpecAtRowIndex:(NSInteger) rowIndex displayType:(MGSTaskDisplayType)actionDisplayType;
- (MGSTaskSpecifier *)actionCopyAtRowIndex:(NSInteger)rowIndex;
- (MGSTaskSpecifier *)actionCopyWithUUID:(NSString *)UUID;
- (void)actionSelected;
- (NSInteger)searchTableView:(NSTableView *)aTableView columnIdentifier:(NSString *)column rowForValue:(id)value searchKey:(NSString *)key;
- (void)setClientRunMode:(NSInteger)mode;
- (void)promptToExitEditMode;
- (BOOL)computerListVisible;
- (MGSScript *)selectedScript;
- (MGSScript *)clickedScript;
- (MGSScript *)scriptAtRow:(NSInteger)rowIndex;
- (void)clientListChanged:(MGSNetClient *)netClient;
- (void)addClientObservations:(MGSNetClient *)netClient;
- (void)removeClientObservations:(MGSNetClient *)netClient;
- (void)selectedClientNeedsDisplay;
- (void)sendClientSelectedNotification:(NSString *)name options:(NSDictionary *)options;
- (NSTimeInterval)startDelay;
- (void)setObject:(id)object forClientStore:(MGSNetClient *)netClient;
- (NSMutableDictionary *)clientStore:(MGSNetClient *)netClient;
- (void)sortTableViewAndReloadData:(NSTableView *)tableView;
- (void)groupSelected;
- (void)tableViewCheckClick: (NSTableView *)tableView;
- (void)promptExitSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
@end

@interface MGSBrowserViewController (Sizing)
- (CGFloat)machineTableMinWidth;
- (CGFloat)actionTableMinWidth;
- (CGFloat)groupTableMinWidth;
@end

@interface MGSBrowserViewController (DataSource)
- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors;
- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
@end

@implementation MGSBrowserViewController
@synthesize machineTable;
@synthesize viewEffect = _viewEffect;
@synthesize sharingView = _sharingView;

// problem using this 
// awakeFromNib was not called
//
/*
- (id)initWithDelegate:(id <MGSBrowserViewControllerDelegate>)delegate
{
	if (self = [super initWithNibName:@"BrowserView" bundle:nil]) {
		[self setDelegate:delegate];
	}
	return self;
}
 */

#pragma mark Instance handling
/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		_nibLoaded = NO;
		_LMTimer = nil;
	}
	return self;
}

/*
 
 delegate
 
 */
-(id <MGSBrowserViewControllerDelegate>)delegate
{
	return _delegate;
}

/*
 
 set delegate
 
 */
- (void)setDelegate:(id <MGSBrowserViewControllerDelegate>)delegate
{
	_delegate = delegate;
}

/*
 
 awake from nib
 
 */
- (void) awakeFromNib {
	
	if (_nibLoaded) {
		return;
	}
	
	_nibLoaded = YES;
	_postNetClientSelectionNotifications = YES;
	
	_clientStore = [NSMutableDictionary dictionaryWithCapacity:1];
	_viewEffect = NSView_animateEffectNone;	// don't fade in the initial view
	_browserView = splitView;
	[splitView setDelegate:self];
	
	_netClientHandler = [MGSNetClientManager sharedController];
	NSTableColumn *tableColumn;
	NSTableHeaderCell *headerCell;
	NSSortDescriptor *sortDescriptor;
	
	//============================================
	// Set up the machine table
	//============================================
	[machineTable setAllowsEmptySelection:NO];
	[machineTable setCornerView:[[MGSImageManager sharedManager] splitDragThumbView]];

	// status column
	tableColumn = [machineTable tableColumnWithIdentifier: MGSTableColumnIdentifierStatus];
	[[tableColumn headerCell] setImage:[[[MGSImageManager sharedManager] onlineStatusHeader] copy]];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"hostSortIndex" ascending:YES];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];

	// user column
	tableColumn = [machineTable tableColumnWithIdentifier: MGSTableColumnIdentifierUser];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"hostUserName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];

	// machine column
	tableColumn = [machineTable tableColumnWithIdentifier: MGSTableColumnIdentifierMachine];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"serviceShortName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];

	// security column
	tableColumn = [machineTable tableColumnWithIdentifier: MGSTableColumnIdentifierSecurity];
	[[tableColumn headerCell] setImage:[[[MGSImageManager sharedManager] lockLockedTemplate] copy]];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"useSSL" ascending:YES];
	[tableColumn setSortDescriptorPrototype:sortDescriptor]; 

	// authenticate column
	tableColumn = [machineTable tableColumnWithIdentifier: MGSTableColumnIdentifierAuthenticate];
	[[tableColumn headerCell] setImage:(NSImage *)[[[MGSImageManager sharedManager] user] copy]];
	//sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"useSSL" ascending:YES];
	//[tableColumn setSortDescriptorPrototype:sortDescriptor]; 
	
	//============================================
	// set up the group table
	//============================================	
	[groupTable setAllowsEmptySelection:NO];
	[groupTable setCornerView:[[MGSImageManager sharedManager] splitDragThumbView]];
	[groupTable setTarget:self];

	// name column
	tableColumn = [groupTable tableColumnWithIdentifier: MGSTableColumnIdentifierName];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];
	
	// checkbox column
	tableColumn = [groupTable tableColumnWithIdentifier: MGSTableColumnIdentifierPublishCheckbox];
	//[[tableColumn headerCell] setAlignment:NSCenterTextAlignment];
	[[tableColumn headerCell] setImage: [[[MGSImageManager sharedManager] publishedActionTemplate] copy]];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"published" ascending:YES];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];
	
	// published column
	tableColumn = [groupTable tableColumnWithIdentifier: MGSTableColumnIdentifierPublished];
	[[tableColumn headerCell] setImage: [[[MGSImageManager sharedManager] publishedActionTemplate] copy]];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"published" ascending:YES];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];

	[groupTable setDoubleAction:@selector(tableViewDoubleClick:)];

	
	//============================================
	// set up the action table
	//============================================	
	[actionTable setAllowsEmptySelection:NO];
	[actionTable setTarget:self];

	// checkbox column
	tableColumn = [actionTable tableColumnWithIdentifier: MGSTableColumnIdentifierPublishCheckbox];
	[[tableColumn headerCell] setImage: [[[MGSImageManager sharedManager] quickLookTemplate] copy]];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"published" ascending:YES];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];
	
	// published column
	tableColumn = [actionTable tableColumnWithIdentifier: MGSTableColumnIdentifierPublished];
	headerCell = [tableColumn headerCell];
	[headerCell setImage:[[[MGSImageManager sharedManager] quickLookTemplate] copy]];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"published" ascending:YES];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];

	// rating column
	tableColumn = [actionTable tableColumnWithIdentifier: MGSTableColumnIdentifierRating];
	id cell = [tableColumn dataCell];
	if ([cell isKindOfClass:[NSLevelIndicatorCell class]]) {
		[cell setImage:[NSImage imageNamed:@"StarRating"]];
	}
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ratingIndex" ascending:YES];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];

	// bundled column
	tableColumn = [actionTable tableColumnWithIdentifier: MGSTableColumnIdentifierBundled];
	headerCell = [tableColumn headerCell];
	
	[headerCell setImage:[NSImage imageNamed:@"GearSmall"]];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"isBundled" ascending:YES];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];
	
	// description column sorting
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	tableColumn = [actionTable tableColumnWithIdentifier: MGSTableColumnIdentifierDescription];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];

	// action column sorting
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	tableColumn = [actionTable tableColumnWithIdentifier: MGSTableColumnIdentifierAction];
	[tableColumn setSortDescriptorPrototype:sortDescriptor];
	
	// set table actions
	//[actionTable setAction:@selector(tableViewSingleClick:)];
	[actionTable setDoubleAction:@selector(tableViewDoubleClick:)];
	
	// set action table context menus menus
	NSMenuItem *labelMenu = [[actionTable menu] itemWithTag:100];	// label menu
	FVColorMenuView *menuView = [FVColorMenuView menuView];
	[menuView setTarget:self];
	[menuView setAction:@selector(changeTaskLabelColour:)];
	[labelMenu setView:menuView];
	
	//
	// other
	//
	
	// startup the network services browser
	//
	// note that it is very poor design to assign a delegate here as 
	// _netClientHandler [MGSNetClientManager sharedController] points to a singleton.
	// the delegate could be easily replaced by another object.
	//
	// as it is the setDelegate: method raises an internal assertion exception if an attempt is made
	//
	[_netClientHandler setDelegate: self];
	[_netClientHandler searchForServices];
	
	[self updateStatusBarCaption];
	
	_showActionInNewTab = NO;
	_allowActionDispatch = YES;
	
	[self setClientRunMode:kMGSMotherRunModePublic];
	
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appRunModeChanged:) name:MGSNoteAppRunModeChanged object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientSelected:) name:MGSNoteClientSelected object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientItemSelected:) name:MGSNoteClientItemSelected object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(suggestExitEditMode:) name:MGSNoteClientClickDuringEdit object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewConfigChangeRequest:) name:MGSNoteViewConfigChangeRequest object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupIconWindowItemSelected:) name:MGSNoteGroupIconWindowItemSelected object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAction:) name:MGSNoteRefreshAction object:nil];
	
	
	
	// create startup timer.
	// delay to allow clients to connect.
	// if the local host connects before the timer expires then :
	// 1. the local client is selected
	// 2. the timer is expired
	_startupTimer = [NSTimer scheduledTimerWithTimeInterval:[self startDelay] target:self selector:@selector(startupTimerExpired:) userInfo:nil repeats:NO];
	
} /*awakeFromNib*/

#pragma mark -
#pragma mark ActionSpecifier handling

/*
 
 return currently selected action
 
 */
- (MGSTaskSpecifier *)selectedAction
{
	MGSTaskSpecifier *action = [self actionCopyAtRowIndex:[actionTable selectedRow]];
	
	return action;
}

#pragma mark -
#pragma mark Menu handling
/*
 
 validate menu item
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    SEL action = [anItem action];
    
	// change task label colour
    if (action == @selector(changeTaskLabelColour:)) {
		
		// can right mouse in tableview on unselected cell.
		// so make sure to get the correct cell
		MGSScript *script = [self clickedScript];	
		if (!script) return NO;
		[(FVColorMenuView *)[anItem view] selectLabel:script.labelIndex];
		return YES;
	}

	// change task rating index
    if (action == @selector(changeTaskRatingIndex:)) {
		
		// can right mouse in tableview on unselected cell.
		// so make sure to get the correct cell
		MGSScript *script = [self clickedScript];	
		if (!script) return NO;
		[anItem setState: (script.ratingIndex == [anItem tag]) ? NSOnState : NSOffState];
		
		return YES;
	}
	
	return YES;
}

#pragma mark -
#pragma mark View handling
/*
 
 min view height
 
 */
- (CGFloat)minViewHeight
{
	return ([actionTable rowHeight] + [actionTable intercellSpacing].height) * 3 + [[actionTable headerView] frame].size.height;
}

#pragma mark -
#pragma mark Timer callbacks
/*
 
 startup timer has expired
 
 */
- (void)startupTimerExpired:(NSTimer*)theTimer
{	
	#pragma unused(theTimer)
	
	[_startupTimer invalidate];
	_startupTimer = nil;
		
	if (_delegate && [_delegate respondsToSelector:@selector(browserStartupTimerExpired:)]) {
		[_delegate browserStartupTimerExpired:self];
	}
	
	// start the licence manager timer
	if (!_LMTimer) {
		_LMTimer = [NSTimer scheduledTimerWithTimeInterval:LMTestInterval target:self selector:@selector(LMTimerExpired:) userInfo:nil repeats:YES];
	}
	
	[self retrievePreferences];
}

/*
 
 licence manager timer has expired
 
 */
- (void)LMTimerExpired:(NSTimer*)theTimer
{	
	#pragma unused(theTimer)
	
	MGSLM *licenceManager = [MGSLM sharedController];
	if (!licenceManager) {
		goto errorExit;
	}
	
	NSInteger licenceMode = [licenceManager mode];
	switch (licenceMode) {
		case MGSValidLicenceMode:
			break;
						
		case MGSInvalidLicenceMode:
		default:
			goto errorExit;
	}
	
	return;
	
errorExit:;
	NSRunAlertPanel(@"Invalid or missing licence file.",@"KosmicTask will terminate.",@"OK",nil,nil);
	[NSApp terminate:nil];
}

#pragma mark -
#pragma mark MGSNetClient handling

/*
 
 currently selected client
 
 */
- (MGSNetClient *)selectedClient
{
	NSInteger machineRowIndex = [machineTable selectedRow];
	if (machineRowIndex == -1) return nil;
	
	return [_netClientHandler clientAtIndex:machineRowIndex];
}

#pragma mark -
#pragma mark NSTableView handling
/*
 
 table view check box cell clicked
 sender is the tableview
 
 */
- (void)handleTableCheckClick: (id) sender 
{
	// sanity check
	if (![sender isKindOfClass:[NSTableView class]]) {
		return;
	}	
	
	// performing the click processing immediately causes selection problems when
	// check cell in row that is not the selected row.
	// so allow normal row selection processing to occur before we process our check click
	[self performSelector:@selector(tableViewCheckClick:) withObject:sender afterDelay:0.0];
}

/*
 
 table view single click
 
 */
/*
 - (void)tableViewSingleClick:(id)aTableView
 {
 // group table
 if (aTableView == groupTable) {
 }
 }
 */
/*
 
 table view double click
 
 */
- (void)tableViewDoubleClick:(id)aTableView
{
	MGSNetClient *netClient = [self selectedClient];
	
	// clicked row
	NSInteger rowIndex = [aTableView clickedRow];
	
	// clicked column
	NSInteger columnIndex = [aTableView clickedColumn];
	NSTableColumn *tableColumn = (columnIndex != -1) ? [[aTableView tableColumns] objectAtIndex:columnIndex] : nil;
	
	if (aTableView == actionTable) {
		
		// this message also sent if double click column header
		// so check that a row was clicked
		if (rowIndex != -1) {
			
			switch ([[netClient applicationWindowContext] runMode]) {
					
				case kMGSMotherRunModePublic:
				case kMGSMotherRunModeAuthenticatedUser:
					// perhaps too easy to fire off an action unintentionally.
					return;
					// call delegate with new action
					if (_delegate && [_delegate respondsToSelector:@selector(browserExecuteSelectedAction:)]) {
						[_delegate browserExecuteSelectedAction:self];
					}						
					break;
					
				case kMGSMotherRunModeConfigure:
					
					if (tableColumn) {
						
						// post edit selected action.
						// don't send if double clickpublish checkbox as this too easily results in uneanted edit requests
						if (![[tableColumn identifier] isEqual:MGSTableColumnIdentifierPublishCheckbox]) {
							[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteEditSelectedTask object:nil userInfo:nil];
						}
					}
					break;
					
			}
			
		}
	}
	
	else if (aTableView == groupTable) {
	}
}

#pragma mark -
#pragma mark Preference handling
/*
 
 save browser preferences
 
 */
- (void)savePreferences
{
}

/*
 
 retrieve browser preferences
 
 */
- (void)retrievePreferences
{
	// get persistent clients
	[_netClientHandler performSelector:@selector(restorePersistentClients) withObject:nil afterDelay:0];
}

#pragma mark -
#pragma mark Task handling

/*
 
 select group icon
 
 */
- (IBAction)selectGroupIcon:(id)sender
{
	#pragma unused(sender)
	
	if (!_imageCollectionWindowController) {
		
		// load window
		[NSBundle loadNibNamed:@"ImageCollectionWindow" owner:self];
		[_imageCollectionWindowController window];	// load window

	}
	[_imageCollectionWindowController showWindow:self];
	
	[self groupSelected];
}

/*
 
 change task label colour
 
 */
- (IBAction)changeTaskLabelColour:(id)sender
{
	// Sender tag corresponds to the Finder label integer
    NSInteger label = [sender tag];
    NSAssert1(label >=0 && label <= 7, @"invalid label %d (must be between 0 and 7)", label);
    
    // we have to close the menu manually; FVColorMenuCell returns its control view's menu item
    if ([sender respondsToSelector:@selector(enclosingMenuItem)] && [[[sender enclosingMenuItem] menu] respondsToSelector:@selector(cancelTracking)])
        [[[sender enclosingMenuItem] menu] cancelTracking];
	
	// set script label index
	MGSScript *script = [self clickedScript];	
	script.labelIndex = label;
}
/*
 
 change task rating index
 
 */
- (IBAction)changeTaskRatingIndex:(id)sender
{
	// Sender tag corresponds to the rating
    NSInteger rating = [sender tag];
    NSAssert1(rating >=0 && rating <= 5, @"invalid label %d (must be between 0 and 5)", rating);
    
	// set script rating index
	MGSScript *script = [self clickedScript];	
	script.ratingIndex = rating;
}
/*
 
 open task in new tab
 
 */
- (IBAction)openTaskInNewTab:(id)sender
{
	#pragma unused(sender)
	
	[self dispatchTaskSpecAtRowIndex:[actionTable clickedRow] displayType:MGSTaskDisplayInNewTab];	
}
/*
 
 open task in new window
 
 */
- (IBAction)openTaskInNewWindow:(id)sender
{
	#pragma unused(sender)
	[self dispatchTaskSpecAtRowIndex:[actionTable clickedRow] displayType:MGSTaskDisplayInNewWindow];	
}


//==================================================================
//
// show the path to the action
//
// this will be sent when the action is selected by say clicking
// on one of the tabview tab items.
// as such it is not neccessaey to inform our delegate
// of a selection change.
//==================================================================
- (void)showPathToAction:(MGSTaskSpecifier *)action
{
	
	@try {
		
		// if action has nil script then it action represents situation were there are no valid tasks
		if (!action.script) {
			return;
		}

		// do not wish to dispatch an action as the tables are updated
		_allowActionDispatch = NO;
		
		NSString *machineName = [action.netClient serviceShortName];
		NSString *actionUUID = [action.script UUID];
		NSString *groupName = [action.script group];

		NSAssert(machineName, @"machine name is nil");
		NSAssert(actionUUID, @"action UUID is nil");
		NSAssert(groupName, @"group name is nil");

		NSInteger idx;
		
		// select action machine if required
		if (NO == [machineName isEqualToString:[[self selectedClient] serviceShortName]]) {

			// get the machine name table index
			idx = [self searchTableView:machineTable columnIdentifier:MGSTableColumnIdentifierMachine rowForValue:machineName searchKey:nil];
			if (idx == -1) {
				MLog(DEBUGLOG, @"bowser machine name not found");
				return;
			}
			
			// selectRowIndexes:byExtendingSelection: can raise exception if index out of range
			[machineTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
			[machineTable scrollRowToVisible:idx];
		}

		// try and get action match within current group
		idx = [self searchTableView:actionTable columnIdentifier:MGSTableColumnIdentifierUUID rowForValue:actionUUID  searchKey:nil];	
		if (idx != -1) {
			[actionTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
			[actionTable scrollRowToVisible:idx];
		} else {
			// get the group index
			idx = [self searchTableView:groupTable columnIdentifier:MGSTableColumnIdentifierName rowForValue:groupName  searchKey:MGSImageAndTextValueKey];	
			if (idx == -1) {
				MLog(DEBUGLOG, @"bowser group name not found");
				
				// if the action is in a displayed user tab and public mode has been reverted to
				// then we may not find the action in the table view.
				// in this case deselect the group and action tableviews.
				// NO. if deselect it is difficult to restore the group correctly
				//[self setDeselectGroupAndActionTableViews:YES];
				return;
			}	
			[groupTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
			[groupTable scrollRowToVisible:idx];
			
			// get the action index
			idx = [self searchTableView:actionTable columnIdentifier:MGSTableColumnIdentifierUUID rowForValue:actionUUID  searchKey:nil];	
			if (idx == -1) {
				MLog(DEBUGLOG, @"bowser action UUID not found");
				//[self setDeselectGroupAndActionTableViews:YES];
				return;
			}	
			[actionTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
			[actionTable scrollRowToVisible:idx];
		}
	} 
	@catch(NSException *e) {
		MLog(DEBUGLOG, @"exception name :%@ description :%@", [e name], [e description]);
	}
	@finally {
		_allowActionDispatch = YES;
	}

}

/*
 
 delete selected action
 
 */
- (void)deleteSelectedAction
{
	// get selected script
	MGSScript *script = [self selectedScript];
	MGSNetClient *netClient = [self selectedClient];

	// schedule deletion of script from the manager.
	// deletion will only occur when the current configuration is saved.
	[[netClient.taskController scriptManager] scheduleDeleteScript:script];

	[self reloadGroupTableData];

	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
									 [script UUID], MGSNoteClientScriptUUIDKey,
									 nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteScriptScheduledForDelete object:netClient userInfo:userInfo];

	
}

/*
 
 - setSelectedActionSchedulePublished:
 
 */
- (void)setSelectedActionSchedulePublished:(BOOL)aBool
{
	MGSScript *script = [self selectedScript];
	
	[script setSchedulePublished:aBool];
	
	[self reloadGroupTableData];
	
}

#pragma mark -
#pragma mark - NSSplitView delegate

/*
 
 size splitview subviews as required
 
 */
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize
{	
	MGSSplitviewBehaviour behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;
	
	// note that a view does not provide a -setTag method only -tag
	// so views cannot be easily tagged without subclassing.
	// NSControl implements -setTag;
	//
	if ([sender isEqual:splitView]) {
		switch ([[splitView subviews] count]) {
			case 2:
				behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;
				break;
				
			case 3:
				behaviour = MGSSplitviewBehaviourOf3ViewsFirstAndSecondFixed;
				break;
				
			default:
				NSAssert(NO, @"invalid number of views in splitview");
				return;
		}
	} else {
		NSAssert(NO, @"invalid splitview");
	}
	
	// see the NSSplitView_Mugginsoft category
	[sender resizeSubviewsWithOldSize:oldSize withBehaviour:behaviour];
}

/*
 
 get additional rect to be used to drag splitview
 
 */
- (NSRect)splitView:(NSSplitView *)aSplitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
	NSView *subView = [[aSplitView subviews] objectAtIndex:dividerIndex];
	
	NSRect rect = [subView bounds];
	rect.origin.x = rect.size.width -15;
	rect.origin.y = rect.size.height -15;
	rect.size.height = 15;
	rect.size.width = 15;

	// rect must be in splitview co-ords
	return [aSplitView convertRect:rect fromView:subView];
}

/*
 
 splitview constrain max position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	switch ([[splitView subviews] count]) {
		case 2:
			proposedMax = [sender frame].size.width - [self actionTableMinWidth];
			break;
		
		case 3:
			switch (offset) {
				case 0:
					proposedMax = [sender frame].size.width - [self groupTableMinWidth] - [[[sender subviews] objectAtIndex:2] frame].size.width;
					break;
				case 1:
					proposedMax = [sender frame].size.width - [self actionTableMinWidth];
					break;
				default:
					NSAssert(NO, @"invalid index");
					break;
			}
			break;
			
		default:
			NSAssert(NO, @"invalid splitview count");
			break;
	}
	return proposedMax;
}

/*
 
 splitview constrain min position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	switch ([[splitView subviews] count]) {
		case 2:
			proposedMin = [self groupTableMinWidth];
			break;
			
		case 3:
			switch (offset) {
				case 0:
					proposedMin = [self machineTableMinWidth];
					break;
				case 1:
					proposedMin = [[[sender subviews] objectAtIndex:0] frame].size.width + [sender dividerThickness] + [self groupTableMinWidth];
					break;
				default:
					NSAssert(NO, @"invalid index");
					break;
			}
			break;
			
		default:
			NSAssert(NO, @"invalid splitview count");
			break;
	}
	
	return proposedMin;
}

#pragma mark -
#pragma mark MGSClientRequestManager delegate category

/*
 
 net request response payload
 
 */
-(void)netRequestResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	NSString *requestCommand = netRequest.kosmicTaskCommand;
	
	// validate response
	if (NSOrderedSame != [requestCommand caseInsensitiveCompare:MGSScriptCommandListAll] && 
		NSOrderedSame != [requestCommand caseInsensitiveCompare:MGSScriptCommandListPublished]) {
		[MGSError clientCode:MGSErrorCodeInvalidCommandReply];
		return;
	}

	// check for errors
	if (payload.requestError) {
		
		// an error that arrives here may or may not have been logged.
		// make sure that we log it here otherwise it disappears.
		// in particular a corrupt request may deposit a failed authentication
		// error here which will otherwise remain unlogged.
		[payload.requestError log];
		
		return;
	}
	
	MGSNetClient *netClient = netRequest.netClient;
	
	// save the script dict to the netClient 
	NSMutableDictionary *scriptDict = [NSMutableDictionary dictionaryWithDictionary:payload.dictionary];
	if ([requestCommand isEqualToString:MGSScriptCommandListAll]) {
		[netClient.taskController setTrustedScriptDictionary:scriptDict];	// trusted user script dict
	} else if ([requestCommand isEqualToString:MGSScriptCommandListPublished]) {
		[netClient.taskController setPublicScriptDictionary:scriptDict];	// public script dict
	} else {
		[MGSError clientCode:MGSErrorCodeInvalidCommandReply];
	}
	
	// if a manual client has been added then its status may have been at
	// unavailable. update status is required.
	if (netClient.hostStatus != MGSHostStatusAvailable) {
		[netClient setHostStatus: MGSHostStatusAvailable];	
	}

	// show the new script dictionary if it matches the currently selected client
	if ([netClient isEqualTo:[self selectedClient]]) {
		[self reloadGroupTableData];
	}
	
	// tell delegate that a valid client has become available
	// and that its dictionary has been received.
	if (netClient.clientStatus == MGSClientStatusNotAvailable) {
		
		// a user client may exist within the browser in a disconnected state.
		// the sidebar will only display the client when it becomes available.
		// the delegate is only informed of availability once, even if subsequent requests
		// for the script dict are issued
		if (_delegate && [_delegate respondsToSelector:@selector(browser:clientAvailable:)]) {
			[_delegate browser:self clientAvailable:netClient];
		}
		
		netClient.clientStatus = MGSClientStatusAvailable;
	}

	// look for local host coming up
	if ([netClient hostType] == MGSHostTypeLocal) {
		
		// if the startup timer has not expired then select the
		// local client and expire the timer.
		// note that the local client may not be the first client found (though it should be as we now defer remote connections).
		// already initialised network hosts may respond first.
		
		if (_startupTimer) {

			// select the local client
			NSString *machineName = [netClient serviceShortName];
			NSInteger idx = [self searchTableView:machineTable columnIdentifier:MGSTableColumnIdentifierMachine rowForValue:machineName  searchKey:nil];
			if (idx > -1) {
				[machineTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
				[machineTable scrollRowToVisible:idx];
			}
			
			[self startupTimerExpired:_startupTimer];
		}
	}

	
	// if have received dict for currently selected client then send out
	// a client selected notification.
	// the sidebar only adds clients to its outline on receipt of MGSNoteNetClientAvailable.
	// the upshot of this is that the first item added to the sidebar remains unselected.
	// this notification will confirm the selection to the sidebar
	if ([netClient isEqualTo:[self selectedClient]]) {
		[self sendClientSelectedNotification:MGSNoteClientSelected options:nil];
	}
	
	// if we have retrieved the local host data okay then we no longer need to
	// defer remote connections
	if ([netClient isLocalHost]) {
		[[MGSNetClientManager sharedController] setDeferRemoteClientConnections:NO];
	}
}

#pragma mark -
#pragma mark NSNotificationCenter callbacks

/*
 
 application run mode has changed for the current net client
 
 */
- (void)appRunModeChanged:(NSNotification *)notification
{
	if ([notification object] == self) {
		return;
	}
	
    NSNumber *mode = [[notification userInfo] objectForKey:MGSNoteModeKey];
	
	// Hmmm. We may have the client open in another window.
	// in that case the client run mode may be different.
	[self setClientRunMode:[mode intValue]];
}

/*
 
 suggest exit edit mode
 
 */
- (void)suggestExitEditMode:(NSNotification *)notification
{
	#pragma unused(notification)
	
	//[self promptToExitEditMode];	// try allowing permissive editing oy any client
}

/*
 
 action view mode has changed
 
 */
- (void)viewConfigChangeRequest:(NSNotification *)notification
{ 
    NSNumber *viewMode = [[notification userInfo] objectForKey:MGSNoteViewConfigKey];
	int mode = [viewMode intValue];
	
	// get view state
	eMGSViewState viewState = kMGSViewStateToggleVisibility;
	NSNumber *number = [[notification userInfo] objectForKey:MGSNoteViewStateKey];
	if (number) {
		viewState = [number integerValue];
	}
	
	switch (mode) {
			
		/*
		 
		 toggle the group list visibility
		 
		 */
		case kMGSMotherViewConfigGroupList:;
			NSView *taskView = [[splitView subviews] objectAtIndex:1];
			NSView *parentView = [_browserView superview];
			
			switch (viewState) {
				case kMGSViewStateShow:
					if (_browserView != splitView) {
						[parentView replaceSubview:_browserView withViewFrameAsOld:splitView];
						[splitView replaceSubview:taskView withViewFrameAsOld:_browserView];
						_browserView = splitView;
					}
					break;
					
				case kMGSViewStateHide:;
					if (_browserView == splitView) {
						NSView *placeHolderView = [[NSView alloc] initWithFrame:[taskView frame]];
						[splitView replaceSubview:taskView withViewFrameAsOld:placeHolderView];
						[parentView replaceSubview:_browserView withViewFrameAsOld:taskView];
						_browserView = taskView;
					}
					break;
					
				default:
					return;
			}	
			
			[[NSUserDefaults standardUserDefaults] setBool:(viewState == kMGSViewStateShow ? YES : NO) forKey:MGSMainGroupListVisible];
			
			break;
			
		default:
			return;
	}
	
	// send out completed change notification.
	NSNotification *noteDone = [NSNotification notificationWithName:MGSNoteViewConfigDidChange 
															 object:[[self view] window]
														   userInfo:[notification userInfo]];
	[[NSNotificationCenter defaultCenter] postNotification:noteDone];
	
	
}

/*
 
 - netClientSelected:
 
 */
- (void)netClientSelected:(NSNotification *)notification
{
	// we have receieved a netclient selection notification
	// so don't post anotehr when we change our selection
	_postNetClientSelectionNotifications = NO;
	
	NSDictionary *userInfo = [notification userInfo];
	NSString *clientName = [userInfo objectForKey:MGSNoteClientNameKey];
	NSAssert(clientName, @"client name is nil");

	MGSNetClient *netClient = [userInfo objectForKey:MGSNoteNetClientKey];

	// ignore if we sent the notification
	if ([notification object] != self) {
	
		// select the client in the machine table
		NSInteger idx = [self searchTableView:machineTable columnIdentifier:MGSTableColumnIdentifierMachine rowForValue:clientName  searchKey:nil];
		if (idx == -1) {
			MLog(DEBUGLOG, @"browser machine name not found");
			return;
		}
		
		// selectRowIndexes:byExtendingSelection: can raise exception if index out of range
		[machineTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
		[machineTable scrollRowToVisible:idx];

		// select the group in the group table if defined
		id group = [userInfo objectForKey:MGSNoteClientGroupKey];
		if (group) {
			[self netClientItemSelected:notification];
		}
		
	}
	
	// browser run mode must match client
	[self setClientRunMode:netClient.applicationWindowContext.runMode];
	
	_postNetClientSelectionNotifications = YES;
	
}

/*
 
 - netClientItemSelected:
 
 */
- (void)netClientItemSelected:(NSNotification *)notification
{
	BOOL previousNotifificationState = _postNetClientSelectionNotifications;
	_postNetClientSelectionNotifications = NO;
	
	/*
	 
	 item selected for current net client
	 
	 */
	NSDictionary *userInfo = [notification userInfo];
	NSInteger idx = -1;
	
	// ignore if we sent the notification
	if ([notification object] != self) {
		
		// item key defines what type of of selection was made
		NSString *itemKey = [userInfo objectForKey:MGSNoteClientItemKey];
		
		// a group or script was selected
		if ([itemKey isEqualToString:MGSNoteClientGroupKey] || 
			[itemKey isEqualToString:MGSNoteClientScriptKey]) {
			
			// select the group in the group table
			NSString *groupName = [userInfo objectForKey:MGSNoteClientGroupKey];
			NSAssert(groupName, @"group name is missing");
			
			// an empty group name indicates the all group
			if ([groupName isEqualToString:@""] || [groupName isEqualToString:[MGSClientScriptManager groupNameAll]]) {
				idx = 0;
			} else {
				idx = [self searchTableView:groupTable columnIdentifier:MGSTableColumnIdentifierName rowForValue:groupName searchKey:@"value"];
				if (idx == -1) {
					MLog(DEBUGLOG, @"group name not found");
					goto errorExit;
				}
			}
			
			// selectRowIndexes:byExtendingSelection: can raise exception if index out of range
			[groupTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
			[groupTable scrollRowToVisible:idx];
			
			// look for a script to select
			MGSScript *script = [userInfo objectForKey:MGSNoteClientScriptKey];
			if (script) {
				
				// search for index of action UUID
				idx = [self searchTableView:actionTable columnIdentifier:MGSTableColumnIdentifierUUID rowForValue:[script UUID] searchKey:nil];	
				
				// if our action is no longer available we default to the first
				if (idx == -1) {
					idx = 0;
				}	
				
				// select our row
				if ([actionTable numberOfRows] > 0) {
					[actionTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];	
					[actionTable scrollRowToVisible:idx];
				}
			}
		}
		
	}
	
errorExit:
	
	_postNetClientSelectionNotifications = previousNotifificationState;
}
/*
 
 group icon window item selected
 
 */
- (void)groupIconWindowItemSelected:(NSNotification *)notification
{
	NSDictionary *userDict = [notification userInfo];
	NSString *imageName = [userDict objectForKey:MGSNoteValueKey];
	NSString *location = [userDict objectForKey:MGSNoteLocationKey];
	
	// resource icon selected
	if ([location caseInsensitiveCompare:MGSResourceGroupIcons] == NSOrderedSame) {
		
		MGSNetClient *netClient = [self selectedClient];
		[netClient.taskController setImageNameForActiveGroup:imageName location:location];
		
		// reload selected row only
		[groupTable reloadDataForSelectedRow];
	}
}
/*
 
 refresh action
 
 */
- (void)refreshAction:(NSNotification *)notification
{
	id object = [notification object];
	if (!object) return;
	
	// verify that object has required accessors
	if ([object respondsToSelector:@selector(actionSpecifier)] && 
		[object respondsToSelector:@selector(setActionSpecifier:)]) {
		
		// get new action instance
		MGSTaskSpecifier *objectAction = [object actionSpecifier];
		MGSTaskSpecifier *newAction = [self actionCopyWithUUID:[objectAction UUID]];
		
		// if new action valid then set it
		if (newAction) {
			[object setActionSpecifier:newAction];
		}
	}
}

@end

#pragma mark -
#pragma mark MGSNetClient/MGSNetClientManager delegate category

#pragma mark -
@implementation MGSBrowserViewController (netClientHandlerDelegate)

/*
 
 - netClientScriptDictUpdated
 
 */
- (void)netClientScriptDictUpdated:(MGSNetClient *)netClient
{
	// net client script dict has been updated
	// probably because a manual client has disconnected
	// and is dict is no longer valid
	if ([self selectedClient] == netClient) {
		[self reloadGroupTableData];
	}
}

/*
 
 - netClientScriptDataUpdated
 
 */
- (void)netClientScriptDataUpdated:(MGSNetClient *)netClient
{
	// net client script data has been updated
	// probably as the result of a script edit
	if ([self selectedClient] == netClient) {
		[self reloadGroupTableData];
	}
	
}

// client TXT record updated.
// this includes the username and the server SSL state.
// if the server SSL state changes this needs to be reflected in the table
- (void)netClientTXTRecordUpdated:(MGSNetClient *)netClient
{
	#pragma unused(netClient)
	
	[self reloadMachineTableData];
}

// authentication status has changed for client
- (void)netClientAuthenticationStatusChanged:(MGSNetClient *)netClient
{
	#pragma unused(netClient)
	
	[self reloadMachineTableData];
}

// client was not responding or connected but is now responding
- (void)netClientResponding:(MGSNetClient *)netClient
{
	// if client now responding but has no scripts then
	// try and retrieve them
	if (NO == [netClient.taskController hasScripts]) {
		[[MGSClientRequestManager sharedController] requestScriptDictForNetClient:netClient isPublished:YES withOwner:self];
	}

}

/*
 
 client list changed

 called when clients either added or removed
 
 */
-(void)netClientHandlerClientListChanged:(MGSNetClientManager *)sender
{
	#pragma unused(sender)
	
	[self clientListChanged:nil];
}

/*
 
 net client found
 
 */
-(void)netClientHandlerClientFound:(MGSNetClient *)netClient
{
	// check if bonjour host has disconnected
	if ([netClient hostViaBonjour]) {
		
		// the netservice may have disconnected
		if (!netClient.netService) {
			return;
		}
	}
	
	// check that we can connect. for Bonjour resolved hosts
	// a valid connection cannot be attempted until we recieve a TXTrecord stating the SSL mode
	if ([netClient canConnect]) {
		
		[self addClientObservations:netClient];

		// flag host as available
		[netClient setHostStatus:MGSHostStatusAvailable];
		
		// get script dict for client
		if (NO == [netClient.taskController hasScripts]) {
			[[MGSClientRequestManager sharedController] requestScriptDictForNetClient:netClient isPublished:YES withOwner:self];
		}
	} else {
		
		if ([netClient hostViaBonjour]) {
			// retry - allow time for the TXTRecord to be received
			if (++netClient.initialRequestRetryCount < 10) {
				MLog(RELEASELOG, @"%@ : service available but cannot yet connect. Retrying (%d)...", netClient.serviceShortName, netClient.initialRequestRetryCount);
				[self performSelector:_cmd withObject:netClient afterDelay:2.0];
			} else {
				NSString *reason = [NSString stringWithFormat:@"%@ : Maximum retries exceeded trying to sending initial request.", netClient.serviceShortName];
				[MGSError clientCode:MGSErrorCodeCannotConnectToService reason:reason log:YES];
			}
		}
	}
}

/*
 
 net client removed
 
 */
-(void)netClientHandlerClientRemoved:(MGSNetClient *)netClient
{
	//[self updateStatusBarCaption];
	[self removeClientObservations:netClient];

	// tell delegate that a valid client has become unavailable
	if (_delegate && [_delegate respondsToSelector:@selector(browser:clientUnvailable:)]) {
		[_delegate browser:self clientUnvailable:netClient];
	}
}


@end

#pragma mark -
#pragma mark Private category

@implementation MGSBrowserViewController (Private)

#pragma mark -
#pragma mark Action handling
/*
 
 get action copy at row index
 
 */
- (MGSTaskSpecifier *)actionCopyAtRowIndex:(NSInteger)rowIndex 
{
	
	MGSNetClient *netClient = [self selectedClient];
	NSAssert(netClient, @"net client is nil");
	
	MGSClientScriptManager *scriptController = [netClient.taskController scriptManager];
	NSAssert(scriptController, @"script controller is nil");
	
	// if no actions available then action will contain a nil script
	MGSScript *script = nil;
	int scriptIndex = -1;
	if ([actionTable numberOfRows] > 0) {
		scriptIndex = rowIndex;
		if (scriptIndex > -1) {
			script = [scriptController groupScriptAtIndex: scriptIndex];
		}
	}
	
	// create a task specifier
	MGSTaskSpecifier *taskSpec = [[MGSTaskSpecifierManager sharedController] newObject];
	taskSpec.netClient = netClient;
	taskSpec.scriptIndex = scriptIndex;
	if (script) {
		taskSpec.script = [script mutableDeepCopy];
	} 
	return taskSpec;
}

/*
 
 get action copy at row index
 
 */
- (MGSTaskSpecifier *)actionCopyWithUUID:(NSString *)UUID 
{
	
	MGSNetClient *netClient = [self selectedClient];
	NSAssert(netClient, @"net client is nil");
	
	MGSClientScriptManager *scriptController = [netClient.taskController scriptManager];
	NSAssert(scriptController, @"script controller is nil");
	
	// if no actions available then action will contain a nil script
	int scriptIndex = -1;
	MGSScript *script = [scriptController scriptForUUID:UUID];
	if (!script) return nil;
	
	// create an action specifier
	MGSTaskSpecifier *action = [[MGSTaskSpecifierManager sharedController] newObject];
	action.netClient = netClient;
	action.scriptIndex = scriptIndex;
	action.script = [script mutableDeepCopy];
	
	return action;
}

/*
 
 set deselect group and action table views
 
 */
- (void)setDeselectGroupAndActionTableViews:(BOOL)deselect
{
	if (deselect) {
		[actionTable setAllowsEmptySelection:YES];
		[actionTable deselectAll:self];
		[groupTable setAllowsEmptySelection:YES];
		[groupTable deselectAll:self];
	} else {
	}
	
}
/*
 
 group selected
 
 */
- (void)groupSelected
{
	
	MGSNetClient *netClient  = [self selectedClient];
	if (!netClient) return;
	
	// send group icon selected notification
	MGSScriptManager *scriptManager = [[netClient.taskController scriptManager] activeGroup];
	
	// send group icon selection notification
	// if image collection window allocated and winodw is visible
	if (_imageCollectionWindowController) {
		
		// send if window visible
		if ([[_imageCollectionWindowController window] isVisible]) {
			NSString *name = nil, *location = nil;
			[[netClient.taskController scriptManager] imageResourceForGroup:scriptManager name:&name location:&location];
			if (name && location) {
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: name, MGSNoteValueKey, location, MGSNoteLocationKey, nil];
				[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteGroupIconSelected object:[[self view] window] userInfo:userInfo];
			}
		}
	}
	
	// get the group name.
	// if the all scripts group is selected we send an empty string
	NSString *groupName = [scriptManager name];
	if (scriptManager.hasAllScripts) {
		//groupName = @"";
	}
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 MGSNoteClientGroupKey, MGSNoteClientItemKey,
							  groupName, MGSNoteClientGroupKey,
							  nil];
	[self sendClientSelectedNotification:MGSNoteClientItemSelected options:options];
	
}

/*
 
 - clientListChanged:
 
 */
- (void)clientListChanged:(MGSNetClient *)netClient
{
#pragma unused(netClient)

	// called when clients either added or removed
	// when a new client is detected this message is sent before all others.

	// sort the machine table.
	// this will display the new client in its sorted position
	[self tableView:machineTable sortDescriptorsDidChange:nil];	
	[self reloadGroupTableData];
}



// get store for client
- (NSMutableDictionary *)clientStore:(MGSNetClient *)netClient
{
	NSMutableDictionary *clientDict = [_clientStore objectForKey:[netClient serviceName]];
	if (!clientDict) {
		clientDict = [NSMutableDictionary dictionaryWithCapacity:2];
	}
	return clientDict;
}

// set object in store for client
- (void)setObject:(id)object forClientStore:(MGSNetClient *)netClient
{
	[_clientStore setObject:object forKey:[netClient serviceName]];
}


// start delay interval
- (NSTimeInterval)startDelay
{
	NSTimeInterval startDelay = [[NSUserDefaults standardUserDefaults] doubleForKey:MGSDefaultStartDelay];
	if (startDelay <= 0) startDelay = 1.0;
	return startDelay;
}

/*
 
 - sendClientSelectedNotification:options:
 
 */
- (void)sendClientSelectedNotification:(NSString *)noteName options:(NSDictionary *)options
{
	if (!_postNetClientSelectionNotifications) {
		return;
	}
	
	// post client selected notification
	MGSNetClient *netClient  = [self selectedClient];
	if (!netClient) {
		MLog(DEBUGLOG, @"net client is nil");
		return;
	}
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[netClient serviceShortName], MGSNoteClientNameKey, 
							  netClient, MGSNoteNetClientKey, nil];
	if (options) {
		[userInfo addEntriesFromDictionary:options];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:noteName object:self userInfo:userInfo];
	
}

#pragma mark -
#pragma mark KVO
// observe client
// not a lot of observing is occuring at present.
// there seems to be a lot of manual table refreshing.
// try and improve on this.
- (void)addClientObservations:(MGSNetClient *)netClient
{
	// observe the host status
	[netClient addObserver:self forKeyPath:MGSNetClientKeyPathHostStatus options:NSKeyValueObservingOptionNew context:0];
	
}


/*
 
 remove client observations
 
 */
- (void)removeClientObservations:(MGSNetClient *)netClient
{
	if (!netClient) {
		MLog(DEBUGLOG, @"net client is nil");
		return;
	}
	
	// observe the host status
	@try {
		[netClient removeObserver:self forKeyPath:MGSNetClientKeyPathHostStatus];
	} 
	@catch (NSException *e) {
		MLog(RELEASELOG, @"%@", [e reason]);
	}
}

/*
 
 observe value for key path 
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(change)
	#pragma unused(context)
	// net client
	if ([object isKindOfClass:[MGSNetClient class]]) {
		
		MGSNetClient *netClient = object;
		
		// host status
		if ([keyPath isEqualToString:MGSNetClientKeyPathHostStatus]) {
			[self reloadMachineTableData];	
			
			// if client added manually and is now disconnected then message delegate
			if (NO == netClient.hostViaBonjour && netClient.hostStatus == MGSHostStatusNotYetAvailable) {
				
				// tell delegate that a valid client has become unavailable
				if (_delegate && [_delegate respondsToSelector:@selector(browser:clientUnvailable:)]) {
					[_delegate browser:self clientUnvailable:netClient];
				}
			}
		}
	
	}
}

#pragma mark -
#pragma mark MGSScript handling
/*
 
 selected script
 
 */
- (MGSScript *)selectedScript
{
	return [self scriptAtRow:[actionTable selectedRow]];
}
/*
 
 clicked script
 
 script for clicked table view row.
 useful when looking for right click which does not change selected row
 
 */
- (MGSScript *)clickedScript
{
	return [self scriptAtRow:[actionTable clickedRow]];
}
/*
 
 script at row
 
 */
- (MGSScript *)scriptAtRow:(NSInteger)rowIndex
{
	if (rowIndex == -1) return nil;

	// set script label index
	MGSNetClient *netClient = [self selectedClient];
	MGSScript *script = [[netClient.taskController scriptManager] groupScriptAtIndex:rowIndex];	
	
	return script;
}

#pragma mark -
#pragma mark NSTableView handling
/*
 
 table view check click
 
 */
- (void)tableViewCheckClick: (NSTableView *)tableView 
{
	
	
	// cicking the checkbox will select the row
	int rowIndex = [tableView selectedRow];
	MGSNetClient *netClient = [self selectedClient];
	
	
	// action table
	if (tableView == actionTable) {
		
		// toggle the published state
		MGSScript *script = [[netClient.taskController scriptManager] groupScriptAtIndex:rowIndex];
		
		[script setSchedulePublished:![script published]];			// schedule for publish
		
	} else if (tableView == groupTable) {
		
		// group table
		MGSScriptManager *scriptManager = [[netClient.taskController scriptManager] groupAtIndex:rowIndex];
		NSCellStateValue published = [scriptManager publishedCellState];
		
		// cycle the published state
		// this represented by a mixed state checkbox
		if (published == NSOnState || published == NSMixedState) {
			published = NO;
		} else {
			published = YES;
		}	
		
		// change published state of all scripts in the group
		[scriptManager setSchedulePublished:published];
	}
	
	// our changes may affect both the group and action tables.
	// ie: changing the publication state of an action changes the displayed publication state of its group
	[self reloadGroupTableData];
}



/*
 
 search table view column for value
 
 note that the sorted data source could be searched directly but this seems convenient
 
 */
- (NSInteger)searchTableView:(NSTableView *)aTableView columnIdentifier:(NSString *)column rowForValue:(id)value searchKey:(NSString *)searchKey
{
	int i;
	NSTableColumn *aTableColumn = [aTableView tableColumnWithIdentifier:column];
	
	NSAssert(aTableColumn, @"table column is nil");

	SEL keySelector = (SEL)0;
	if (searchKey) {
		keySelector = NSSelectorFromString(searchKey);
	}
	
	for (i = 0; i < [aTableView numberOfRows]; i++) {
		
		// get our table cell object.
		// in cases where cell is not say of type NSString then the key value can be used to
		// extract required key value
		id cellObject = [self tableView:aTableView objectValueForTableColumn:aTableColumn row:i];
		
		// if key selector defined and cell responds to it use its value
		if (keySelector != (SEL)0) {
			if ([cellObject respondsToSelector:keySelector]) {
				cellObject = [cellObject performSelector:keySelector];
			}
		}
		// compare
		if ([value isEqualTo:cellObject]) {
			return i;
		}
	}
	return -1;
}


/*
 
 sort table view and reload data
 
 note that this method does not try to maintain selection
 
 at present we always sort or table on a reload
 we have normally added, removed or otherwise modified an item
 in such a way that it will affect the sort order anyway.
 
 there may be some opportunity to reduce the number of sorts undertaken.
 
 */
- (void)sortTableViewAndReloadData:(NSTableView *)aTableView
{
	// get the sort descriptors for the table and apply
	NSArray *newDescriptors = [aTableView sortDescriptors];
	MGSNetClient *netClient = [self selectedClient];
	MGSClientScriptManager *scriptController = [netClient.taskController scriptManager];
	
	// action table
	if (aTableView == actionTable) {
		
		MGSScriptManager *scriptManager = [scriptController activeGroup];
		[scriptManager sortUsingDescriptors:newDescriptors];
		[actionTable reloadData];	// the selection will be maintained so a solitary table update is okay
		
		// group table
	} else if (aTableView == groupTable) {
		
		[scriptController sortUsingDescriptors:newDescriptors];
		[groupTable reloadData]; // the selection will be maintained so a solitary table update is okay
		
		// machine table
	} else if (aTableView == machineTable) {
		[_netClientHandler sortUsingDescriptors:newDescriptors];
		[machineTable reloadData]; // the selection will be maintained so a solitary table update is okay
	}
	
}

#pragma mark -
#pragma mark DataSource methods
//==========================================================
//
// reload all the browser tables
//
//
//==========================================================
- (void)reloadAllTableData
{
	[self reloadMachineTableData];
	[self reloadGroupTableData];
}
/*
 
 reload machine table data
 
 */
- (void)reloadMachineTableData
{
	// uderlying data does not change here the way it does for the group and action
	// so using currently selected row index to obtain an object seems okay
	
	// rowindex may be -1
	NSInteger rowIndex = [machineTable selectedRow];
	MGSNetClient *client = [_netClientHandler clientAtIndex:rowIndex];	// initial selection
	NSInteger idx = 0;
	
	// sort tableview and reload
	[self sortTableViewAndReloadData:machineTable];
	
	if (client) {
		idx = [_netClientHandler indexOfClient:client];
	}

	if (idx >= 0 && idx < [machineTable numberOfRows]) {
		
		// reselect initial item
		[machineTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
		
		// make selected row visible
		[machineTable scrollRowToVisible:idx];
	}

}
//==========================================================
//
// reload the group table
//
// the client script controller retains the active group
// name. this group is selected.
//==========================================================
- (void)reloadGroupTableData
{
	// note that the underlying data may have changed so that we cannot use the
	// selected row index as a means of determining the prev selected item

	// reselect active group name
	MGSNetClient *netClient = [self selectedClient];
	NSString *groupName = [netClient.taskController activeGroupDisplayName];
	
	// sort tableview and reload
	//
	// at present we always sort or table on a reload
	// we have normally added or removed an item.
	[self sortTableViewAndReloadData:groupTable];

	// because the group table name column contains an MGSImageAndText object we need to define what key to use for our search
	NSInteger idx = [self searchTableView:groupTable columnIdentifier:MGSTableColumnIdentifierName rowForValue:groupName  searchKey:MGSImageAndTextValueKey];	
	
	// if our group is no longer available then we default to the first item
	if (idx == -1) {
		idx = 0;
	}
	
	BOOL reloadActionTableData = NO;
	
	// selecting a new row in the group table will trigger reloading of the action table data.
	// if a new row is not selected then the action data must be reloaded manually
	if ([groupTable numberOfRows] > 0) {
		
		NSInteger prevIndex = [groupTable selectedRow];
		
		// select our row
		[groupTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];	
		[groupTable scrollRowToVisible:idx];
		
		reloadActionTableData = ([groupTable selectedRow] == prevIndex);
	} else {
		reloadActionTableData = YES;
	}
		
	// reload action table data if reqd
	if (reloadActionTableData) {
		[self reloadActionTableData];
	}
	
	// update status bar
	[self updateStatusBarCaption];
}

//==========================================================
//
// reload the action table
//
// the client script controller retains the script UUID.
// the corresponding action is selected.
//==========================================================
- (void)reloadActionTableData
{
	// note that the underlying data may have changed so that we cannot use the
	// selected row index as a means of determining the prev selected item
	// reselect action with matching script UUID
	MGSNetClient *netClient = [self selectedClient];
	NSString *UUID = [netClient.taskController activeScriptUUID];
	
	// sort table view and reload
	[self sortTableViewAndReloadData:actionTable];
		
	// search for index of action UUID
	NSInteger idx = [self searchTableView:actionTable columnIdentifier:MGSTableColumnIdentifierUUID rowForValue:UUID searchKey:nil];	
	
	// if our action is no longer available we default to the first
	if (idx == -1) {
		idx = 0;
	}	
	
	// select our row
	if ([actionTable numberOfRows] > 0) {
		[actionTable selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];	
		[actionTable scrollRowToVisible:idx];
	}

	// action selected
	[self actionSelected];
}

//
// actionSelected
//
// if an action is selected then send it to the request view.
// note that this method will be called whenever the action table is reloaded.
// when this occurs at startup the table will be empty and no row will be selected
//
- (void)actionSelected
{
	// this method can be called on startup before a client is available.
	// so validate that we have a selected client before proceeding

	MGSNetClient *netClient  = [self selectedClient];
	if (!netClient) {
		return;
	}
	
	// the selected row index may have remained constant.
	// ensure that the netclient knows the correct active script UUID
	MGSScript *script = [self selectedScript];
	if (script) {
		[netClient.taskController setActiveScriptUUID:[script UUID]];
	}
		
	[self dispatchSelectedAction];
	
	// hmm, perhaps just selecting the group is enough
	if (YES) {
		MGSScriptManager *scriptManager = [[netClient.taskController scriptManager] activeGroup];
		NSString *groupName = [scriptManager name];
		
		if (groupName && script) {
			NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
									 MGSNoteClientScriptKey, MGSNoteClientItemKey,
									 groupName, MGSNoteClientGroupKey,
									 script, MGSNoteClientScriptKey,
									 nil];
			[self sendClientSelectedNotification:MGSNoteClientItemSelected options:options];
		}	
	}
}

/*
 
 update status bar caption
 
 */
- (void)updateStatusBarCaption
{
	// show number of Mothers available and hidden
	
	//NSInteger total = [_netClientHandler clientsCount];
	//NSInteger hidden = [_netClientHandler clientsHiddenCount];
	//NSInteger visible = total - hidden;
	
	//NSString *format;
	//if (visible == 1) {
		/*
		 Note on localization:
		 http://www.stone.com/The_Cocoa_Files/Internationalize_Your_App.html
		 
		 Localized strings are accessed as so
		 format = NSLocalizedSt*ing(@"%d kosmicTask available (%d hidden)", “Only 1 machine available to user”);
		 (note that using the full macro name in this comment crashes genstrings!
		 
		 To generate the strings file(s) (named Mother.strings etc) use: */
		// genstrings *[hmc] */*[hmc] */*/*[hmc]
		/*
		 this will search down through three folders looking for NSLocalizedSt*ing
		 and will extract the keys. values and commecnts into the strings file
		 
		 note that quotes strings must be used in the localization macros in order for the genstrings
		 tool to be able to extract the string data
		 */
	//	format = NSLocalizedString(@"%d kosmicTask available (%d hidden)", @"Only 1 machine available to user");
	//} else {
	//	format = NSLocalizedString(@"%d Mothers available (%d hidden)", @"Zero or more than 1 machines available to user");
	//}
	
	//NSString *caption = [NSString stringWithFormat:format, visible, hidden];
	NSString *caption = @"";
	
	MGSNetClient *netClient = [self selectedClient];
	if (netClient) {

		MGSClientScriptManager *scriptController = [netClient.taskController scriptManager];		
		NSAssert(scriptController, @"script controller is nil");
		
		NSInteger groupCount = [scriptController groupCount];
		NSInteger scriptCount = [scriptController scriptCount];
		NSInteger publishedScriptCount = [scriptController publishedScriptCount];
		NSString *format, *group, *script, *published;
		
		// all group will be counted
		if (groupCount > 1) groupCount--;
		
		// group count
		if (1 == groupCount) {
			format = NSLocalizedString(@"%d group", @"Only 1 group available");
		} else {
			format = NSLocalizedString(@"%d groups", @"0 or more than 1 group available");
		}
		group = [NSString stringWithFormat:format, groupCount];
		
		// action count
		if (1 == scriptCount) {
			format = NSLocalizedString(@"%d task", @"Only 1 task available");
		} else {
			format = NSLocalizedString(@"%d tasks", @"0 or more than 1 task available");
		}
		script = [NSString stringWithFormat:format, scriptCount];
		
		// published count
		format = NSLocalizedString(@"%d published", @"published groups");
		published = [NSString stringWithFormat:format, publishedScriptCount];
		
		if (netClient.applicationWindowContext.runMode == kMGSMotherRunModePublic) {
			caption = [NSString stringWithFormat:@"%@ - %@, %@", [netClient serviceShortName], group, script];
		} else {
			caption = [NSString stringWithFormat:@"%@ - %@, %@, %@", [netClient serviceShortName], group, script, published];
		}
	}
	
	// call delegate with new status
	if (_delegate && [_delegate respondsToSelector:@selector(browser:groupStatus:)]) {
		[_delegate browser:self groupStatus:caption];
	}
}

- (void) makeTableColumnCheck:(NSTableColumn *)tableColumn withTarget:(id)target withSelector:(SEL)selector
{
	NSButtonCell *buttonCell = [[NSButtonCell alloc] initTextCell: @""];
	[buttonCell setControlSize: NSSmallControlSize];	
	[buttonCell setEditable: NO];
	[buttonCell setButtonType: NSSwitchButton];	
	[buttonCell setTarget: target];	
	[buttonCell setAction: selector];
	[tableColumn setDataCell: buttonCell];
}

- (void) makeTableColumnIcon:(NSTableColumn *)tableColumn 
{
	NSImageCell *iconCell = [[NSImageCell alloc] initImageCell: nil];
	[iconCell setEditable: NO];
	[tableColumn setDataCell: iconCell];
}

#pragma mark -
#pragma mark Action dispatch
/*
 
 dispatch the currently selected action.
 
 a new MGSActionSpecifier is always created for dispatch.
 
 note that if the action table is empty then this function
 generates an action specifier with a nil script.
 
 */
- (void)dispatchSelectedAction
{
	MGSTaskDisplayType actionDisplayType = MGSTaskDisplayInSelectedTab;
	
	BOOL enableDisplayInNewTab = [[NSUserDefaults standardUserDefaults] boolForKey:MGSModClickOpensNewTab];
	BOOL enableDisplayInNewWindow = [[NSUserDefaults standardUserDefaults] boolForKey:MGSModClickOpensNewWindow];
	
	// look for modifier keys in last event
	unsigned int flags = [[NSApp currentEvent] modifierFlags];
	if ((flags & NSCommandKeyMask) && enableDisplayInNewTab) {
		actionDisplayType = MGSTaskDisplayInNewTab;
	} else if ((flags & NSAlternateKeyMask) && enableDisplayInNewWindow) {
		actionDisplayType = MGSTaskDisplayInNewWindow;			
	} 
	
	// invert action display
	if (_showActionInNewTab) {
		
		switch (actionDisplayType) {
				
			case MGSTaskDisplayInNewTab:
				actionDisplayType = MGSTaskDisplayInSelectedTab;
				break;
				
			case MGSTaskDisplayInSelectedTab:
				actionDisplayType = MGSTaskDisplayInNewTab;
				break;
				
			default:
				NSAssert(NO, @"invalid action display type");
				break;
		}
	}
	
	[self dispatchTaskSpecAtRowIndex:[actionTable selectedRow] displayType:actionDisplayType];
	
}

/*
 
 dispatch action at row index
 
 */
- (void)dispatchTaskSpecAtRowIndex:(NSInteger)rowIndex displayType:(MGSTaskDisplayType)actionDisplayType
{
	if (!_allowActionDispatch) {
		return;
	}
	
	// get action
	MGSTaskSpecifier *action = [self actionCopyAtRowIndex:rowIndex];
	if (!action) {
		MLog(RELEASELOG, @"cannot dispatch selected action");
		return;
	}
	
	// set reqd display type
	action.displayType = actionDisplayType;
		
	// call delegate with new action
	if (_delegate && [_delegate respondsToSelector:@selector(browser:userSelectedAction:)]) {
		[_delegate browser:self userSelectedAction:action];
	}
	
}

/*
 
 prompt to exit edit mode 
 
 */
- (void)promptToExitEditMode
{
	NSBeginAlertSheet(
					  NSLocalizedString(@"Sorry, cannot activate this item.", @"Alert sheet text"),	// sheet message
					  NSLocalizedString(@"Okay", @"Alert sheet button text"),              //  default button label
					  nil,              //  other button label
					  NSLocalizedString(@"Exit Configuration", @"Alert sheet button text"),             //  alternate button label
					  [[self view] window],	// window sheet is attached to
					  self,                   // we’ll be our own delegate
					  @selector(promptExitSheetDidEnd:returnCode:contextInfo:),					// did-end selector
					  NULL,                   // no need for did-dismiss selector
					  nil,                 // context info
					  NSLocalizedString(@"Please exit the configuration mode before activating other items.", @"Alert sheet text"),	// additional text
					  nil);
	
}

/*
 
 prompt exit alert sheet ended
 
 */
- (void)promptExitSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	#pragma unused(sheet)
	#pragma unused(contextInfo)
	
	switch (returnCode) {
			//okay
		case NSAlertDefaultReturn:
			break;
			
		case NSAlertAlternateReturn:;
			
			break;
			
		case NSAlertOtherReturn:;
			// post run mode should change notification
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kMGSMotherRunModePublic], MGSNoteModeKey , nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteAppRunModeShouldChange object:self userInfo:dict];
			
			break;
	}
}


/*
 
 set the client run mode
 
 */
- (void)setClientRunMode:(NSInteger)mode
{	
	MGSNetClient *netClient = [self selectedClient];
	
	//if (_runMode == mode) {
	//	return;
	//}
	//_runMode = mode;


	BOOL publishCheckColumnIsHidden = YES;
	BOOL publishedColumnIsHidden = YES;
	
	switch (mode) {

		// run actions
		case kMGSMotherRunModePublic:				// access public actions
			break;
			
		case kMGSMotherRunModeAuthenticatedUser:	// access user actions
			publishedColumnIsHidden = NO;
			break; 

		// edit actions
		case kMGSMotherRunModeConfigure:			
			publishCheckColumnIsHidden = NO;
			break;

		default:
			NSAssert(NO, @"invalid run mode");
			break;
	}

	// set the client mode
	netClient.applicationWindowContext.runMode = mode;
		
	switch (netClient.applicationWindowContext.runMode) {
		
		// access public actions
		case kMGSMotherRunModePublic:				
			if ((netClient.taskController.scriptAccessModes & kMGSMotherRunModePublic) == 0) {
				[netClient.taskController setScriptAccess:MGSScriptAccessPublic];
				[self reloadGroupTableData];
			}
			break;
			
		// in user or config modes need access to user scripts
		case kMGSMotherRunModeAuthenticatedUser:	// access user actions
		case kMGSMotherRunModeConfigure:			// configuration
			// if we do not have access to the user scripts then request them
			if ((netClient.taskController.scriptAccessModes & MGSScriptAccessTrusted) == 0) {
				[netClient.taskController clearScripts];
				[self reloadGroupTableData];
				[[MGSClientRequestManager sharedController] requestScriptDictForNetClient:netClient isPublished:NO withOwner:self];
			} else {
				[netClient.taskController setScriptAccess:MGSScriptAccessTrusted];
				[self reloadGroupTableData];
			}

			
			break;
	}
	
	// redisplay the selected client in the machine table
	[self selectedClientNeedsDisplay];
	
	// show/hide columns
	
	// group table
	NSTableColumn *published = [groupTable tableColumnWithIdentifier: MGSTableColumnIdentifierPublished];
	NSTableColumn *checkBox = [groupTable tableColumnWithIdentifier: MGSTableColumnIdentifierPublishCheckbox];
	[published setHidden:publishedColumnIsHidden];
	[checkBox setHidden:publishCheckColumnIsHidden];
	
	// action table
	published = [actionTable tableColumnWithIdentifier: MGSTableColumnIdentifierPublished];
	checkBox = [actionTable tableColumnWithIdentifier: MGSTableColumnIdentifierPublishCheckbox];
	[published setHidden:publishedColumnIsHidden];
	[checkBox setHidden:publishCheckColumnIsHidden];

}

// redisplay the selected client in the machine table
- (void)selectedClientNeedsDisplay
{
	// machine table column shows run mode
	int row = [machineTable selectedRow];
	if (row != -1) {
		[machineTable setNeedsDisplayInRect:[machineTable rectOfRow:row]];
	}
}

- (BOOL)computerListVisible
{
	return([[splitView subviews] count] == 3 ? YES : NO);
}

@end

#pragma mark -
//
// tableview delegate methods
//
@implementation MGSBrowserViewController (TableViewDelegate)

/*
 
 table view should select row
 
 */
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	#pragma unused(aTableView)
	#pragma unused(rowIndex)
	
	return YES;
}

/*
 
 table view selection did change
 
 */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *aTableView = [aNotification object];
	NSInteger rowIndex = [aTableView selectedRow];

	// rowindex of -1 will occur when table is cleared
	if (rowIndex == -1) {
		return;
	}
	
	 // post client selected notification
	 MGSNetClient *netClient  = [self selectedClient];
	 if (!netClient) {
		 MLog(DEBUGLOG, @"net client is nil");
		 return;
	 }
		 
	// new machine selected
	if (aTableView == machineTable) {
		
		// reload the group and action tables
		[self reloadGroupTableData];
		
		[self sendClientSelectedNotification:MGSNoteClientSelected options:nil];
		
		// if client flagged as unavailable then briefly show info window.
		// omit this behaviour during startup.
		if (netClient.hostStatus != MGSHostStatusAvailable && _startupTimer == nil) {
			
			// get image cell rect in window coordinate system
			NSWindow *window =[[self view] window];
			NSRect cellRect = [machineTable frameOfCellAtColumn:[machineTable columnWithIdentifier:MGSTableColumnIdentifierStatus] row:rowIndex];
			cellRect = [machineTable convertRect:cellRect toView:[window contentView]];
			
			NSString *message;
			if (netClient.hostStatus == MGSHostStatusNotYetAvailable) {
				message = NSLocalizedString(@"This KosmicTask is unavailable", @"Browser host not available");
			} else {
				message = NSLocalizedString(@"This KosmicTask is not responding", @"Browser host not responding");
			}
			
			// show message pointing to centre of image cell
			[[MGSAttachedWindowController sharedController]  showForWindow:window atCentreOfRect:cellRect withText:message];
			
		} else {
			// hide any window
			[[MGSAttachedWindowController sharedController] hide];
		}
		
		return;
	}
	
	if (aTableView == groupTable) {
		
		// set selected group index
		[netClient.taskController setActiveGroupIndex:rowIndex];
		[self reloadActionTableData];
		
		// group selected
		[self groupSelected];
				
	} else if (aTableView == actionTable) {
				
		// send the selected action to the request view controller if selected
		[self actionSelected];
	}
}

/*
 
 table view should track cell for column and row
 
 from the 10.5 release notes
 
 Another example is to not allow check box button cells to change the selection, but still allow them to be clicked on and tracked. 
 [NSApp currentEvent] will always be correct when this method is called, 
 and you may use it to perform additional hit testing of the current mouse location. See the DragNDropOutlineView demo application for an example of how to do this.
 
 */
- (BOOL)tableView:(NSTableView *)tableView
  shouldTrackCell:(NSCell *)cell
   forTableColumn:(NSTableColumn *)column
			  row:(NSInteger)row
{
	#pragma unused(tableView)
	#pragma unused(cell)
	#pragma unused(column)
	#pragma unused(row)
	/*
	if ([cell isKindOfClass:[NSButtonCell class]]) {
		return YES;
	}
	*/
	return YES;
}

@end

#pragma mark -
//
// data source methods
//
@implementation MGSBrowserViewController (DataSource)

#pragma mark Tableview data source methods

/*
 
 number of rows in table view
 
 */
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	// machine table
	if (aTableView == machineTable) {
		//
		// return number of clients
		//
		return [_netClientHandler clientsVisibleCount];
	}

	// get the current client
	MGSNetClient *netClient = [self selectedClient];
	MGSClientScriptManager *scriptController = [netClient.taskController scriptManager];
	
	if ([_netClientHandler clientsVisibleCount] == 0) {
		return 0;
	}	
	
	if (aTableView == groupTable) {
		return [scriptController groupCount];
		
	} else if (aTableView == actionTable) {
		return [scriptController groupScriptCount];
	}
	
	return 0;
}


 // alternate colours
// note that this has trouble with images
/*
- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell 
   forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex
{
    if ((aRowIndex % 2) == 0)
    {
		if ([aCell respondsToSelector:@selector(setDrawsBackground:)]) {
			[aCell setDrawsBackground: YES];
		}
		if ([aCell respondsToSelector:@selector(setBackgroundColor:)]) {
        [aCell setBackgroundColor: [NSColor colorWithCalibratedRed: 0.90
															 green: 0.90
															  blue: 0.80
															 alpha: 1.0]];
		}
    }
    else
    {
		if ([aCell respondsToSelector:@selector(setDrawsBackground:)]) {
			[aCell setDrawsBackground: NO];
		}
		if ([aCell respondsToSelector:@selector(setBackgroundColor:)]) {
        [aCell setBackgroundColor: [NSColor whiteColor]];
		}
    }
}
*/

/*
 
 table view will display cell for table column
 
 */
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	#pragma unused(aTableView)
	#pragma unused(aTableColumn)
	#pragma unused(rowIndex)
	
	if ([aCell isKindOfClass:[MGSImageAndTextCell class]]) {
		[aCell setCountMarginVertical:2];
		return;
	}
}
 
/*
 
 table view object for column and row
 
 */
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{

	MGSNetClient *netClient;
	NSString *identifier = [aTableColumn identifier];
	
	if (aTableView == machineTable) {
		
		// get client for current row
		netClient = [_netClientHandler clientAtIndex:rowIndex];
		NSAssert(netClient, @"net client is nil");
		
		//
		// show client data
		//
		
		// machine name is service name
		if ([identifier isEqualToString:MGSTableColumnIdentifierMachine]) {
			return [netClient serviceShortName];
		}
		
		// service name
		if ([identifier isEqualToString:MGSTableColumnIdentifierService]) {
			return [netClient serviceName];
		}
		
		// status is host icon
		if ([identifier isEqualToString:MGSTableColumnIdentifierStatus]) {
			return [netClient hostIcon];
		}
	
		// security
		if ([identifier isEqualToString:MGSTableColumnIdentifierSecurity]) {
			return [netClient securityIcon];
		}
		
		// username
		if ([identifier isEqualToString:MGSTableColumnIdentifierUser]) {
			NSString *username = [netClient hostUserName];
			
			// the host may not dislose the username in which case it will be @""
			if ([username isEqualToString:@""]) {
				username = @"●●●●●●●";
			}
			return username;
		}
	
		// authenticate
		if ([identifier isEqualToString:MGSTableColumnIdentifierAuthenticate]) {
			return [netClient authenticationIcon];
		}
		
		return nil;
	} 
	
	// for other tables the client identity depends on selected row in machine table
	// not on the current row in the current table
	netClient = [self selectedClient];
	//NSAssert(netClient, @"net client is nil");
	if (!netClient) {
		return @"none";
	}
	
	MGSClientScriptManager *scriptController = [netClient.taskController scriptManager];		
	NSAssert(scriptController, @"script controller is nil");
	
	if (aTableView == groupTable) {
		//
		// show script group
		//
		if ([identifier isEqualToString:MGSTableColumnIdentifierName]) {
			return [scriptController groupDisplayObjectAtIndex:rowIndex];
		}

		NSImage *image = nil;
		NSCellStateValue state = NSOffState;
		MGSScriptManager *scriptManager = [scriptController groupAtIndex:rowIndex];
		
		if ([scriptManager count] == [scriptManager publishedCount]) {
			image = [[[MGSImageManager sharedManager] publishedActionTemplate] copy];
			state = NSOnState;
		} else if ([scriptManager publishedCount] > 0) {
			image = [[[MGSImageManager sharedManager] partiallyPublishedTemplate] copy];
			state = NSMixedState;
		} else {
			image = nil;
			state = NSOffState;
		}
		
		if ([identifier isEqualToString:MGSTableColumnIdentifierPublished]) {
			return image;
		}
		
		if ([identifier isEqualToString:MGSTableColumnIdentifierPublishCheckbox]) {
			return [NSNumber numberWithInt:state];
		}
		
		return nil;
		
	} else if (aTableView == actionTable) {
		
		//
		// show script action
		//
		
		// name
		if ([identifier isEqualToString:MGSTableColumnIdentifierAction]) {
			return [scriptController groupScriptNameLabelAtIndex:rowIndex];
		}
		
		// description
		if ([identifier isEqualToString:MGSTableColumnIdentifierDescription]) {
			return [scriptController groupScriptDescriptionLabelAtIndex:rowIndex];
		}

		// UUID
		if ([identifier isEqualToString:MGSTableColumnIdentifierUUID]) {
			return [scriptController groupScriptUUIDAtIndex:rowIndex];
		}
	
		// rating
		if ([identifier isEqualToString:MGSTableColumnIdentifierRating]) {
			return [scriptController groupScriptRatingLabelAtIndex:rowIndex];
		}
		
		// publish checkbox
		if ([identifier isEqualToString:MGSTableColumnIdentifierPublishCheckbox]) {
			if ([scriptController groupScriptPublishedAtIndex:rowIndex]) {
				return [NSNumber numberWithBool:YES];
			} else {
				return [NSNumber numberWithBool:NO];
			}
		}
		
		// published image
		if ([identifier isEqualToString:MGSTableColumnIdentifierPublished]) {
			if ([scriptController groupScriptPublishedAtIndex:rowIndex]) {
				return [[[MGSImageManager sharedManager] publishedActionTemplate] copy];
			} else {
				return nil;
			}
		}
		
		// bundled image
		if ([identifier isEqualToString:MGSTableColumnIdentifierBundled]) {
			if ([scriptController groupScriptBundledAtIndex:rowIndex]) {
				//return [[MGSImageManager sharedManager] dotTemplate];
				return [NSImage imageNamed:@"GearSmall"];
			} else {
				return [[[MGSImageManager sharedManager] user] copy];
			}
		}
		
	}
	
	return nil;
}
/*
 
 table viewsort descriptors changed
 defined in NSTableDataSource protocol
 
 */
- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	#pragma unused(oldDescriptors)
	
	if (aTableView == machineTable) {
		[self reloadMachineTableData];
	} else if (aTableView == groupTable) {
		[self reloadGroupTableData];
	} else if (aTableView == actionTable) {
		[self reloadActionTableData];
	} else {
		NSAssert(NO, @"invalid tableview");
	}
		
}

/*
 
 table view should select row
 
 */
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	#pragma unused(rowIndex)
	
	if (aTableView == machineTable) {
		MGSNetClient *netClient = [self selectedClient];
		if (netClient.applicationWindowContext.runMode == kMGSMotherRunModeConfigure) {
			//[self promptToExitEditMode];	// try more permissive editing
			
			// if still in edit mode then do not allow selection
			// return (netClient.runMode == kMGSMotherRunModeConfigure ? NO : YES);
			
			return YES;
		}
	}
	
	return YES;
}
@end

#pragma mark -
@implementation MGSBrowserViewController (Sizing)
/*
 
 machine table min width
 
 */
- (CGFloat)machineTableMinWidth
{
	return 140;
}

/*
 
 group table min width
 
 */
- (CGFloat)groupTableMinWidth
{
	return 140;
}

/*
 
 action table min width
 
 */
- (CGFloat)actionTableMinWidth
{
	return 140;
}
@end
