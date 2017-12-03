//
//  MGSLWindowController.m
//  Mother
//
//  Created by Jonathan on 30/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSLWindowController.h"
#import "NSBundle_Mugginsoft.h"
#import "NSDictionary_Mugginsoft.h"
#import "MGSLM.h"
#import "MGSL.h"
#import "MGSError.h"
#import "MGSLAddWindowController.h"
#import "MGSUser.h"
#import "MGSAppTrial.h"
#import "MGSAPLicenceCode.h"

NSString *MGSSelectionIndexesContext = @"SelectionIndexesContext";
static BOOL trialExpired = NO;

@interface MGSLWindowController()
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void)addWindowSheetDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void)windowWillClose:(NSNotification *)aNote;
@end

@implementation MGSLWindowController

@synthesize selectedItem = _selectedItem;
@synthesize allowRemoveLicence = _allowRemoveLicence;

/*
 
 shared instance
 
 */
+ (MGSLWindowController *)sharedController
{
    static MGSLWindowController	*sharedInstance = nil;
	
    if (sharedInstance == nil)
    {
        sharedInstance = [[self alloc] init];
		(void)[sharedInstance initWithWindowNibName:@"LicenceWindow"];
    }
	
    return sharedInstance;
}


/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	// MGSLM subclasses NSArrayController
	_licencesController = [MGSLM sharedController];
	_addController = nil;
	
	// bind licence table view columns to array controller
	[[_licencesTableView tableColumnWithIdentifier:@"owner"] bind:@"value" toObject:_licencesController withKeyPath:@"arrangedObjects.owner" options:nil];
	[[_licencesTableView tableColumnWithIdentifier:@"seats"] bind:@"value" toObject:_licencesController withKeyPath:@"arrangedObjects.seats" options:nil];

	[_licencesController addObserver:self forKeyPath:@"selectionIndexes" options:NSKeyValueObservingOptionNew context:&MGSSelectionIndexesContext];

	// bind detail table view controller o dictionary controller
	_licenceDictionaryController = [[NSDictionaryController alloc] init];
	[_licenceDictionaryController bind:NSContentDictionaryBinding toObject:self withKeyPath:@"selectedItem" options:nil];
	[[_detailTableView tableColumnWithIdentifier:@"name"] bind:@"value" toObject:_licenceDictionaryController withKeyPath:@"arrangedObjects.key" options:nil];
	[[_detailTableView tableColumnWithIdentifier:@"value"] bind:@"value" toObject:_licenceDictionaryController withKeyPath:@"arrangedObjects.value" options:nil];
	
	// update selected item
	[self updateSelectedItem:_licencesController];
	
	// bind buttons
	[_removeLicenceButton bind:NSEnabledBinding toObject:self withKeyPath:@"allowRemoveLicence" options:nil];
	
}

/*
 
 - windowWillClose:
 
 */
- (void)windowWillClose:(NSNotification *)aNote
{
	#pragma unused(aNote)
	
	// if trial was expired
	if (trialExpired) {
		
		// if trial licence still loaded
		if (MGSAPLicenceIsRestrictiveTrial()) {
			[NSApp terminate:self];
			return;
		}
		
		// must have a valid licence now.
		// prompt to relaunch app
		NSRunAlertPanel(NSLocalizedString(@"Licence Installed", @"dialog title"), 
						NSLocalizedString(@"Please restart application.", @"dialog title"), nil, nil, nil);
	
		[NSApp terminate:self];
	}
}

/*
 
 show window
 
 */
- (void)showWindow:(id)sender
{
	// check for trial
	if (MGSAPLicenceIsRestrictiveTrial()) {
		
		NSUInteger trialDaysRemaining = 0;
		
		// check for trial expiry
		trialExpired = MGSAppTrialPeriodExpired(&trialDaysRemaining);
	}
	
	[super showWindow:sender];
}

/*
 
 update selected item
 
 */
