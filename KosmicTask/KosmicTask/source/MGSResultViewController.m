//
//  MGSResultViewController.m
//  Mother
//
//  Created by Jonathan on 06/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSResultViewController.h"
#import "MGSResult.h"
#import "MGSError.h"
#import "MGSNumberTransformer.h"
#import "MGSKeyImageAndText.h"
#import "MGSImageManager.h"
#import "MGSMotherModes.h"
#import "PlacardScrollView.h"
#import "MGSExportPluginController.h"
#import "MGSExportPlugin.h"
#import "MGSAppController.h"
#import "MGSTaskSpecifier.h"
#import "MGSSendPluginController.h"
#import "MGSSendPlugin.h"
#import "MGSImageBrowserViewController.h"
#import "NSTextView_Mugginsoft.h"
#import "NSString_Mugginsoft.h"
#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import "MarkerLineNumberView.h"
#import "MGSImageBrowserView.h"
#import "MGSNetAttachments.h"
#import "MGSApplicationMenu.h"
#import "MGSNotifications.h"
#import "NSObject_Mugginsoft.h"
#import "MGSPreferences.h"
#import "MGSScriptViewController.h"
#import "NSView_Mugginsoft.h"

#import <ORCDiscount/ORCDiscount.h>

NSString *MGSKeyResult = @"result";
static BOOL applicationMenuConfigured = NO;

// class extension
@interface MGSResultViewController()
- (void)setResultTreeArray:(NSArray *)anArray;
- (void)sendResult:(id)sender;
- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
@end

@interface MGSResultViewController(Private)
- (MGSExportPlugin *)selectedExportPlugin;
- (void)buildMenus;
- (MGSExportPlugin *)selectedDisplayPlugin;
- (void)displayFormat:(id)sender;
@end

@implementation MGSResultViewController

@synthesize titleImage = _titleImage;
@synthesize result = _result;
@synthesize resultDictionary = _resultDictionary;
@synthesize resultTreeArray = _resultTreeArray;
@synthesize dragThumbView = _dragThumbView;
@synthesize viewMode = _viewMode;
@synthesize resultMenu = _resultMenu;
@synthesize resultString = _resultString;
@synthesize resultLogString = _resultLogString;
@synthesize openFileAfterSave = _openFileAfterSave;

#pragma mark Instance handling
/*
 
 init
 
 */
- (id)initWithDelegate:(id)delegate
{
	if ([super initWithNibName:@"ResultView" bundle:nil]) {
		[super setDelegate:delegate];
		_result = nil;
		_nibLoaded = NO;
		_resultTreeArray = nil;
		_resultString = nil;
		_openFileAfterSave = NO;
	}
	return self;
}
- (id)init
{
	return [self initWithDelegate:nil];
}

/*
 
 finalize
 
 */
