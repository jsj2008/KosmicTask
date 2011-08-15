//
//  MGSFolderPathParameterEditViewController.m
//  KosmicTask
//
//  Created by Jonathan on 18/07/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSFolderPathParameterPlugin.h"
#import "MGSFolderPathParameterEditViewController.h"

// class extension
@interface MGSFolderPathParameterEditViewController()
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation MGSFolderPathParameterEditViewController

@synthesize folderPath = _folderPath;

/*
 
 init  
 
 */
- (id)init
{
	if ([super initWithNibName:@"FolderPathParameterEditView"]) {
		self.parameterDescription = NSLocalizedString(@"Select folder. Folder path will be sent to the task.", @"Parameter folder selection prompt");
	}
	return self;
}



/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	[pathTextField bind:NSValueBinding toObject:self withKeyPath:@"folderPath" options:[NSDictionary dictionaryWithObjectsAndKeys: @"no folder selected", NSNullPlaceholderBindingOption, nil]];	
	[[pathTextField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
	
	// this will send viewDidLoad to delegate
	[super awakeFromNib];
}

/*
 
 update plist
 
 */
- (void)updatePlist
{
	[self.plist setObject: (self.folderPath ? self.folderPath : @"") forKey:MGSKeyFolderPath];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	self.folderPath = [self.plist objectForKey:MGSKeyFolderPath withDefault:@""];
}

/*
 
 - selectFile:
 
 http://developer.apple.com/mac/library/documentation/cocoa/conceptual/AppFileMgmt/Tasks/UsingAnOpenPanel.html
 
 */
- (IBAction)selectFile:(id)sender
{
#pragma unused(sender)
	
	NSOpenPanel *op = [NSOpenPanel openPanel];
	
	// configure panel
	[op setCanChooseDirectories:YES];
	[op setCanChooseFiles:NO];
	[op setAllowsMultipleSelection:NO];
	[op setDelegate:self];
	
	// set file types if required
	//NSArray *fileTypes = [self allowedFileTypes];
	NSArray *fileTypes = nil;
	
	[op setTitle:NSLocalizedString(@"Select folder", @"Parameter folder selection prompt")];
	[op setPrompt:NSLocalizedString(@"Select", @"Parameter folder select button text")];
	
	
	/* display the NSOpenPanel */
	[op beginSheetForDirectory:[op directory] 
						  file:nil 
						 types: fileTypes
				modalForWindow:[[self view] window] 
				 modalDelegate:self 
				didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
				   contextInfo:nil];
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
	
	// get folder
	if (0 == [[sheet URLs] count]) return;
	NSURL *url = [[sheet URLs] objectAtIndex:0];
	self.folderPath = [url path];
}

@end
