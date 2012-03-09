//
//  MGSImageBrowserViewController.m
//  Mother
//
//  Created by Jonathan on 30/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSAppController.h"
#import "MGSImageBrowserViewController.h"
#import "MGSNetAttachments.h"
#import "PlacardScrollView.h"
#import "NSString_Mugginsoft.h"
#import "MGSBrowserImage.h"
#import "MGSImageBrowserView.h"

NSString *MGSImagesBrowserCountContext = @"MGSImagesBrowserCountContext";
NSString *KeyPath_FileCountString = @"fileCountString";

#define MGS_SAVE_OVERWRITE_OPT_PROMPT 0
#define MGS_SAVE_OVERWRITE_OPT_OVERWRITE 1


@implementation MGSSaveImageSelectionAccessoryViewController

@synthesize fileCountString = _fileCountString;
@synthesize fileCount = _fileCount;
@synthesize openInDefaultAppAfterSave = _openInDefaultAppAfterSave;
@synthesize overwriteOption = _overwriteOption;


/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	self.openInDefaultAppAfterSave = NO;
	self.overwriteOption = MGS_SAVE_OVERWRITE_OPT_PROMPT;
}

/*
 
 set file count
 
 */
- (void)setFileCount:(NSInteger)value
{
	_fileCount = value;
	self.fileCountString = [NSString stringWithFormat:NSLocalizedString(@"%i files to be saved", @"Image save panel file count text"), _fileCount];
}

@end

// class extension
@interface MGSImageBrowserViewController()
- (void)saveSheetDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
- (void)saveSelectionSheetDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end


@implementation MGSImageBrowserViewController

@synthesize attachments = _attachments;
@synthesize fileCountString = _fileCountString;
@synthesize imageBrowser = _imageBrowser;
@synthesize menu = _menu;
@synthesize splitViewAdditionalView = _splitViewAdditionalView;

/*
 
 init
 
 */
- (id)init
{
	if ([super initWithNibName:@"ImageBrowserView" bundle:nil]) {
		
	}
	return self;
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	//
	// set additional drag views for splitview
	// scrollview is subclass PlacardScrollView
	// 
	[scrollView setSide:PlacardRightCorner];
	
	// bind
	[fileCountTextField bind:NSValueBinding toObject:self withKeyPath:KeyPath_FileCountString options:nil];
	[_slider bind:NSValueBinding toObject:_imageBrowser withKeyPath:@"zoomValue" options:nil];
	
	// Allow reordering, animations and set the dragging destination delegate.
    [_imageBrowser setAllowsReordering:NO];
    [_imageBrowser setAnimates:YES];
	
    //[_imageBrowser setDraggingDestinationDelegate:self];
}

/*
 
 save selection
 
 */
- (IBAction)saveSelection:(id)sender
{	
	#pragma unused(sender)
	
	// sanity check
	if ([self numberOfItemsInImageBrowser:nil] == 0) {
		return;
	}
	
	// get selection
	NSIndexSet *indexes = [_imageBrowser selectionIndexes];
	
	// if no image selected then select all
	if ([indexes count] == 0) {
		[_imageBrowser selectAll:self];
		indexes = [_imageBrowser selectionIndexes];
	}
	
	// if saving only one file then use the save method
	if  ([indexes count] == 1) {
		[self save:self];
	}
	
	_accessoryViewController.fileCount = [indexes count];
	
	// we only want to select a directory to save into so NSOpenPamel is appropriate
	NSOpenPanel *op = [NSOpenPanel openPanel];
	
	[op setCanChooseDirectories:YES];
	[op setCanChooseFiles:NO];
	[op setAllowsMultipleSelection:NO];
	[op setDelegate:self];
	[op setCanCreateDirectories:YES];
	[op setAccessoryView:[_accessoryViewController view]];
	[op setTitle:NSLocalizedString(@"Select directory", @"Save result panel prompt")];
	[op setPrompt:NSLocalizedString(@"Save", @"Save result button text")];
	
	
	/* display the NSOpenPanel */
	[op beginSheetForDirectory:[op directory] 
						  file:nil 
						 types: nil
				modalForWindow:[self window] 
				 modalDelegate:self 
				didEndSelector:@selector(saveSelectionSheetDidEnd:returnCode:contextInfo:) 
				   contextInfo:nil];
}

