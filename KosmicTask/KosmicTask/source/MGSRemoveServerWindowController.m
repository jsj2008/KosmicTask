//
//  MGSRemoveServerWindowController.m
//  Mother
//
//  Created by Jonathan on 06/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSRemoveServerWindowController.h"
#import "MGSNetClientManager.h"
#import "MGSNetClient.h"


@implementation MGSRemoveServerWindowController
@synthesize delegate = _delegate;

/*
 
 - init
 
 */
- (id)init
{
	self = [super initWithWindowNibName:@"DisconnectServer"];
	_delegate = nil;
	return self;
}

/*
 
 - windowDidLoad
 
 */
- (void)windowDidLoad
{
	[arrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:nil];
	
	// add dictionaries for clients with user connected hosts to array controller
	[arrayController setContent:[[MGSNetClientManager sharedController] hostViaUserDictionaries]];
}

/*
 
 - observeValueForKeyPath:ofObject:change:context
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(change)
	#pragma unused(context)
	
	BOOL enableRemove;
	
	if (object == arrayController) {
		NSArray *array = [arrayController selectedObjects];
		if ([array count] > 0) {
			enableRemove = YES;
		} else {
			enableRemove = NO;
		}
		[disconnectButton setEnabled:enableRemove];
	}
	
}

/*
 
 - showWindow:
 
 */
- (void)showWindow:(id)sender
{
	#pragma unused(sender)
	
	[super showWindow:self];
}

/*
 
 - cancel:
 
 */
- (IBAction)cancel:(id)sender
{
	#pragma unused(sender)
	
	[self closeWindow];
}

/*
 
 - closeWindow
 
 */
- (void)closeWindow
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:1];
}

/*
 
 - disconnect:
 
 */
- (IBAction)disconnect:(id)sender
{
	#pragma unused(sender)
	
	for (NSDictionary *dict in [arrayController selectedObjects]) {
		NSString *address = [dict objectForKey:MGSNetClientKeyAddress];
		MGSNetClient *netClient = [[MGSNetClientManager sharedController] clientForServiceName:address]; 
		if (netClient) {
			[(MGSNetClientManager *)[MGSNetClientManager sharedController] removeStaticClient:netClient];
			[arrayController removeObject:dict];
		}
	}
	return;
}

@end
