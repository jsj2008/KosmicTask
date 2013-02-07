//
//  MGSResourceBrowserSheetController.m
//  KosmicTask
//
//  Created by Jonathan on 12/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSResourceBrowserSheetController.h"
#import "MGSLanguageTemplateResource.h"
#import "MGSLanguageCodeDescriptor.h"

// class extension
@interface MGSResourceBrowserSheetController()
- (void)closeSheet:(NSInteger)returnCode;
- (void)copySelectionToPasteBoard;
@property (copy) MGSLanguagePropertyManager *languagePropertyManager;
@end

const char MGSContextRequiredResourceDoubleClicked;
const char MGSContextResourcesChanged;

@implementation MGSResourceBrowserSheetController

@synthesize resourceBrowserViewController, resourceText, resourcesChanged, languagePropertyManager, script;

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self = [super initWithWindowNibName:@"ResourceBrowserSheet"];
	}
	
	return self;
}

/*
 
 - awakeFromNib
 
 */
- (void)awakeFromNib
{
	// load the template view
	resourceBrowserViewController = [[MGSResourceBrowserViewController alloc] init];	
	[resourceBrowserViewController view];
	resourceBrowserViewController.requiredResourceClass = [MGSLanguageTemplateResource class];
	resourceBrowserViewController.editable = NO;
	[resourceBrowserViewController buildResourceTree];


	// bindings
	[okButton bind:NSEnabledBinding toObject:self withKeyPath:@"resourceBrowserViewController.requiredResourceSelected" options:nil];
	 
	// update the templateView
	[[resourceBrowserViewController view] setFrame:[templateView frame]];
	[[templateView superview] replaceSubview:templateView with:[resourceBrowserViewController view]];
	templateView = [resourceBrowserViewController view];
	
	// KVO
	[resourceBrowserViewController addObserver:self forKeyPath:@"requiredResourceDoubleClicked" options:0 context:(void *)&MGSContextRequiredResourceDoubleClicked];
	[resourceBrowserViewController addObserver:self forKeyPath:@"documentEdited" options:0 context:(void *)&MGSContextResourcesChanged];

	// restore view frames
	NSDictionary *viewDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
								  MGSSheetResourceBrowserOutlineSplitViewFrames, @"MainSplitView",
								  MGSSheetResourceBrowserTableSplitViewFrames, @"ResourceSplitView", nil];
	[resourceBrowserViewController setViewFrameDefaults:viewDefaults];
	
}

#pragma mark -
#pragma mark KVO

/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
	
	if (context == (void *)&MGSContextRequiredResourceDoubleClicked) {
		[self insertTemplateAction:self];
	} else if (context == (void *)&MGSContextResourcesChanged) {
		self.resourcesChanged = YES;
	}
}

#pragma mark -
#pragma mark Accessors

/*
 
 - setScript:
 
 */
- (void)setScript:(MGSScript *)theScript
{
    script = theScript;
    resourceBrowserViewController.script = theScript;
    resourceBrowserViewController.defaultScriptType = theScript.scriptType;
}

#pragma mark -
#pragma mark Text selection handling
/*
 
 - copySelectionToPasteBoard
 
 */
- (void)copySelectionToPasteBoard
{
    NSString *text = self.resourceBrowserViewController.scriptString;
    if (text) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:text forType:NSStringPboardType];
    }
}
#pragma mark -
#pragma mark Actions

/*
 
 - insertTemplateAction:
 
 */
- (IBAction)insertTemplateAction:(id)sender
{
#pragma unused(sender)
    [self copySelectionToPasteBoard];
    resourceText = self.resourceBrowserViewController.scriptString;
	[self closeSheet:kMGSResourceBrowserSheetReturnInsert];
}

/*
 
 - cancel:
 
 */
- (IBAction)cancel:(id)sender
{
#pragma unused(sender)
	[self closeSheet:kMGSResourceBrowserSheetReturnCancel];
}

/*
 
 - copyToPasteboardAction:
 
 */
- (IBAction)copyToPasteboardAction:(id)sender
{
#pragma unused(sender)
    [self copySelectionToPasteBoard];
	[self closeSheet:kMGSResourceBrowserSheetReturnCopy];    
}
/*
 
 - openFile:
 
 */
- (IBAction)openFile:(id)sender
{
#pragma unused(sender)
	[self closeSheet:kMGSResourceBrowserSheetReturnShowFile];
}

/*
 
 - openCodeAssistantAction:
 
 */
- (IBAction)openCodeAssistantAction:(id)sender
{
#pragma unused(sender)
	[self closeSheet:kMGSResourceBrowserSheetReturnShowCodeAssistant];
}

/*
 
 - closeSheet:
 
 */
- (void)closeSheet:(NSInteger)returnCode
{
	[resourceBrowserViewController saveViewState];
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:returnCode];
}
@end