/*
 
 save selection sheet did end
 
 */
- (void)saveSelectionSheetDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	#pragma unused(contextInfo)
	
	// hide the sheet
	[sheet orderOut:self];
	
	// check for cancel
	if (NSCancelButton == returnCode) {
		return;
	}
	
	// must have a selection
	if ([[sheet filenames] count] == 0) {
		return;
	}
	
	// get save folder
	NSString *folder = [[sheet filenames] objectAtIndex:0];
	
	// get our first index
	NSInteger selectionIndex = [[_imageBrowser selectionIndexes] firstIndex];
	BOOL applyToAll = NO;
	NSInteger selectedButton = NSAlertAlternateReturn;
	NSMutableArray *fileArray = [NSMutableArray arrayWithCapacity:1];
	
	// loop through selected images
	while (selectionIndex != NSNotFound) {
		
		// get our browser image
		MGSBrowserImage *browserImage = [self imageBrowser:_imageBrowser itemAtIndex:selectionIndex];
		
		// get our save path
		NSString *fileName = browserImage.imageTitle;	// title contains filename
		NSString *path = [folder stringByAppendingPathComponent:fileName];
		
		// check if file exists
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			
			// prompt to overwrite
			if ([_accessoryViewController overwriteOption] == MGS_SAVE_OVERWRITE_OPT_PROMPT) {
				
				// if not applying to all then prompt
				if (!applyToAll) {
					
					NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"A file named %@ already exists in this location.", @"file copy sheet message"), fileName];
					NSAlert *alert = [NSAlert alertWithMessageText: alertMessage
													 defaultButton: NSLocalizedString(@"Replace", @"file copy sheet default button")
												   alternateButton: NSLocalizedString(@"Don't Replace", @"file copy sheet alternate button")
													   otherButton: NSLocalizedString(@"Stop", @"file copy sheet other button")
										 informativeTextWithFormat: NSLocalizedString(@"Do you want to replace this file?", @"file copy sheet info text")];
					[alert setShowsSuppressionButton:YES];
					[[alert suppressionButton] setTitle: NSLocalizedString(@"Apply to all?", @"file copy sheet suppression button title")];
					
					// run modal dialog
					selectedButton = [alert runModal];
					
					// suppress alert in future
					applyToAll = ([[alert suppressionButton] state] == NSOnState) ? YES : NO;
				}
				
				// process 
				switch (selectedButton) {
					
					// replace
					case NSAlertDefaultReturn:
						break;

					// don't replace
					case NSAlertAlternateReturn:
						goto getNextIndex;
						break;
						
					// stop
					case NSAlertOtherReturn:
					case NSAlertErrorReturn:
					default:
						return;
						break;
				}
			}

			// remove file at path
			if (![[NSFileManager defaultManager] removeFileAtPath:path handler:self]) {
				return;
			}
		}
		
		// save copy of browser image file
		if (![[NSFileManager defaultManager] copyPath:browserImage.filePath toPath:path handler:self]) {
			return;
		}
		
		// add path to array if not present
		if (_accessoryViewController.openInDefaultAppAfterSave) {
			[fileArray addObject:path];
		}
		
	getNextIndex:		
		// get next index
		selectionIndex = [[_imageBrowser selectionIndexes] indexGreaterThanIndex:selectionIndex];
        
        // call dispose to clean up resources
        [browserImage dispose];
	}

	// open files in default apps if required
	if (_accessoryViewController.openInDefaultAppAfterSave) {
		
		for (NSString *filePath in fileArray) {	
			
			// queue these as NSOperations
			[[NSApp delegate] queueOpenFileWithDefaultApplication:filePath];
		}
	}
	
}

/*
 
 view window
 
 as view is in a tab view even though loaded its view property may be nil if not currently displayed/
 if a method depending on the view's when is called when it is not displayed then the cal will misbehave as [[self view] window] window will return nil
 */
- (NSWindow *)window
{
	return [[self view] window];
}


- (void)setMenu:(NSMenu *)aMenu
{
	[_imageBrowser setMenu:aMenu];
}
/*
 
 save
 
 */
