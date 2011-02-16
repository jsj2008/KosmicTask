//
//  MGSHistoryViewController.m
//  Mother
//
//  Created by Jonathan on 14/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSHistoryViewController.h"
#import "MGSTaskSpecifierManager.h"
#import "NSTableView_Mugginsoft.h"
#import "iTableColumnHeaderCell.h"
#import "MGSTaskSpecifier.h"
#import "MGSScript.h"
#import "MGSNetClient.h"
#import "MGSAttachedWindowController.h"
#import "MGSImageManager.h"
#import "MGSPreferences.h"

// class extension
@interface MGSHistoryViewController()
- (void)tableViewSingleClick:(id)aTableView;
- (void)tableViewDoubleClick:(id)aTableView;
@end

@interface MGSHistoryViewController(Private)
- (void)bindNetClient;
@end

@implementation MGSHistoryViewController
@synthesize delegate = _delegate;
@synthesize actionHistory = _actionHistory;
@synthesize maxHistoryCount = _maxHistoryCount;

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	_ignoreTableSelectionChange = NO;
	
	// want to keep a history of actions
	[[MGSTaskSpecifierManager sharedController] setKeepHistory:YES];
	
	// bind our view table to the history 
	_actionHistory = [[MGSTaskSpecifierManager sharedController] history];
	NSAssert(_actionHistory, @"action history is nil");
	[_actionHistory setDelegate:self];
	
	[_actionHistory setAvoidsEmptySelection:NO];
	[historyTable setAllowsEmptySelection:YES];

	// configure table columns
	NSTableColumn *tableColumn = [historyTable tableColumnWithIdentifier: @"activeimage"];
	[[tableColumn headerCell] setImage:[[[MGSImageManager sharedManager] onlineStatusHeader] copy]];

	tableColumn = [historyTable tableColumnWithIdentifier: @"identifier"];
	[[tableColumn headerCell] setImage:[[[MGSImageManager sharedManager] dotTemplate] copy]];
	
	// bind the history table columns to the arranged objects of the _actionHistory (a subclass of NSArrayController)
	// the general scheme of things Bind control value to model value
	// http://lists.apple.com/archives/cocoa-dev/2005/Apr/msg02018.html
	// http://homepage.mac.com/mmalc/CocoaExamples/controllers.html
	// note that the NSTableViews content binding is automatically made when initial column is bound - see Cocoa bindings reference
	[[historyTable tableColumnWithIdentifier:@"identifier"] bind:@"value" toObject:_actionHistory withKeyPath:@"arrangedObjects.identifier" options:nil];
	[[historyTable tableColumnWithIdentifier:@"group"] bind:@"value" toObject:_actionHistory withKeyPath:@"arrangedObjects.script.group" options:nil];
	[[historyTable tableColumnWithIdentifier:@"action"] bind:@"value" toObject:_actionHistory withKeyPath:@"arrangedObjects.script.nameWithParameterValues" options:nil];
	[[historyTable tableColumnWithIdentifier:@"description"] bind:@"value" toObject:_actionHistory withKeyPath:@"arrangedObjects.script.description" options:nil];

	[self bindNetClient];

	// set target action behaviour
	[historyTable setTarget:self];
	[historyTable setAction:@selector(tableViewSingleClick:)];
	[historyTable setDoubleAction:@selector(tableViewDoubleClick:)];

	// load saved history
	[self loadSavedHistory];
}

#pragma mark View handling
/*
 
 min view height
 
 */
- (CGFloat)minViewHeight
{
	return ([historyTable rowHeight] + [historyTable intercellSpacing].height) * 3 + [[historyTable headerView] frame].size.height;
}

#pragma mark Table handling
/*
 
 table view single click
 
 */
- (void)tableViewSingleClick:(id)aTableView
{
	#pragma unused(aTableView)
}
/*
 
 table view double click
 
 */
- (void)tableViewDoubleClick:(id)aTableView
{
	#pragma unused(aTableView)
	
	if ([historyTable clickedRow] != -1) {
				
		// want our action to observe the is processing state of the delegated action.
		// our action is bound to the tableview so updating it will update the tableview
		MGSTaskSpecifier *action = [[_actionHistory selectedObjects] objectAtIndex:0];
		
		// do not want to launch this action
		if (MGSTaskAvailable != action.isAvailable) {
			return;
		}
		
		// call delegate with new action
		if (_delegate && [_delegate respondsToSelector:@selector(historyExecuteSelectedAction:)]) {
			[_delegate historyExecuteSelectedAction:self];
		}			
	}

}

#pragma mark - NSTableView delegate methods

/*
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return NO;
}
*/

