//
//  MGSTextPanelViewController.m
//  Mother
//
//  Created by Jonathan on 31/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSTextPanelViewController.h"
#import "NSTextField_Mugginsoft.h"
#import "MGSActionActivityView.h"
#import "MGSNotifications.h"

@implementation MGSTextPanelViewController

@synthesize highlighted = _highlighted;

/*
 
 init
 
 */
-(id)init 
{
	if ([super initWithNibName:@"TextPanelView" bundle:nil]) {
		
	}
	return self;
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	/*
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subviewFrameDidChange:) name:NSViewFrameDidChangeNotification object:_textField];
	 */
	[[_textField cell] setBackgroundStyle: NSBackgroundStyleRaised];
	
	_actionActivityView.backgroundFillColor = [NSColor colorWithCalibratedRed:0.961f green:0.961f blue:0.961f alpha:1.0f];
	_actionActivityView.hasDropShadow = NO;
	self.highlighted = NO;
	
	NSColor *color1 = _actionActivityView.foregroundColor;
	NSColor *color3 = [NSColor keyboardFocusIndicatorColor];
	//NSColor *color2 = [color1 blendedColorWithFraction:0.5 ofColor:color3];
	
	_animationColorArray = [NSArray arrayWithObjects:color1, color3, nil];
	_animationColorIndex = 0;
	_animationColorIndexIncreasing = YES;
	//_animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(animationTimerExpired:) userInfo:nil repeats:YES];
}

/*
 
 set activity 
 
 */
- (void)setActivity:(MGSTaskActivity)activity 
{
	_actionActivityView.activity = activity;
}

/*
 
 set highlighted
 
 */
- (void)setHighlighted:(BOOL)value
{
	_highlighted = value;
	//_actionActivityView.foregroundColor = _highlighted ? [NSColor keyboardFocusIndicatorColor] : [NSColor grayColor];
	//_actionActivityView.hasDropShadow = _highlighted;
	//[_actionActivityView display];
}
/*
 
 animation timer expired
 
 */
- (void)animationTimerExpired:(NSTimer*)theTimer
{
	#pragma unused(theTimer)
	
	if (_animationColorIndexIncreasing) {
		if (_animationColorIndex == [_animationColorArray count] -1) {
			_animationColorIndexIncreasing = NO;
			//return;
		} 
	} else {
		if (_animationColorIndex == 0) {
			_animationColorIndexIncreasing = YES;
			//return;
		} 
	}
	
	if (_animationColorIndexIncreasing) {
		_animationColorIndex++;
	} else {
		_animationColorIndex--;
	}
	_actionActivityView.foregroundColor = [_animationColorArray objectAtIndex:_animationColorIndex];
	[_actionActivityView setNeedsDisplay:YES];
}

/*
 
 subview frame did change
 
 */
- (void)subviewFrameDidChange:(NSNotification *)notification
{
	if ([[self view] autoresizesSubviews]) {
		return;
	}
	
	NSView *subview = [notification object];
	
	if (subview == _textField) {
		
		NSSize size = [_textField frame].size;
		size.height += 32;
		
		[[self view] setFrameSize: size];
	}
}

/*
 
 set string value
 
 */
- (void)setStringValue:(NSString *)aString
{
	if (!aString) {
		aString = @"";
	}
	
	[_textField setStringValue:aString];
	
	// scale text field vertically to fit
	/*
	[[self view] setAutoresizesSubviews:NO];
	[_textField verticalHeightToFit];
	[[self view] setAutoresizesSubviews:YES];
	 */
}

/*
 
 initialise action
 
 */
- (IBAction)initialiseAction:(id)sender
{
	#pragma unused(sender)
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteInitialiseAction object:[self view]];
	
}
@end