- (IBAction)save:(id)sender
{
	#pragma unused(sender)
	
	// sanity check
	if ([self numberOfItemsInImageBrowser:nil] == 0) {
		return;
	}
	
	// get selection
	NSIndexSet *indexes = [_imageBrowser selectionIndexes];
	
	// if no image selected then select all
	if ([indexes count] == 0) {
		[_imageBrowser selectAll:self];
		indexes = [_imageBrowser selectionIndexes];
	}
	
	// save selection
	if  ([indexes count] > 1) {
		[self saveSelection:self];
	}
	
	NSSavePanel *savePanel;
	
	/* create or get the shared instance of NSSavePanel */
	savePanel = [NSSavePanel savePanel];
	
	/* set up new attributes */
	
	//
	// here we explicitly want to always start in the user's home directory,
	// If we don't set this, then the save panel will remember the last visited
	// directory, which is generally preferred.
	//
	//[savePanel setDirectory: NSHomeDirectory()];
	
	[savePanel setDelegate: self];	// allows us to be notified of save panel events
	
	//[savePanel setMessage:@"This is a customized save dialog for saving text files:"];
	//[savePanel setAccessoryView: _savePanelAccessoryView];	// add our custom view
	//[savePanel setRequiredFileType: @"txt"];
	//[savePanel setNameFieldLabel:NSLocalizedString(@"Save Result As:", @"Save result panel label")];	// string truncated in panel
	
	MGSBrowserImage *browserImage = [self imageBrowser:_imageBrowser itemAtIndex:[indexes firstIndex]];
	NSString *fileName = browserImage.imageTitle;

    // call dispose to clean up resources
    [browserImage dispose];

	if (!fileName) fileName = @"";
	
	/* display the NSSavePanel */
	[savePanel beginSheetForDirectory:[savePanel directory] file:fileName 
					   modalForWindow:[self window] 
						modalDelegate:self didEndSelector:@selector(saveSheetDidEnd:returnCode:contextInfo:) 
						  contextInfo:nil];
}

#pragma mark NSFileManager handler

/*
 
 file manager should proceed after error
 
 */
- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo
{
	#pragma unused(manager)
	
	int result;
	NSString *error = [errorInfo objectForKey:@"Error"];
	NSString *path = [errorInfo objectForKey:@"Path"];
	NSString *toPath = [errorInfo objectForKey:@"ToPath"];

	if (toPath) {
		MLog(DEBUGLOG, @"error: %@ path: %@ to path: %@", error, path, toPath);
	} else {
		MLog(DEBUGLOG, @"error: %@ path: %@", error, path);
	}

	if (YES) {
		NSString *msgFmt = NSLocalizedString(@"Error type: %@\n\nFile path: %@", @"File error format text");
		NSString *defaultButton = NSLocalizedString(@"OK", @"File error button text");
		NSRunAlertPanel(NSLocalizedString(@"KosmicTask has encountered a file error.", @"File error dialog title"), msgFmt, defaultButton, nil,  NULL,
								 error,
								 path);
		return NO;
	} else {
		result = NSRunAlertPanel([[NSApp delegate] applicationName], @"Error: %@ with file: %@", @"Proceed", @"Stop",  NULL,
								 error,
								 path);
		
		
		if (result == NSAlertDefaultReturn)
			return YES;
		else
			return NO;
	}
}

/*
 
 file manager will process path
 
 */
- (void)fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path
{
	#pragma unused(manager)
	#pragma unused(path)
}

#pragma mark Save Dialog Stuff

/*
 
 save sheet did end
 
 */
- (void)saveSheetDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	#pragma unused(contextInfo)
	
	if (NSCancelButton == returnCode) {
		return;
	}
		
	// get save path
	NSString *path = [sheet filename];
	
	// remove file if it exists
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		if (![[NSFileManager defaultManager] removeFileAtPath:path handler:self]) {
			return;
		}
	}
	
	// the browser image
	MGSBrowserImage *browserImage = [self imageBrowser:_imageBrowser itemAtIndex:[[_imageBrowser selectionIndexes] firstIndex]];
	
	// save copy of browser image file
	if (![[NSFileManager defaultManager] copyPath:browserImage.filePath toPath:path handler:self]) {
		MLogInfo(@"Failed to save file to %@", path);
	}
    
    // call dispose to clean up resources
    [browserImage dispose];

}