- (void)finalize
{
#ifdef MGS_LOG_FINALIZE
	MLog(MEMORYLOG, @"finalized");
#endif
    
	[super finalize];
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{	
	if (_nibLoaded) {
		return;
	}

	// set up bindings

	//=======================================================================================
	// bind text view to result string
	//
	// note that we enable editing even though we don't store the edits back into the result.
	//
    //=======================================================================================
	[_textView mgs_setLineWrap:YES];
	// glyph generation crash was occurring when 2MB text loaded into two textviews in
	// two separate windows.
	// crash was occurring during background layout.
	// if issue reoccurs try disabling garbage collection during layout 
	// see MID:572
	[[_textView layoutManager] setBackgroundLayoutEnabled:YES];
	[[_textView layoutManager] setAllowsNonContiguousLayout:YES];
	
	[_textView bind:NSAttributedStringBinding 
		   toObject:self 
		withKeyPath:@"resultString" 
			options:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSConditionallySetsEditableBindingOption, nil]];
	
    if ([_textView respondsToSelector:@selector(setUsesFindBar:)]) {
        [_textView setUsesFindBar:YES];
    } else {
        [_textView setUsesFindPanel:YES];        
    }
    //=======================================================================================
    //
    // bind logtext view to result log string
    //
    //=======================================================================================
    [_logTextView mgs_setLineWrap:YES];
	[[_logTextView layoutManager] setBackgroundLayoutEnabled:YES];
	[[_logTextView layoutManager] setAllowsNonContiguousLayout:YES];
	
	[_logTextView bind:NSAttributedStringBinding 
		   toObject:self 
		withKeyPath:@"resultLogString" 
			options:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:NO], NSConditionallySetsEditableBindingOption, nil]];
    
    if ([_logTextView respondsToSelector:@selector(setUsesFindBar:)]) {
        [_logTextView setUsesFindBar:YES];
    } else {
        [_logTextView setUsesFindPanel:YES];
    }
    
	//=======================================================================================
	// bind treecontroller to outline view
	//
	// note that we could bind directly to result.resultString etc rather than to self.resultString etc.
	// the extra level of redirection may come in handy
	//=======================================================================================
	_treeController = [[NSTreeController alloc] init];
	[_treeController setChildrenKeyPath:@"childNodes"];
	
	[_outlineView bind:@"selectionIndexPaths" toObject:_treeController withKeyPath:@"selection.selectionIndexPaths" options:nil];	
	[[_outlineView tableColumnWithIdentifier:@"key"] bind:@"value" toObject:_treeController withKeyPath:@"arrangedObjects.representedObject.key" options:nil];
	//
	// cell for value column has been subclassed
	// We need to pass in more than just a string (ie: the text and the image).
	// So pass in the represented object itself.
	// And in the subclassed cell set override - (void)setObjectValue:(id)value to parse
	// the value object from the text and image properties which are then set within the cell.
	//
	[[_outlineView tableColumnWithIdentifier:@"value"] bind:@"value" toObject:_treeController withKeyPath:@"arrangedObjects.representedObject" options:nil];
	
	//=======================================================================================
	// image browser view
	//=======================================================================================
	_imageBrowserViewController = [MGSImageBrowserViewController new];
	[_imageBrowserViewController view];	// load it
	NSTabViewItem *item = [_tabView tabViewItemAtIndex:kMGSMotherResultViewIcon];
	[item setView:[_imageBrowserViewController view]];
	
	
	//
	// set additional drag views for splitview
	// scrollview is subclass PlacardScrollView
	// outline placard
	NSView *scrollView= [_outlineView enclosingScrollView];
	if ([scrollView isKindOfClass:[PlacardScrollView class]]) {
		[(PlacardScrollView *)scrollView setSide:PlacardRightCorner];
	}
	
	// textview placard
	scrollView= [_textView enclosingScrollView];
	if ([scrollView isKindOfClass:[PlacardScrollView class]]) {
		[(PlacardScrollView *)scrollView setSide:PlacardRightCorner];
	}
	
    // log textview placard
	scrollView = [_logTextView enclosingScrollView];
	if ([scrollView isKindOfClass:[PlacardScrollView class]]) {
		[(PlacardScrollView *)scrollView setSide:PlacardRightCorner];
	}

	// build required menus
	[self buildMenus];

	// set action popup menu
	[_actionGearPopupButton setMenu:[self resultMenu]];

	// set image browser menu
	_imageBrowserViewController.menu = [self resultMenu];
	
	// footer
	//[[_resultFooterContentTextField cell] setBackgroundStyle: NSBackgroundStyleRaised];
	[[_resultFooterContentTextField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
	
	_nibLoaded = YES;
	
}

#pragma mark -
#pragma mark Result handling

/*
 
 set result
 
 */
- (void)setResult:(MGSResult *)aResult
{
	_result = aResult;

	// assign result tree array
	self.resultTreeArray = _result.resultTreeArray;
	
	// assign attachments to image browser
	_imageBrowserViewController.attachments = _result.attachments;

	// assign result script string
	//self.resultScriptString = _result.resultScriptString;

    // assign result log string
	self.resultLogString = _result.resultLogString;
    
	// result dictionary is an alias for the object
	self.resultDictionary = _result.object;
	
	// set text display format
	[self displayFormat:self];
	
	NSString *footerText = [NSString stringWithFormat:NSLocalizedString(@"Text: %@", @"Result view text footer text"), [NSString mgs_stringFromFileSize:[self.result.resultString length]]];
	footerText = [NSString stringWithFormat:NSLocalizedString(@"%@    Files: %i files, %@",  @"Result view files footer text"), footerText, [self.result.attachments count], [NSString mgs_stringFromFileSize:[self.result.attachments validatedLength]]];
	[_resultFooterContentTextField setStringValue:footerText];

}

/*
 
 set result tree array
 
 */
- (void)setResultTreeArray:(NSArray *)anArray
{
	// assign result tree array
	// binding the tree controller content to the result tree array
	// causes real performance issues.	
	[_treeController setContent:nil];	
	_resultTreeArray = anArray;
	[_treeController setContent:_resultTreeArray];
	
	// expand all rows
	// seems to cause performance issue.
	if (NO) {
		int nRows = [_outlineView numberOfRows];
		for (int i = nRows-1 ; i >= 0; i --) {
			if ([_outlineView isExpandable:[_outlineView itemAtRow:i]]) {
				[_outlineView expandItem:[_outlineView itemAtRow:i] expandChildren:YES];
			}
		}
	}
	
}

/*
 
 set result string
 
 */
- (void)setResultString:(NSAttributedString *)aString
{
	[[_textView undoManager] removeAllActions];
	[[_textView undoManager] disableUndoRegistration];
	_resultString = aString;
	[[_textView undoManager] enableUndoRegistration];
}
/*
 
 set result log
 
 */
- (void)setResultLogString:(NSAttributedString *)aString
{
	[[_logTextView undoManager] removeAllActions];
	[[_logTextView undoManager] disableUndoRegistration];
	_resultLogString = aString;
	[[_logTextView undoManager] enableUndoRegistration];
}

/*
 
 save result text view
 
 */
- (NSTextView *)saveResultTextView
{
	// get save NSTextView
	NSTextView *saveTextView = nil;
	switch (_viewMode) {
			
			// string result
		case kMGSMotherResultViewDocument:
		case kMGSMotherResultViewList:
			saveTextView = _textView;
			break;
		
        case kMGSMotherResultViewLog:
			saveTextView = _logTextView;
			break;
			
			//nothing to save
		default:
			break;
	}
	
	return saveTextView;
}

/*
 
 save result string
 
 */
- (NSAttributedString *)saveResultString
{
	// get save string
	NSAttributedString *saveString = nil;
	switch (_viewMode) {
			
			// string result
		case kMGSMotherResultViewDocument:
		case kMGSMotherResultViewList:
			saveString = self.resultString;
			break;
        
        case kMGSMotherResultViewLog:
			saveString = self.resultLogString;
			break;
            
			//nothing to save
		default:
			break;
	}
	
	return saveString;
}

#pragma mark -
#pragma mark Result NSTextView handling

/*
 
 - toggleLineWrapping
 
 */
- (IBAction)toggleLineWrapping:(id)sender
{
#pragma unused(sender)
	NSResponder *responder = [[[self view] window] firstResponder];
	if ([responder respondsToSelector:@selector(mgs_toggleLineWrapping:)]) {
		[(NSTextView *)responder mgs_toggleLineWrapping:sender];		
	}
}

#pragma mark -
#pragma mark View mode handling
/*
 
 set the view mode
 
 */
- (void)setViewMode:(eMGSMotherResultView)mode
{
    NSAssert(mode >= kMGSMotherResultViewFirst && mode <= kMGSMotherResultViewLast, @"Invalid view mode");
    
	_viewMode = mode;	
	eMGSMotherViewConfig viewConfig = [self viewConfig];
	
	// select our view
	[_tabView selectTabViewItemAtIndex:mode];
	
	// set image
	[self setViewModeImage:[[_viewModeSegmentedControl imageForSegment:mode] copy]];
	
	// the result retains its view mode so that when a result
	// is restored to view it previous view mode can be instated
	self.result.viewMode = _viewMode;
	
	// post view config did change note
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInteger:viewConfig], MGSNoteViewConfigKey,
						  [NSNumber numberWithInteger:kMGSViewStateShow], MGSNoteViewStateKey,
						  nil];
	NSNotification *noteDone = [NSNotification notificationWithName:MGSNoteViewConfigDidChange 
															 object:[[self view] window]
														   userInfo:dict];
	[[NSNotificationCenter defaultCenter] postNotification:noteDone];
}

