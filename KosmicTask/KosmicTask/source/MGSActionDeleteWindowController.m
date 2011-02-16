//
//  MGSActionDeleteWindowController.m
//  Mother
//
//  Created by Jonathan on 29/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionDeleteWindowController.h"


// class extension
@interface MGSActionDeleteWindowController()
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@implementation MGSActionDeleteWindowController

@synthesize modalForWindow = _modalForWindow;
@synthesize delegate = _delegate;

- (id)init
{
	self = [super initWithWindowNibName:@"ActionDeleteWindow"];
	return self;
}

- (void)windowDidLoad
{
	;
}

// save edits for net client
- (void)promptToDeleteAction:(NSString *)actionName onService:(NSString *)serviceName
{

	NSString *message = NSLocalizedString(@"Do you want to delete task \"%@\" on %@?", @"confirm action - task delete sheet");
	message = [NSString stringWithFormat:message, actionName, serviceName];
	
	[mainLabel setStringValue:message];
	
	// show the save sheet
	[NSApp beginSheet:[self window] modalForWindow:_modalForWindow 
		modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}


// modal sheet did end
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	#pragma unused(sheet)
	#pragma unused(contextInfo)

	if (_delegate && [_delegate respondsToSelector:@selector(confirmDeleteSelectedAction:)]) {
		[_delegate confirmDeleteSelectedAction:returnCode];
	}
}

- (IBAction)confirmDelete:(id)sender
{
	[[self window] orderOut:sender];
	[NSApp endSheet:[self window] returnCode:YES];

}

- (IBAction)cancelDelete:(id)sender
{
	[[self window] orderOut:sender];
	[NSApp endSheet:[self window] returnCode:NO];
}



@end