// -------------------------------------------------------------------------------
// compareFilename:name1:name2:caseSensitive:
// -------------------------------------------------------------------------------
// Controls the ordering of files presented by the NSSavePanel object sender.
//
// Don’t reorder filenames in the Save panel without good reason, because it may confuse the user
// to have files in one Save panel or Open panel ordered differently than those in other such panels
// or in the Finder. The default behavior of Save and Open panels is to order files as they appear in the Finder.
//
// Note also that by implementing this method you will reduce the operating performance of the panel.
//
- (NSComparisonResult)panel:(id)sender compareFilename:(NSString *)name1 with:(NSString *)name2 caseSensitive:(BOOL)caseSensitive
{
	#pragma unused(sender)
	#pragma unused(caseSensitive)
	
	// do the normal compare
	return [name1 compare:name2];
}

// -------------------------------------------------------------------------------
// isValidFilename:filename:
// -------------------------------------------------------------------------------
// Gives the delegate the opportunity to validate selected items.
//
// The NSSavePanel object sender sends this message just before the end of a modal session for each filename
// displayed or selected (including filenames in multiple selections). The delegate determines whether it
// wants the file identified by filename; it returns YES if the filename is valid, or NO if the save panel
// should stay in its modal loop and wait for the user to type in or select a different filename or names.
// If the delegate refuses a filename in a multiple selection, none of the filenames in the selection is accepted.
//
// In this particular case: we arbitrary make sure the save dialog does not allow files named as "text"
//
- (BOOL)panel:(id)sender isValidFilename:(NSString *)filename
{
	#pragma unused(sender)
	#pragma unused(filename)
	
	BOOL result = YES;
	
	/*
	 NSURL* url = [NSURL fileURLWithPath: filename];
	 if (url && [url isFileURL])
	 {
	 NSArray* pathPieces = [[url path] pathComponents];
	 NSString* actualFilename = [pathPieces objectAtIndex:[pathPieces count]-1];
	 if ([actualFilename isEqual:@"text.txt"])
	 {
	 NSAlert *alert = [NSAlert alertWithMessageText: @"Cannot save a file name titled \"text\"."
	 defaultButton: @"OK"
	 alternateButton: nil
	 otherButton: nil
	 informativeTextWithFormat: @"Please pick a new name."];
	 [alert runModal];
	 result = NO;
	 }
	 }
	 */
	
	return result;
}

// -------------------------------------------------------------------------------
// userEnteredFilename:filename:confirmed:okFlag
// -------------------------------------------------------------------------------
// Sent when the user confirms a filename choice by hitting OK or Return in the NSSavePanel object sender.
//
// You can either leave the filename alone, return a new filename, or return nil to cancel the save
// (and leave the Save panel as is). This method is sent before any required extension is appended to the
// filename and before the Save panel asks the user whether to replace an existing file.
//
//
- (NSString*)panel:(id)sender userEnteredFilename:(NSString*)filename confirmed:(BOOL)okFlag
{
	#pragma unused(sender)
	#pragma unused(okFlag)
	
	return filename;
}

// -------------------------------------------------------------------------------
// willExpand:expanding
// -------------------------------------------------------------------------------
// Sent when the NSSavePanel object sender is about to expand or collapse because the user clicked the
// disclosure triangle that displays or hides the file browser.
//
// In this particular case, we have sound feedback for expand/shrink of the save dialog.
//
- (void)panel:(id)sender willExpand:(BOOL)expanding
{
	#pragma unused(sender)
	#pragma unused(expanding)
	
	/*
	 if ([soundOnCheck state])
	 {
	 if (expanding)
	 [[NSSound soundNamed:@"Pop"] play];
	 else
	 [[NSSound soundNamed:@"Blow"] play];
	 }
	 
	 // package navigation doesn't apply for the shrunk/simple dialog
	 [navigatePackages setHidden: !expanding];
	 */
}