/*
 
 view configuration
 
 */
- (eMGSMotherViewConfig)viewConfig
{
	eMGSMotherViewConfig viewConfig = kMGSMotherViewConfigDocument;
	
	switch (_viewMode) {
		case kMGSMotherResultViewList:
			viewConfig = kMGSMotherViewConfigList;
			break;
			
		case kMGSMotherResultViewDocument:
			viewConfig = kMGSMotherViewConfigDocument;
			break;
			
		case kMGSMotherResultViewIcon:
			viewConfig = kMGSMotherViewConfigIcon;
			break;

        case kMGSMotherResultViewLog:
			viewConfig = kMGSMotherViewConfigLog;
			break;

		default:
			NSAssert(NO, @"bad view mode");
			break;
			
	}
	
	return viewConfig;
}
/*
 
 set the view mode image
 
 */
- (void)setViewModeImage:(NSImage *)image
{
	[_viewModeImageButton setImage:[image copy]];
}

/*
 
 show next view mode
 
 */
- (IBAction)showNextViewMode:(id)sender
{
	#pragma unused(sender)
	
	eMGSMotherResultView mode = kMGSMotherResultViewFirst;
	if (_viewMode < kMGSMotherResultViewLast) {
		mode = _viewMode + 1;
	}
	[self setViewMode:mode];
}

