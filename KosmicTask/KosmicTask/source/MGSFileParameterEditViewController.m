//
//  MGSFileParameterEditViewController.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSFileParameterPlugin.h"
#import "MGSFileParameterEditViewController.h"

// class extension
@interface MGSFileParameterEditViewController()
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation MGSFileParameterEditViewController

@synthesize useFileExtensions = _useFileExtensions;
@synthesize fileExtensions = _fileExtensions;
@synthesize filePath = _filePath;

/*
 
 init  
 
 */
- (id)init
{
	if ([super initWithNibName:@"FileParameterEditView"]) {
		self.parameterDescription = NSLocalizedString(@"Select file. File content will be sent to the task.", @"File selection prompt");
	}
	return self;
}



/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	[fileExtensionsTextField bind:NSValueBinding toObject:self withKeyPath:@"fileExtensions" options:[NSDictionary dictionaryWithObjectsAndKeys: @"ext1 ext2 ext3 ...", NSNullPlaceholderBindingOption, nil]];
	[fileNameTextField bind:NSValueBinding toObject:self withKeyPath:@"filePath" options:[NSDictionary dictionaryWithObjectsAndKeys: @"no file selected", NSNullPlaceholderBindingOption, nil]];
	[useRequiredFileExtensionCheckbox bind:NSValueBinding toObject:self withKeyPath:@"useFileExtensions" options:nil];
	
	[[fileNameTextField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
	
	// this will send viewDidLoad to delegate
	[super awakeFromNib];
}

/*
 
 - setFileExtensions:
 
 */
- (void)setFileExtensions:(NSString *)aString
{
	if (!aString) aString = @"";
	_fileExtensions = aString;
}
/*
 
 update plist
 
 */
- (void)updatePlist
{
	[self.plist setObject:[NSNumber numberWithBool:self.useFileExtensions] forKey:MGSKeyUseFileExtensions];
	[self.plist setObject:self.fileExtensions forKey:MGSKeyFileExtensions];
	[self.plist setObject: (self.filePath ? self.filePath : @"") forKey:MGSKeyFilePath];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	self.useFileExtensions = [[self.plist objectForKey:MGSKeyUseFileExtensions withDefault:[NSNumber numberWithBool:NSOffState]] boolValue];
	self.fileExtensions = [self.plist objectForKey:MGSKeyFileExtensions withDefault:@""];
	self.filePath = [self.plist objectForKey:MGSKeyFilePath withDefault:@""];
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
	[op setCanChooseDirectories:NO];
	[op setCanChooseFiles:YES];
	[op setAllowsMultipleSelection:NO];
	[op setDelegate:self];
	
	// set file types if required
	//NSArray *fileTypes = [self allowedFileTypes];
	NSArray *fileTypes = nil;
	
	[op setTitle:NSLocalizedString(@"Select file", @"Parameter file selection prompt")];
	[op setPrompt:NSLocalizedString(@"Select", @"Parameter file select button text")];
	
	
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
	
	// get filename
	if (0 == [[sheet filenames] count]) return;
	self.filePath = [[sheet filenames] objectAtIndex:0];
}

@end