// -------------------------------------------------------------------------------
// directoryDidChange:path
// -------------------------------------------------------------------------------
// Sent when the user has changed the selected directory in the NSSavePanel object sender.
//
// In this particular case, we have sound feedback for directory changes.
//
- (void)panel:(id)sender directoryDidChange:(NSString *)path
{
	#pragma unused(sender)
	#pragma unused(path)
	
	/*
	 if ([soundOnCheck state])
	 [[NSSound soundNamed:@"Frog"] play];
	 */
}

// -------------------------------------------------------------------------------
// panelSelectionDidChange:sender
// -------------------------------------------------------------------------------
// Sent when the user has changed the selection in the NSSavePanel object sender.
//
// In this particular case, we have sound feedback for selection changes.
//
- (void)panelSelectionDidChange:(id)sender
{
	#pragma unused(sender)
	
	/*
	 if ([soundOnCheck state])
	 [[NSSound soundNamed:@"Hero"] play];
	 */
}

// -------------------------------------------------------------------------------
// filePackagesAsDirAction:sender
// -------------------------------------------------------------------------------
// toggles flag via custom checkbox to view packages
//
- (IBAction)filePackagesAsDirAction:(id)sender
{
	#pragma unused(sender)
	
	/*
	 [savePanel setTreatsFilePackagesAsDirectories: [sender state]];
	 */
}
/*
 
 quick look
 
 */
- (IBAction)quicklook:(id)sender
{
	#pragma unused(sender)
	
	// get selection
	NSIndexSet *indexes = [_imageBrowser selectionIndexes];
	
	// if no image selected then select first
	if ([indexes count] == 0) {
		[_imageBrowser setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]	byExtendingSelection:NO];
		indexes = [_imageBrowser selectionIndexes];
	}
	
	NSInteger idx = [indexes firstIndex];
	while (idx != NSNotFound) {
		
		// the browser image
		MGSBrowserImage *browserImage = [self imageBrowser:_imageBrowser itemAtIndex:idx];
		NSString *filePath = [browserImage.filePath copy];
		
        // call dispose to clean up resources
        [browserImage dispose];
        
		// queue showing of finder quicklook
		[[NSApp delegate] queueShowFinderQuickLook:filePath];
		
		idx = [indexes indexGreaterThanIndex:idx];
	}
}

/*
 
 number of items in image browser
 
 tried using bindings but without success
 uses datasource like Apple sample code
 
 */
- (int) numberOfItemsInImageBrowser:(IKImageBrowserView *) browser
{
	#pragma unused(browser)
	
	int count = [_attachments.attachmentPreviewImages count];
    return count;
}

/*
 
 item at index
 
 */
- (id)imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)idx
{
	#pragma unused(aBrowser)
	
	id item = [_attachments.attachmentPreviewImages objectAtIndex:idx];
	
    return item;
}


/*
 
 remove items at indexes
 
 */
- (void)imageBrowser:(IKImageBrowserView*)view removeItemsAtIndexes:(NSIndexSet *)indexes
{
	#pragma unused(view)
	
	[_attachments.attachmentPreviewImages removeObjectsAtIndexes:indexes];
}

// -------------------------------------------------------------------------
//	moveItemsAtIndexes:
//
//	The user wants to reorder images, update the datadsource and the browser
//	will reflect our changes.
// ------------------------------------------------------------------------- 
/*- (BOOL)imageBrowser:(IKImageBrowserView*)view moveItemsAtIndexes: (NSIndexSet*)indexes toIndex:(unsigned int)destinationIndex
{
	NSInteger		index;
	NSMutableArray*	temporaryArray;
	
	temporaryArray = [[[NSMutableArray alloc] init] autorelease];
	
	// First remove items from the data source and keep them in a temporary array.
	for (index = [indexes lastIndex]; index != NSNotFound; index = [indexes indexLessThanIndex:index])
	{
		if (index < destinationIndex)
			destinationIndex --;
		
		id obj = [images objectAtIndex:index];
		[temporaryArray addObject:obj];
		[images removeObjectAtIndex:index];
	}
	
	// Then insert the removed items at the appropriate location.
	NSInteger n = [temporaryArray count];
	for (index = 0; index < n; index++)
	{
		[images insertObject:[temporaryArray objectAtIndex:index] atIndex:destinationIndex];
	}
	
	return YES;
}
*/
/*
 
 set attachments
 
 */