/*
 
 show prev view mode
 
 */
- (IBAction)showPrevViewMode:(id)sender
{
	#pragma unused(sender)
	
	eMGSMotherResultView mode = kMGSMotherResultViewLast;
	if (_viewMode > 0) {
		mode = _viewMode - 1;
	}
	[self setViewMode:mode];
}

/* 
 
 get the view containing the active control
 
 */
- (NSView *)viewControl
{
	NSView *view = nil;
	
	switch (_viewMode) {
		case kMGSMotherResultViewList:
			view = _outlineView;
			break;
			
		case kMGSMotherResultViewDocument:
			view = _textView;
			break;
			
		case kMGSMotherResultViewIcon:
			view = [_imageBrowserViewController imageBrowser];
			break;

        case kMGSMotherResultViewLog:
			view = _logTextView;
			break;

		default:
			NSAssert(NO, @"bad view");
			break;
			
	}
	
	return view;
}

#pragma mark Window handling
/*
 
 detach result as window
 
 */
- (IBAction)detachResultAsWindow:(id)sender
{
	if ([[self delegate] respondsToSelector:_cmd]) {
		[[self delegate] performSelector:_cmd withObject:sender];
	}
}

#pragma mark Menu handling
/*
 
 view menu view as selected
 
 this will probably be sent from the result view controller.
 it is not best placed to handle this due to the amount of view
 syncronisation that is required
 
 */
