//
//  MGSFolderPathParameterInputViewController.m
//  KosmicTask
//
//  Created by Jonathan on 18/07/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSMother.h"
#import "MGSFolderPathParameterInputViewController.h"
#import "MGSFolderPathParameterPlugin.h"
#import "NSString_Mugginsoft.h"

// class extension
@interface MGSFolderPathParameterInputViewController()
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation MGSFolderPathParameterInputViewController


@synthesize fileLabel = _fileLabel;

/*
 
 init  
 
 */
- (id)init
{
	self = [super initWithNibName:@"FolderPathParameterInputView"];
	if (self) {
		self.sendAsAttachment = NO;
		//self.fileLabel = @"File Content";
	}
	return self;
}




/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	
	// bind it
	[pathTextField bind:NSValueBinding toObject:self withKeyPath:@"parameterValue" options:[NSDictionary dictionaryWithObjectsAndKeys: [[pathTextField cell] placeholderString], NSNullPlaceholderBindingOption, nil]];
	
	[[pathTextField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
	
	// this will send viewDidLoad to delegate
	[super awakeFromNib];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	self.parameterValue = [self.plist objectForKey:MGSKeyFolderPath withDefault:@""];
	
	self.label = NSLocalizedString(@"Input is required", @"label text");
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
	
	[op setTitle:NSLocalizedString(@"Select folder", @"Parameter folder selection prompt")];
	[op setPrompt:NSLocalizedString(@"Select", @"Parameter folder select button text")];
	
	
	/* display the NSOpenPanel */
	[op beginSheetForDirectory:[op directory] 
						  file:nil 
						 types: nil
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
	if (0 == [[sheet URLs] count]) return;
	NSURL *url = [[sheet URLs] objectAtIndex:0];
	self.parameterValue = [url path];
}

/*
 
 is valid
 
 */
- (BOOL)isValid
{
	// parameter value must be defined
	if (!self.parameterValue || [self.parameterValue isEqual:@""]) {
		self.validationString = NSLocalizedString(@"Please select a folder.", @"Validation string - no folder selected");
		return NO;
	}
	
	// folder must exist ?
	if (![[NSFileManager defaultManager] fileExistsAtPath:self.parameterValue] && NO) {
		NSString *fmt = NSLocalizedString(@"Folder %@ does not exist. Please select another folder.", @"Validation string - selected folder does not exist");
		self.validationString = [NSString stringWithFormat:fmt, self.parameterValue];
		
		return NO;
	}
	
	return YES;
}
@end

