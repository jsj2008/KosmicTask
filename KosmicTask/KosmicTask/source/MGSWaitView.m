//
//  MGSWaitView.m
//  Mother
//
//  Created by Jonathan on 12/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
//
// Shows an animated indeterminate progress indicator when added
// to its superview
//
#import "MGSWaitView.h"


@implementation MGSWaitView

#pragma mark -
#pragma mark Instance methods

/*
 
 - initWithFrame:
 
 */
- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
	}
	return self;
}

#pragma mark -
#pragma mark Animation
/*
 
 - startProgressAnimation
 
 */
- (void)startProgressAnimation
{
	[_progressIndicator startAnimation:self];
}

/*
 
 - stopProgressAnimation
 
 */
- (void)stopProgressAnimation
{
	[_progressIndicator stopAnimation:self];
}

#pragma mark -
#pragma mark NSView


/*
 
 - viewWillMoveToSuperview:
 
 */
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{

	// start or stop animation of progress indicator
	// depending on wether being added to or removed from superview
	if (newSuperview) {
		[_progressIndicator startAnimation:self];
	} else {
		[_progressIndicator stopAnimation:self];
	}

}

/*
 
 - isOpaque
 
 */
- (BOOL)isOpaque
{
	return YES;
}

@end