- (IBAction)viewMenuViewAsSelected:(id)sender
{
	eMGSMotherResultView viewMode = kMGSMotherResultViewDocument;
	
	if (![sender isKindOfClass:[NSMenuItem class]]) return;
	NSMenuItem *menu = sender;
	
	switch ([menu tag]) {
		case kMGS_MENU_TAG_VIEW_DOCUMENT:
			viewMode = kMGSMotherResultViewDocument; 
			break;
			
		case kMGS_MENU_TAG_VIEW_ICON:
			viewMode = kMGSMotherResultViewIcon; 
			break;
			
		case kMGS_MENU_TAG_VIEW_LIST:
			viewMode = kMGSMotherResultViewList; 
			break;

        case kMGS_MENU_TAG_VIEW_LOG:
			viewMode = kMGSMotherResultViewLog; 
            break;
			
		default:
			NSAssert(NO, @"invalid View as menu tag");
			return;
	}
	
	[self setViewMode:viewMode];
}

/*
 
 validate menu item
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL theAction = [menuItem action];
	NSCellStateValue state = NSOffState;
	
	if (![[self view] superview]) {
		return NO;
	}
	
	// send result 
	if (theAction == @selector(sendResult:)) {
		
		// at present cannot send images anywhere
		if (_viewMode == kMGSMotherResultViewIcon) {
			return NO;
		}
		
		return YES;			
	}
		
	// save result
	else if (theAction == @selector(saveResult:)) {
		
		// save result files
		if (_viewMode == kMGSMotherResultViewIcon) {
			return [[_imageBrowserViewController imageBrowser] validateMenuItem:menuItem];
		} 
		
		[menuItem setTitle:NSLocalizedString(@"Save As...", @"Menu save as")];
		
		return YES;
	}
	
	// quicklook
	else if (theAction == @selector(quicklook:)) {
		
		// tried sending quicklook up the responder chain but didn't work.
		// so sent it here instead
		if (_viewMode != kMGSMotherResultViewIcon) {
			[menuItem setTitle:NSLocalizedString(@"Quick Look", @"Quick look menu item")];
			return NO;
		}

		return [[_imageBrowserViewController imageBrowser] validateMenuItem:menuItem];
	}
	
	// detach result as window
	else if (theAction == @selector(detachResultAsWindow:)) {
		return self.result ? YES : NO;
	}
	
	// view menu view as
	else if (theAction == @selector(viewMenuViewAsSelected:)) {
		
		if (self.result) {
			switch ([menuItem tag]) {
				case kMGS_MENU_TAG_VIEW_DOCUMENT:
					if (_viewMode == kMGSMotherResultViewDocument) state = NSOnState; 
					break;
					
				case kMGS_MENU_TAG_VIEW_ICON:
					if (_viewMode == kMGSMotherResultViewIcon) state = NSOnState; 
					break;
					
				case kMGS_MENU_TAG_VIEW_LIST:
					if (_viewMode == kMGSMotherResultViewList) state = NSOnState; 
					break;
					
                case kMGS_MENU_TAG_VIEW_LOG:
					if (_viewMode == kMGSMotherResultViewLog) state = NSOnState; 
					break;

				default:
					NSAssert(NO, @"invalid View as menu tag");
			}
		}
		[menuItem setState:state];
		return self.result ? YES : NO;
	}
	
	return YES;
}



#pragma mark Saving and Sending

/*
 
 quick look
 
 */
- (IBAction)quicklook:(id)sender
{
	[_imageBrowserViewController quicklook:sender];
}

/*
 
 save the result
 
 */
- (IBAction)saveResult:(id)sender
{
	#pragma unused(sender)
	
	// save result files in icon view
	if (_viewMode == kMGSMotherResultViewIcon) {
		return [self saveResultFiles:sender];
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
	[savePanel setAccessoryView: _savePanelAccessoryView];	// add our custom view
	//[savePanel setRequiredFileType: @"txt"];
	//[savePanel setNameFieldLabel:NSLocalizedString(@"Save Result As:", @"Save result panel label")];	// string truncated in panel
	
	NSString *fileName = [_result.action nameWithHostPrefix];
	if (!fileName) fileName = @""; 
	
	/* display the NSSavePanel */
	[savePanel beginSheetForDirectory:[savePanel directory] file:fileName 
					   modalForWindow:[[self view] window] 
						modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) 
						  contextInfo:nil];
}