//================================================================
//
// history item selected
//
//
//================================================================
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	#pragma unused(aNotification)
	
	// ignore the table selection change
	// when adding rows programmotically
	if (_ignoreTableSelectionChange) {
		_ignoreTableSelectionChange = NO;
		return;
	}
	
	NSInteger selectedRow = [historyTable selectedRow];
	if (selectedRow == -1) {
		return;
	}

	// get the selected object from the history (this is bound to the table)
	NSArray *actionSelection = [_actionHistory selectedObjects];
	NSAssert([actionSelection count] == 1, @"more than one history item selected");
	
	// get the action
	MGSTaskSpecifier *action = [actionSelection objectAtIndex:0]; 
	
	// is the action available (ie: net client service available)?
	// this may occur for a history action whose client has not yet become
	// available or has become unavailable
	MGSTaskAvailability availability = action.isAvailable;
	if (availability != MGSTaskAvailable) {
		
		// get image cell rect in window coordinate system
		NSWindow *window =[[self view] window];
		NSRect cellRect = [historyTable frameOfCellAtColumn:[historyTable columnWithIdentifier:@"activeimage"] row:selectedRow];
		cellRect = [historyTable convertRect:cellRect toView:[window contentView]];
		
		NSString *windowText;
		
		if (availability == MGSTaskClientNotAvailable) {
			windowText = NSLocalizedString(@"This KosmicTask server is currently unavailable", @"history task client not available");
		} else {
			windowText = NSLocalizedString(@"This KosmicTask is not currently available", @"history task not currently available");
		}
		
		// show message pointing to centre of image cell
		[[MGSAttachedWindowController sharedController] 
			showForWindow:window
			atCentreOfRect:cellRect 
			withText:windowText];
		
		// do not want to delegate this action
		return;
	} else {
		// hide any window
		[[MGSAttachedWindowController sharedController] hide];
	}
	
	// look for modifier keys in current event
	int actionDisplayType;
	unsigned int flags = [[NSApp currentEvent] modifierFlags];
	if ((flags & NSCommandKeyMask) || (flags & NSAlternateKeyMask) || (flags & NSControlKeyMask)) {
		actionDisplayType = MGSTaskDisplayInNewTab;
	} else {
		actionDisplayType = MGSTaskDisplayInSelectedTab;
	}
	
	// invert action display
	/*if (_showActionInNewTab) {
		
		switch (_actionDisplayType) {
				
			case MGSActionDisplayInNewTab:
				_actionDisplayType = MGSActionDisplayInSelectedTab;
				break;
				
			case MGSActionDisplayInSelectedTab:
				_actionDisplayType = MGSActionDisplayInNewTab;
				break;
		}
	}*/
	
	// copy the action for delegate
	_delegatedAction = nil;
	_delegatedAction = [action historyCopy];
	_delegatedAction.displayType = actionDisplayType;

	// call delegate with action
	if (_delegate && [_delegate respondsToSelector:@selector(history:actionSelected:)]) {
		[_delegate history:self actionSelected:_delegatedAction];
	}
	
}

#pragma mark History content
/*
 
 load history from file
 
 */
- (void)loadSavedHistory
{
	[_actionHistory loadFromPath:[_actionHistory historyPath]];
}

/*
 
 save history to file
 
 */
- (void)saveHistory
{
	[_actionHistory saveToPath:[_actionHistory historyPath]];
}

/*
 
 clear history
 
 */
- (IBAction)clearHistory:(id)sender
{
	#pragma unused(sender)
	
	[_actionHistory removeAllObjects];
	[self saveHistory];
}
/*
 
 set history capacity
 
 */
- (IBAction)setHistoryCapacity:(id)sender
{
	NSAssert([sender isKindOfClass:[NSMenuItem class]], @"invalid sender");
	
	// menu item tag is capacity
	[[NSUserDefaults standardUserDefaults] setInteger:[(NSMenuItem *)sender tag] forKey:MGSTaskHistoryCapacity];
}
/*
 
 validate menu item
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = [menuItem action];
    
	// set history capacity
    if (action == @selector(setHistoryCapacity:)) {
		NSInteger capacity = [[NSUserDefaults standardUserDefaults] integerForKey:MGSTaskHistoryCapacity];
		menuItem.state = menuItem.tag == capacity ? NSOnState : NSOffState;
	}
	
	return YES;
}

#pragma mark MGSTaskSpecifierManager delegate
//
// whenever an item is added to the actionHistory this delegate method
// will ensure that the new row does not get selected.
// nothing else seems to work. The tableview delegate methods
// do not get called for programmatic changes and [_actionHistory setAvoidsEmptySelection:NO]
// seems to have little effect
// -setSelectsInsertedObjects might be the one to try !
- (void)actionSpecifierAdded:(MGSTaskSpecifier *)actionSpecifier
{
	#pragma unused(actionSpecifier)
	
	_ignoreTableSelectionChange = YES;
	[historyTable deselectAll:self];
}

- (void)actionSpecifierWillBeAdded
{
	// want to ignore the next selection change
	_ignoreTableSelectionChange = YES;
}
@end


@implementation MGSHistoryViewController(Private)

#pragma mark Binding
/*
 
 bind net client
 
 */
- (void)bindNetClient
{
	[[historyTable tableColumnWithIdentifier:@"machine"] bind:@"value" toObject:_actionHistory withKeyPath:@"arrangedObjects.representedNetClient.serviceShortName" options:nil];
	[[historyTable tableColumnWithIdentifier:@"activeimage"] bind:@"value" toObject:_actionHistory withKeyPath:@"arrangedObjects.representedNetClient.hostIcon" options:nil];

}
@end