- (void)setAttachments:(MGSNetAttachments *)attachments
{	
	_attachments = attachments;
	_attachments.delegate = self;
	//[self zoomChange:self];
	[self reloadData];

}

/*
 
 reload data
 
 */
- (void)reloadData
{
	[_imageBrowser reloadData];

	NSString *fmt = nil;
	int fileCount = [self numberOfItemsInImageBrowser:nil];
	BOOL enableControls = YES;
	
	[self willChangeValueForKey:KeyPath_FileCountString];

	if (fileCount > 0) {
		fmt = NSLocalizedString(@"%i files, %@ total", @"Result image browser text display string");
		_fileCountString = [NSString stringWithFormat:fmt, fileCount, [NSString mgs_stringFromFileSize:[_attachments validatedLength]]];
	} else {
		fmt = NSLocalizedString(@"%i files", @"Result image browser text display string");
		_fileCountString = [NSString stringWithFormat:fmt, fileCount];
		enableControls = NO;;
	}
	
	// enable controls
	[_slider setEnabled:enableControls];
	[_quicklook setEnabled:enableControls];
	
	[self didChangeValueForKey:KeyPath_FileCountString];
}

/*
 
 zoom change
 
 */
- (IBAction)zoomChange:(id)sender
{
	#pragma unused(sender)
	
	//[_imageBrowser setZoomValue:[_slider floatValue]];
}

#pragma mark -
#pragma mark NSView delegate methods

/*
 
 view did move to window
 
 */
- (void)view:(NSView *)aView didMoveToWindow:(NSWindow *)aWindow
{
	if (aWindow && aView == _imageBrowser) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:aWindow]; 
	}
	
}

/*
 
 - windowWillClose:
 
 */
- (void)windowWillClose:(NSNotification *)aNote
{
#pragma unused(aNote)
/*
 
 The following gets logged when closing a window containing:
 
 Mon Dec 13 21:50:54 master-mini.local KosmicTask[15476] <Error>: kCGErrorInvalidConnection: CGSGetSurfaceBounds: Invalid connection
 Mon Dec 13 21:50:54 master-mini.local KosmicTask[15476] <Error>: kCGErrorFailure: Set a breakpoint @ CGErrorBreakpoint() to catch errors as they are logged.
 Mon Dec 13 21:50:54 master-mini.local KosmicTask[15476] <Error>: kCGErrorInvalidConnection: CGSGetSurfaceBounds: Invalid connection
 
 This is generated by IKImageView when the window closes.
 Removing it form the superview seems to help.
 
 */
	
	[_imageBrowser removeFromSuperview];
}

#pragma mark -
#pragma mark drag n drop 

// -------------------------------------------------------------------------
//	draggingEntered:sender
// ------------------------------------------------------------------------- 
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	#pragma unused(sender)
	
    return NSDragOperationCopy;
}

// -------------------------------------------------------------------------
//	draggingUpdated:sender
// ------------------------------------------------------------------------- 
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	#pragma unused(sender)
	
    return NSDragOperationCopy;
}

// -------------------------------------------------------------------------
//	performDragOperation:sender
// ------------------------------------------------------------------------- 
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSData*			data = nil;
    NSPasteboard*	pasteboard = [sender draggingPasteboard];
	
	// Look for paths on the pasteboard.
    if ([[pasteboard types] containsObject:NSFilenamesPboardType]) 
        data = [pasteboard dataForType:NSFilenamesPboardType];
	
    if (data)
	{
		/*
		NSString* errorDescription;
		
		// Retrieve  paths.
        NSArray* filenames = [NSPropertyListSerialization propertyListFromData:data 
															  mutabilityOption:kCFPropertyListImmutable 
																		format:nil 
															  errorDescription:&errorDescription];
		
		// Add paths to the data source.
        NSInteger i, n;
        n = [filenames count];
        for (i = 0; i < n; i++)
		{
            [self addAnImageWithPath:[filenames objectAtIndex:i]];
        }
		
		// Make the image browser reload the data source.
        [self updateDatasource];
	 */
    }
	
	// Accept the drag operation.
	return YES;
}
@end