/*
 
 save the result files
 
 */
- (IBAction)saveResultFiles:(id)sender
{
	#pragma unused(sender)
	
	// saving of files currently only works correctly if icon view displayed
	[self setViewMode:kMGSMotherResultViewIcon];
	
	[_imageBrowserViewController save:self];
}

/*
 
 send the result
 
 */
- (void)sendResult:(id)sender
{
	
	if (![sender respondsToSelector:@selector(representedObject)]) {
		return;
	}
	
	id representedObject = [sender representedObject];
	
	// attempt to send
	if ([representedObject respondsToSelector:@selector(sendAttributedString:)]) {
		[representedObject sendAttributedString: [self saveResultString]];
	/*} else if ([representedObject respondsToSelector:@selector(sendFormattedAttributedString:)]) {
		[representedObject sendFormattedAttributedString: [self saveResultString]];*/
	} else {
		[MGSError clientCode:MGSErrorCodeSendPlugin reason:NSLocalizedString(@"Invalid plugin", @"Plugin error message")];
	}
}

#pragma mark NSSplitView handling
/*
 
 Set the splitview drag thumb view
 
 */
- (void)setDragThumbView:(NSView *)view
{
	_dragThumbView = view;
}

/*
 
 additional dragging rect for splitview
 
 */
- (NSView *)splitViewAdditionalView
{
	// this is a bit klutzy due to the fact that we are switching views via NSTabView.
	// it could have been done by simply replacing the scrollview document view!
	NSView *activeView = [self viewControl];


    NSView *scrollView = [activeView enclosingScrollView];
	
	//while ([scrollView isKindOfClass:[NSScrollView class]] == NO && scrollView != [self view]) {
		//scrollView = [scrollView superview];	// clipview then scrollview
	//}
	
	
	//NSView *scrollView= [[activeView superview] superview];	// clipview then scrollview
	
	if ([scrollView isKindOfClass:[PlacardScrollView class]]) {
		
		// specify drag thumb for text view as only part of placard is thumb
		if (activeView == _textView) {
			return _textViewDragThumb;
		}
		
		if (activeView == [_imageBrowserViewController imageBrowser]) {
			return [_imageBrowserViewController splitViewAdditionalView];
		}
		return [(PlacardScrollView *)scrollView placard];
	}
	return nil;
}

#pragma mark Save dialog handling

/*
 
 save sheet did end
 
 saves text result or script text depending on mode
 
 */
- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	#pragma unused(contextInfo)
	
	if (NSCancelButton == returnCode) {
		return;
	}
	
	// get the currently selected export plugin
	MGSExportPlugin *plugin = [self selectedExportPlugin];
	if (!plugin) return;
	
	// get save path
	NSString *path = [sheet filename];
	NSString *fullPath = nil;
	
	// get save string and text view
	NSAttributedString *saveString = [self saveResultString];
	NSTextView *saveTextView = [self saveResultTextView];
		
	//
	// attempt to export
	//
	// export string
	if ([plugin respondsToSelector:@selector(exportString:toPath:)]) {
		fullPath = [plugin exportString:[saveString string] toPath:path];
	// export attributed string
	} else if ([plugin respondsToSelector:@selector(exportAttributedString:toPath:)]) {
		fullPath = [plugin exportAttributedString:saveString toPath:path];
	// export plist
	} else if ([plugin respondsToSelector:@selector(exportPlist:toPath:)]) {
		fullPath = [plugin exportPlist:_resultDictionary toPath:path];
	// export view
	} else if ([plugin respondsToSelector:@selector(exportView:toPath:)]) {
		fullPath = [plugin exportView:saveTextView toPath:path];		// export text view
	} else {
		[MGSError clientCode:MGSErrorCodeExportPlugin reason:NSLocalizedString(@"Invalid plugin", @"Plugin error message")];
		return;
	} 
	
	// fullPath is defined on success
	if (fullPath) {
		
		// open file with default app after save
		if (_openFileAfterSave) {
			[plugin openFileWithDefaultApplication:fullPath];
		}
	}
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
	
	MGSExportPlugin *plugin = [self selectedExportPlugin];
	if (!plugin) return filename;

	
	// add plugin extension to our selected filename.
	// note that if the returned file alreay exists the NSSavePanel will prompt to overwrite it.
	return [plugin completePath:filename];
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
	#pragma unused(path)
	#pragma unused(sender)
	
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
@end

