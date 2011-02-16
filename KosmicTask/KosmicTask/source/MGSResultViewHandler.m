//
//  MGSResultViewHandler.m
//  Mother
//
//  Created by Jonathan on 06/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSResultViewHandler.h"
#import "MGSResultViewController.h"
#import "MGSTaskSpecifier.h"
#import "MGSNetClient.h"

@implementation MGSResultViewHandler

+ (id)defaultResultObject
{
	return NSLocalizedString(@"Task completed", @"Default result text");
}

- (id)init
{
	if ([super init]) {
		_resultViewControllers = [NSMutableArray arrayWithCapacity:2];
	}
	return self;
}

//=========================================================================
//
// add result
//
// create a view to display the result
//
//=========================================================================
- (void)addResult1:(id)resultObject forAction:(MGSTaskSpecifier *)action
{
	#pragma unused(resultObject)
	#pragma unused(action)
	
	/*
	// create view controller and view
	MGSResultViewController *resultViewController = [[MGSResultViewController alloc] init];
	[_resultViewControllers addObject:resultViewController];
	
	NSView *newView = [resultViewController view];
	NSView *prevView = nil;
	if ([_resultViewControllers count] > 1)
	{
		MGSResultViewController *prevViewController = [_resultViewControllers objectAtIndex:[_resultViewControllers count] - 1];
		prevView = [prevViewController view];
	}
	
	//
	// the document view of the scroll view is flipped
	//
	NSRect newFrame = [newView frame];
	newFrame.origin.x = 0;
	newFrame.origin.y = 0;
	[newView setFrame:newFrame];

	// resize document view to hold new view
	NSView *docView = [scrollView documentView];
	NSSize newSize  = [docView frame].size;
	newSize.height += [newView frame].size.height;
	
	// if change frame need to redraw view and superview
	[[docView superview] setNeedsDisplayInRect:[docView frame]];
	[docView setFrameSize:newSize];
	[docView setNeedsDisplay:YES];
	
	// move other views down
	int i;
	for (i = 0; i < [_resultViewControllers count]-1; i++) {
		NSView *view = [[_resultViewControllers objectAtIndex:i] view];
		NSPoint newOrigin = [view frame].origin;
		newOrigin.y += newFrame.size.height;
		[[view superview] setNeedsDisplayInRect:[view frame]];
		[view setFrameOrigin:newOrigin];
		[view setNeedsDisplay:YES];
	}
	
	// add new view to document view
	[docView addSubview:newView];
	
	[resultViewController setTitle:[action name]];
	
	[resultViewController setTitleImage:[[action netClient] hostIcon]];
	 */
}

- (void)awakeFromNib
{
}

@end
