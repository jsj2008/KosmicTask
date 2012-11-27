//
//  MGSActionInputFooterViewController.m
//  Mother
//
//  Created by Jonathan on 29/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionInputFooterViewController.h"
#import "MGSActionOptionsViewController.h"
#import "MGSActionInfoViewController.h"
#import "MGSActionDescriptionViewController.h"
#import "MGSActionViewController.h"

enum _MGSAIFButton {
	MGSAifButtonNone = 0,
	MGSAifButtonDescription = 1,
	MGSAifButtonOptions = 2,
	MGSAifButtonInfo = 3,
};
typedef NSInteger MGSAifButton;

static MGSAifButton _currentButton = MGSAifButtonNone;

@interface MGSActionInputFooterViewController (Private)
- (void)exclusiveButtonClick:(id)sender;
- (void)deselectAllExclusiveButtons;
- (void)showViewForController:(NSViewController *)controller;
@end

@implementation MGSActionInputFooterViewController

@synthesize delegate = _delegate;
@synthesize actionSpecifier = _actionSpecifier;

/*
 
 init
 
 */
-(id)init 
{
	if ([super initWithNibName:@"ActionInputFooterView" bundle:nil]) {
		
	}
	return self;
}

/*
 
 class initialize
 
 */
+ (void)initialize
{
	if ( self == [MGSActionInputFooterViewController class] ) {
		// may want to retrieve this setting from preferences at some point
		_currentButton = MGSAifButtonNone;
	}
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	_exclusiveButtonArray = [NSArray arrayWithObjects:optionsButton, infoButton, descriptionButton, nil];
	
	//[resetButton setHidden: [parameterHandler count] == 0 ? YES : NO];
	[self deselectAllExclusiveButtons];
	
	_initialViewRect = NSZeroRect;
	[self setResetEnabled:NO];
}

/*
 
 set reset enabled
 
 */
- (void)setResetEnabled:(BOOL)newValue
{
	[resetButton setEnabled:newValue];
}
/*
 
 is reset enabled
 
 */
- (BOOL)isResetEnabled
{
	return [resetButton isEnabled];
}
/*
 
 set action
 
 */
- (void)setActionSpecifier:(MGSTaskSpecifier *)action
{
	_actionSpecifier = action;
	
	switch (_currentButton) {
		case MGSAifButtonNone:
			break;
			
		case MGSAifButtonDescription:
			[descriptionButton performClick:self];
			break;
			
		case MGSAifButtonOptions:
			[optionsButton performClick:self];			
			break;
			
		case MGSAifButtonInfo:
			[infoButton performClick:self];
			break;
	}
}

/*
 
 options button click
 
 */
- (IBAction)optionsClick:(id)sender
{
	[self exclusiveButtonClick:sender];
	if (!_actionOptionsViewController) {
		_actionOptionsViewController = [[MGSActionOptionsViewController alloc] init];
		[_actionOptionsViewController view];
		_actionOptionsViewController.actionSpecifier = _actionSpecifier;
	}
	
	if ([optionsButton state] == NSOnState) {
		_currentButton = MGSAifButtonOptions;
		[self showViewForController:_actionOptionsViewController];
	} else {
		[self showViewForController:nil];
	}
}

/*
 
 info button click
 
 */
- (IBAction)infoClick:(id)sender
{
	[self exclusiveButtonClick:sender];
	if (!_actionInfoViewController) {
		_actionInfoViewController = [[MGSActionInfoViewController alloc] init];
		[_actionInfoViewController view];
		_actionInfoViewController.actionSpecifier = _actionSpecifier;
	}
	
	if ([infoButton state] == NSOnState) {
		_currentButton = MGSAifButtonInfo;
		[self showViewForController:_actionInfoViewController];
	} else {
		[self showViewForController:nil];
	}
}

/*
 
 description button click
 
 */
- (IBAction)descriptionClick:(id)sender
{
	[self exclusiveButtonClick:sender];
	if (!_actionDescriptionViewController) {
		_actionDescriptionViewController = [[MGSActionDescriptionViewController alloc] init];
		[_actionDescriptionViewController view];
		_actionDescriptionViewController.actionSpecifier = _actionSpecifier;
	}
	
	if ([descriptionButton state] == NSOnState) {
		_currentButton = MGSAifButtonDescription;
		[self showViewForController:_actionDescriptionViewController];
	} else {
		[self showViewForController:nil];
	}
}
/*
 
 reset all
 
 */
- (IBAction)resetAll:(id)sender
{
	#pragma unused(sender)
	
	SEL reset = @selector(resetToDefaultValue);
	if ([self delegate] && [[self delegate] respondsToSelector:reset]) {
		[[self delegate] performSelector:reset];
	}
}
@end

@implementation MGSActionInputFooterViewController (Private)

/*
 
 exclusive button click
 
 */
- (void)exclusiveButtonClick:(id)sender
{
	for (NSButton *button in _exclusiveButtonArray) {
		if (![button isEqual:sender]) {
			[button setState:NSOffState];
		}
	}
}


/*
 
 deselect all exclusive buttons
 
 */
- (void)deselectAllExclusiveButtons
{
	for (NSButton *button in _exclusiveButtonArray) {
		[button setState:NSOffState];
	}
}


/*
 
 show view for controller
 
 */
- (void)showViewForController:(NSViewController *)controller
{
	if (_activeViewController) {
		[[_activeViewController view] removeFromSuperview];
		_activeViewController = nil;
	}
		
	NSRect controllerViewRect = [[controller view] bounds];
	NSRect viewRect = [[self view] frame];
	NSSize oldSize = [[self view] frame].size;
	NSRect buttonViewRect = [buttonView frame];
	
	if ((NSInteger)_initialViewRect.size.width == 0 && (NSInteger)_initialViewRect.size.height == 0) {
		_initialViewRect = viewRect;
	}
	
	if (controller) {
		// height change required
		CGFloat heightDelta = controllerViewRect.size.height + buttonViewRect.size.height - viewRect.size.height;
		viewRect.size.height += heightDelta;
		//viewRect.origin.y -= heightDelta;
		[[self view] setFrame:viewRect];
		
		_activeViewController = controller;
		[[self view] addSubview:[_activeViewController view]];
		[[_activeViewController view] setFrame:NSMakeRect(0, 0, viewRect.size.width, viewRect.size.height - buttonViewRect.size.height)];
	} else {
		_currentButton = MGSAifButtonNone;
		
		// if no controller specified then size back to the button bar
		[[self view] setFrame:NSMakeRect(viewRect.origin.x, viewRect.origin.y, viewRect.size.width, buttonViewRect.size.height)];
	}
	
	[_delegate footerViewDidResize:self oldSize:oldSize];
}
@end