@implementation MGSResultViewController(Private)
*/

#pragma mark -
#pragma mark Export handling
/*
 
 export the result in given format
 
 */
- (void)exportFormat:(id)sender
{
	#pragma unused(sender)
}

#pragma mark -
#pragma mark NSTextViewDelegate protocol
/*
 
 text view menu for event
 
 */

- (NSMenu *)textView:(NSTextView *)view menu:(NSMenu *)menu forEvent:(NSEvent *)event atIndex:(NSUInteger)charIndex
{
#pragma unused(view)
#pragma unused(event)
#pragma unused(charIndex)
	
	if (view == _textView) {
		// result menu can only be a submenu for 1 menu.
		// an internal consistency exception occurs otherwise
		[_resultMenu setSupermenu:nil];
		[_resultViewMenu setSupermenu:nil];
		
		[menu addItem:[NSMenuItem separatorItem]];
		NSMenuItem *results = [menu insertItemWithTitle:[_resultMenu title] action:nil keyEquivalent:@"" atIndex:[menu numberOfItems]];
		[menu setSubmenu:_resultMenu forItem:results];
		
		NSMenuItem *resultView = [menu addItemWithTitle:[_resultViewMenu title] action:nil keyEquivalent:@""];
		[menu setSubmenu:_resultViewMenu forItem:resultView];
	}
	
	return menu;
}

@end

@implementation MGSResultViewController(Private)

/*
 
 selected export plugin
 
 */
- (MGSExportPlugin *)selectedExportPlugin
{
	// represented object should be our plugin
	id item = [_saveFormatPopupButton selectedItem];
	if (![item respondsToSelector:@selector(representedObject)]) {
		return nil;
	}
	MGSExportPlugin *plugin = [item representedObject];
	if (![plugin isKindOfClass:[MGSExportPlugin class]]) {
		[MGSError clientCode:MGSErrorCodeExportPlugin reason:NSLocalizedString(@"Bad export plugin class", @"Plugin error message")];
		return nil;
	}
	
	return plugin;
}

/*
 
 selected display plugin
 
 */
- (MGSExportPlugin *)selectedDisplayPlugin
{
	// represented object should be our plugin
	id item = [_displayFormatPopupButton selectedItem];
	if (![item respondsToSelector:@selector(representedObject)]) {
		return nil;
	}
	MGSExportPlugin *plugin = [item representedObject];
	if (![plugin isKindOfClass:[MGSExportPlugin class]]) {
		[MGSError clientCode:MGSErrorCodeExportPlugin reason:NSLocalizedString(@"Bad export plugin class", @"Plugin error message")];
		return nil;
	}
	
	return plugin;
}

/*
 
 build menus for plugins
 
 */