- (void)updateSelectedItem:(NSArrayController *)object
{
	if ([[object selectedObjects] count] > 0)
	{
		MGSL *licence = nil;
		
		if ([[object selectedObjects] objectAtIndex:0] != nil)
		{
			// update our item and reflect the change to our dictionary controller
			licence = [[object selectedObjects] objectAtIndex:0];
			if ([licence isKindOfClass: [MGSL class]]) {
				
				// in order ofr our NSTAbleView to be able to sort the dict without exceptions
				// we need to ensure that all keys and esp objects are strings.
				self.selectedItem = [[licence dictionary] dictionaryWithObjectsAndKeysAsStrings];
				
				[_licenceDictionaryController bind:NSContentDictionaryBinding toObject:self withKeyPath:@"selectedItem" options:nil];
			}
		}
		
		// do not allow deletion of only licence
		self.allowRemoveLicence = [[object arrangedObjects] count] > 1 ? YES : NO;
		
		// non admin users cannot delete computer licences
		if (![[MGSUser currentUser] isMemberOfAdminGroup] && [[licence type] integerValue] != MGSLTypeIndividual) {
			self.allowRemoveLicence = NO;
		}
	} else {
		self.allowRemoveLicence = NO;
	}
}
// -------------------------------------------------------------------------------
//	observeValueForKeyPath:keyPath:object:change:context
// -------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// has the array controller's "selectionIndexes" binding changed?
	if (context == &MGSSelectionIndexesContext)
	{
		[self updateSelectedItem:object];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

/* 
 
 buy licences
 
 */
- (void)buyLicences:(id)sender
{
	#pragma unused(sender)
	
	[MGSLM buyLicences];
}

/*
 
 add licence
 
 */
- (void)addLicence:(id)sender
{
	#pragma unused(sender)
	
	NSOpenPanel *op = [NSOpenPanel openPanel];
	
	[op setCanChooseDirectories:NO];
	[op setCanChooseFiles:YES];
	[op setAllowsMultipleSelection:NO];
	[op setDelegate:self];
	[op setRequiredFileType:[[MGSLM sharedController] extension]];
	
	[op setTitle:NSLocalizedString(@"Select licence file", @"Licence file selection prompt")];
	[op setPrompt:NSLocalizedString(@"Select", @"Licence select button text")];
	
	
	/* display the NSSavePanel */
	[op beginSheetForDirectory:[op directory] 
								 file:nil 
								types: [NSArray arrayWithObject:[[MGSLM sharedController] extension]]
					   modalForWindow:[self window] 
						modalDelegate:self 
				didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
						  contextInfo:nil];
}

/*
 
 remove licence
 
 */
- (void)removeLicence:(id)sender
{
	#pragma unused(sender)
	
	// get are selected item
	NSArray *selectedObjects = [_licencesController selectedObjects];
	if ([selectedObjects count] == 0) return;	
	MGSL *licence = [selectedObjects objectAtIndex:0];
	
	// remove it from the controller
	[_licencesController removeObjectAndFile:licence];
}

/*
 
 open sheet did end
 
 */
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	#pragma unused(contextInfo)
	
	// hide the sheet
	[sheet orderOut:self];
	
	// check for cancel
	if (NSCancelButton == returnCode) {
		return;
	}
	
	// get filename
	if (0 == [[sheet filenames] count]) return;
	NSString *filename = [[sheet filenames] objectAtIndex:0];

	// validate item
	if ([[MGSLM sharedController] validateItemAtPath:filename]) {
		
		// confirm add new item
		[self confirmAdd:filename];
	} else {
		[[MGSLM sharedController] showLastError];
	}
	
	return;
	
}

/*
 
 confirm add licence
 
 */
- (void)confirmAdd:(NSString *)path
{
	_addController = [[MGSLAddWindowController alloc] initWithPath:path];
	[_addController window];	// load nib

	// show the sheet
	[NSApp beginSheet:[_addController window] modalForWindow:[self window] 
		modalDelegate:self 
	   didEndSelector:@selector(addWindowSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}
/*
 
 add window sheet did end
 
 */
- (void)addWindowSheetDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	#pragma unused(contextInfo)
	
	// hide the sheet
	[sheet orderOut:self];
	
	// check for cancel
	if (0 == returnCode) {
		_addController = nil;
		return;
	}
	
	// add item
	if ([[MGSLM sharedController] addItemAtPath:[_addController path] withDictionary:[_addController optionDictionary]]) {
		// select new item
	} else {
		[[MGSLM sharedController] showLastError];
	}
	
	_addController = nil;
	return;
	
}


#pragma mark NSTableView delegate
/*
 
 text should begin editing.
 This is sent by the table view to allow editing.
 Replying with No means that the table view cell text can be selected and dragged but not edited.
 This will allow the hash to be selected and coped for queries.
 */
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
	#pragma unused(control)
	#pragma unused(fieldEditor)
	
	return NO;
}
@end
