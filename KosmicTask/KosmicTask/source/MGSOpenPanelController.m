//
//  MGSOpenPanelController.m
//  KosmicTask
//
//  Created by Jonathan on 25/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSOpenPanelController.h"
#import "MGSScript.h"
#import "MGSNotifications.h"

/* class extension */
@interface MGSOpenPanelController()
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation MGSOpenPanelController

/*
 
 - openSourceFile:options:
 
 */
- (NSOpenPanel *)openSourceFile:(id)sender options:(NSDictionary *)options
{

	NSOpenPanel *op = [NSOpenPanel openPanel];
	
	window = [options objectForKey:@"window"];
	delegate = sender;
	
	// configure panel
	[op setCanChooseDirectories:NO];
	[op setCanChooseFiles:YES];
	[op setAllowsMultipleSelection:NO];
	[op setDelegate:self];
	
	// set accessory view
	if (!_openSourceFileAccessoryViewController) {
		_openSourceFileAccessoryViewController = [[MGSOpenSourceFileAccessoryViewController alloc] init];
	}
	[op setAccessoryView:[_openSourceFileAccessoryViewController view]];
	[_openSourceFileAccessoryViewController setScriptTypeForFile:nil];
	
	// text handling
	NSNumber *textHandling = [options objectForKey:@"textHandling"];
	if (textHandling && [textHandling respondsToSelector:@selector(integerValue)]) {
		_openSourceFileAccessoryViewController.selectedTextHandlingTag = [textHandling integerValue];
	}
	
	// text handling enabled
	NSNumber *textHandlingEnabled = [options objectForKey:@"textHandlingEnabled"];
	if (!textHandlingEnabled) {
		textHandlingEnabled = [NSNumber numberWithBool:YES];
	}
	_openSourceFileAccessoryViewController.textHandlingEnabled = [textHandlingEnabled boolValue];
	
	// set file types if required
	NSArray *fileTypes = nil;
	
	[op setTitle:NSLocalizedString(@"Select source text file", @"Open file selection prompt")];
	[op setPrompt:NSLocalizedString(@"Select", @"Open file select button text")];
	
	/* display the NSOpenPanel */
	[op beginSheetForDirectory:[op directory] 
						  file:nil 
						 types:fileTypes
				modalForWindow:window
				 modalDelegate:self 
				didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
				   contextInfo:nil];
	
	return op;
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
	
	// try and open it open it as a string
	NSStringEncoding encoding = NSASCIIStringEncoding;
	NSError *error = nil;
	NSString *source = [NSString stringWithContentsOfFile:filename usedEncoding:&encoding error:&error];
	
	// should not occur ...
	if (!source) {
		error = [NSError errorWithDomain:@"Open" code:0 userInfo:nil];
	}

	// check for error
	if (error) {
		NSString *alertMessage = NSLocalizedString(@"Cannot open file", @"file open sheet title");
		NSString *alertInfo = NSLocalizedString(@"The selected file could not be interpreted as text.", @"file open sheet info");
		NSAlert *alert = [NSAlert alertWithMessageText: alertMessage
										 defaultButton: nil
									   alternateButton: nil
										   otherButton: nil
							 informativeTextWithFormat: @"%@", alertInfo];
		
		//NSString *context = CFRetain(@"openFile");
		
		// run dialog
		[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
		return;
	}
	
	
	// create a new task with the selected source
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 source, @"source",
									 nil];
	
	// set a valid script type if available
	NSString *scriptType = [_openSourceFileAccessoryViewController scriptType];
	if (scriptType && [MGSScript validateScriptType:scriptType]) {
		[userInfo setObject:scriptType forKey:@"scriptType"];
	}
	
	// text handling
	NSNumber *textHandling = [NSNumber numberWithInteger:_openSourceFileAccessoryViewController.selectedTextHandlingTag];
	[userInfo setObject:textHandling forKey:@"textHandling"];
	
	// create task
	NSNotification *note = [NSNotification notificationWithName:MGSNoteOpenSourceFile object:self userInfo:userInfo];

	if (delegate && [delegate respondsToSelector:@selector(openPanelControllerDidClose:)]) {
		[delegate openPanelControllerDidClose:note];
	}
}

/*
 
 - alertDidEnd:returnCode:contextInfo:
 
 */
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
#pragma unused(alert)
#pragma unused(returnCode)
#pragma unused(contextInfo)
}

/*
 
 - panelSelectionDidChange:
 
 */
- (void)panelSelectionDidChange:(id)sender
{
	if ([sender isKindOfClass:[NSOpenPanel class]]) {
		NSString *filename = [[(NSOpenPanel *)sender URL] path];
		[_openSourceFileAccessoryViewController setScriptTypeForFile:filename];
	}
}

@end