- (void)buildMenus
{
	
	NSMenu *popupMenu = [[NSMenu alloc] initWithTitle:@"Format"];
	NSMenuItem *defaultMenuItem = nil;
	
	//
	// build the export menu 
	//
	MGSExportPluginController *exportPluginController = [[NSApp delegate] exportPluginController];
	for (id item in [exportPluginController instances]) {
		
		// sanity check on plugin class
		if ([item isKindOfClass:[MGSExportPlugin class]]) {
			MGSExportPlugin *exportPlugin = item;
			
			// create menu item
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[exportPlugin menuItemString] action:@selector(exportFormat:) keyEquivalent:@""];
			
			// represented object is our export plugin
			[menuItem setRepresentedObject:exportPlugin];
			
			// add item to popup menu
			[popupMenu addItem:menuItem];
			if ([exportPlugin isDefault]) {
				defaultMenuItem = menuItem;
			}			
		} else {
			MLog(DEBUGLOG, @"bad export plugin class");
		}
	}
	
	// set menu for popup
	[_saveFormatPopupButton setMenu:popupMenu];
	if (defaultMenuItem) {
		[_saveFormatPopupButton selectItem:defaultMenuItem];
	}

	//
	// build the display popup  menu 
	//
	popupMenu = [[NSMenu alloc] initWithTitle:@"Display"];
	defaultMenuItem = nil;
	for (id item in [exportPluginController instances]) {
		
		// sanity check on plugin class
		if ([item isKindOfClass:[MGSExportPlugin class]]) {
				MGSExportPlugin *exportPlugin = item;
				
			if ([exportPlugin respondsToSelector:@selector(displayMenuItemString)]) {
				NSString *menuString =  [exportPlugin displayMenuItemString];
				
				// create menu item
				NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuString action:@selector(displayFormat:) keyEquivalent:@""];
				[menuItem setTarget:self];
				
				// represented object is our export plugin
				[menuItem setRepresentedObject:exportPlugin];
				
				// add item to popup menu
				[popupMenu addItem:menuItem];
				if ([exportPlugin isDisplayDefault]) {
					defaultMenuItem = menuItem;
				}	
			}
		} else {
			MLog(DEBUGLOG, @"bad export plugin class");
		}
	}
	
	// set menu for popup
	[_displayFormatPopupButton setMenu:popupMenu];
	if (defaultMenuItem) {
		[_displayFormatPopupButton selectItem:defaultMenuItem];
	}
	
	//
	// build the send menu
	//
	MGSSendPluginController *sendPluginController = [[NSApp delegate] sendPluginController];
	for (id item in [sendPluginController instances]) {
		
		// sanity check on plugin class
		if ([item isKindOfClass:[MGSSendPlugin class]]) {
			MGSSendPlugin *sendPlugin = item;
			
			// create menu item
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[sendPlugin menuItemString] action:@selector(sendResult:) keyEquivalent:@""];
			[menuItem setTarget:self];
			
			// represented object is our send plugin
			[menuItem setRepresentedObject:sendPlugin];
			
			// disable menu item if target app not installed.
			// note that if menu is auto enabled then -setEnabled will have no effect.
			// if no target for mnu then it will automatically disbale itself
			if (![sendPlugin targetAppInstalled]) {
				[menuItem setAction:NULL];
			}
			
			// add item to send menu
			[_sendMenu addItem:menuItem];
		} else {
			MLog(DEBUGLOG, @"bad send plugin class");
		}
	}
	
	// application menu uses this menu item too
	if (!applicationMenuConfigured) {
		[(MGSAppController *)[NSApp delegate] setSendToMenu:[_sendMenu copy]];
		applicationMenuConfigured = YES;
	}
}

/*
 
 display the result in given format
 
 */
- (void)displayFormat:(id)sender
{
	#pragma unused(sender)
	
	// get the currently selected display plugin
	MGSExportPlugin *plugin = [self selectedDisplayPlugin];
	if (!plugin) return;
	
	NSData *data = nil;
	NSMutableAttributedString *resultString = nil;
	
	// attempt to display
	//
	// export plist as data
	if ([plugin respondsToSelector:@selector(exportPlistAsData:)]) {
		data = [plugin exportPlistAsData:_resultDictionary];
		if (data) {
			NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			if (stringData) {
				resultString = [[NSMutableAttributedString alloc] initWithString:stringData];
			}
		}
	}
	
	// if plugin cannot supply processed result use the default
	if (!resultString) {
		resultString = _result.resultString;
	}
	
	// set the result string
	self.resultString = resultString;
}


@end
