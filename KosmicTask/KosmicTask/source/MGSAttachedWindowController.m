//
//  MGSAttachedWindowController.m
//  Mother
//
//  Created by Jonathan on 25/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MAAttachedWindow.h"
#import "MGSAttachedWindowController.h"
#import "MGSAttachedViewController.h"
#import "MGSImageAndTextCell.h"

static MGSAttachedWindowController *_sharedController = nil;

// class extension
@interface MGSAttachedWindowController()
- (void)timerFire:(NSTimer*)theTimer;
@end

@implementation MGSAttachedWindowController

+ (id)sharedController
{
	if (!_sharedController) {
		_sharedController = [[[self class] alloc] init];
	}
	return _sharedController;
}

- (id)init
{
	if ((self = [super init])) {
		_attachedViewController = [[MGSAttachedViewController alloc] init];
		[_attachedViewController loadView];
		_applyTimeout = YES;
		_timerInterval = 1.0;
	}
	return self;
}

// point window to centre of rect
- (void)showForWindow:(NSWindow *)aWindow atCentreOfRect:(NSRect)rect withText:(NSString *)text 
{
	if (!aWindow) {
		MLog(DEBUGLOG, @"invalid window");
		return;	
	}
	
	_attachedViewController.text = text;
	NSPoint centrePoint = NSMakePoint(NSMidX(rect), NSMidY(rect));
	[self showForWindow:aWindow atPoint:centrePoint];
}

// show for parent window at point
- (void)showForWindow:(NSWindow *)aWindow atPoint:(NSPoint)aPoint
{
	// window must be destroyed before it is moved etc
	if (_attachedWindow) {
		[self hideNow];
	}
	
	NSAssert(aWindow, @"window is nil");
	
	_parentWindow = aWindow;
	_attachedWindow = [[MAAttachedWindow alloc] initWithView:[_attachedViewController view]
											attachedToPoint:aPoint 
												   inWindow:_parentWindow
													 onSide:MAPositionAutomatic 
												 atDistance:0];
	[_attachedViewController setTextColor:[NSColor whiteColor]];
	[_attachedWindow setAlphaValue:0.0f];
	//[_attachedWindow setBorderColor:[borderColorWell color]];
	//[textField setTextColor:[borderColorWell color]];
	[_attachedWindow setBackgroundColor:[MGSImageAndTextCell countColor]];
	[_attachedWindow setViewMargin:15.0f];
	//[_attachedWindow setBorderWidth:[borderWidthSlider floatValue]];
	[_attachedWindow setCornerRadius:3.0f];
	[_attachedWindow setHasArrow:YES];
	[_attachedWindow setDrawsRoundCornerBesideArrow:YES];
	//[_attachedWindow setArrowBaseWidth:[arrowBaseWidthSlider floatValue]];
	//[_attachedWindow setArrowHeight:[arrowHeightSlider floatValue]];
	
	[_parentWindow addChildWindow:_attachedWindow ordered:NSWindowAbove];
	
	// fade in
	CAAnimation *anim = [CABasicAnimation animation];
    [anim setDelegate:self];
    [_attachedWindow setAnimations:[NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];
	[_attachedWindow.animator setAlphaValue:1.0f];
	
	if (_applyTimeout) {
		_timer = [NSTimer scheduledTimerWithTimeInterval:_timerInterval target:self selector:@selector(timerFire:) userInfo:nil  repeats:NO];
	}
}

/*
 
 timer fire
 
 */
- (void)timerFire:(NSTimer*)theTimer
{
	#pragma unused(theTimer)

	[self hide];
}

/*
 
 hide the window
 
 window Will fade out
 
 the window must be destroyed before redisplay
 
 */
- (BOOL)hide
{
	if (_timer) {
		[_timer invalidate];
		_timer = nil;
	}
	
	if (_parentWindow && _attachedWindow) {
		// fade out
		CAAnimation *anim = [CABasicAnimation animation];
		[anim setDelegate:self];
		[_attachedWindow setAnimations:[NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];
		[_attachedWindow.animator setAlphaValue:0.0f];
		return YES;
	}
	
	return NO;
}

#pragma mark CAAnimation messages 
/*
 
 animation did stop
 
 */
- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag 
{
	#pragma unused(animation)
	#pragma unused(flag)
	
    if((NSUInteger)_attachedWindow.alphaValue == 0) {
		[self hideNow];

	}
}

/*
 
 hide now
 
 no fade
 
 */
- (void)hideNow
{
	if (_timer) {
		[_timer invalidate];
		_timer = nil;
	}
	
	[_parentWindow removeChildWindow:_attachedWindow];
	[_attachedWindow orderOut:self];
	_attachedWindow = nil;
	_parentWindow = nil;
}

@end
