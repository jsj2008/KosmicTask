//
//  MGSEmptyParameterViewController.m
//  Mother
//
//  Created by Jonathan on 27/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSEmptyParameterViewController.h"
#import "MGSCapsuleTextCell.h"

@implementation MGSEmptyParameterViewController

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	// seems to be bug in view autoresizing code when trying to
	// get a view to stay centered.
	// so turn off view
	[[self view] setAutoresizesSubviews:NO];
	[[self view] setPostsFrameChangedNotifications:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidResize:) name:NSViewFrameDidChangeNotification object:[self view]];

	NSCell *cell = [_textField cell];
	if ([cell isKindOfClass:[MGSCapsuleTextCell class]]) {
		[(MGSCapsuleTextCell *)cell setCapsuleHasShadow:NO];
	}
}

# pragma mark Notification handlers

/*
 
 view did resize
 
 */
- (void)viewDidResize:(NSNotification *)note
{
	#pragma unused(note)
	
	NSSize size = [centreView frame].size;
	NSSize viewSize = [[self view] frame].size;
	NSPoint origin = NSMakePoint((viewSize.width - size.width)/2, (viewSize.height - size.height)/2);
	[centreView setFrameOrigin:origin];
	[centreView setNeedsDisplay:YES];
}

@end
