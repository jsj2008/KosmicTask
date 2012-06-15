//
//  MGSActionWindowController.m
//  Mother
//
//  Created by Jonathan on 03/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSActionWindowController.h"
#import "MGSTaskSpecifier.h"
#import "MGSToolbarController.h"
#import "MGSNotifications.h"
#import "MGSRequestViewController.h"
#import "MGSInputRequestViewController.h"
#import "MGSScript.h"
#import "MGSNetClient.h"
#import "MGSClientScriptManager.h"
#import "MGSMotherModes.h"
#import "NSView_Mugginsoft.h"
#import "MGSRequestViewManager.h"
#import "NSWindow_Mugginsoft.h"

// class extension
@interface MGSActionWindowController()
- (void)viewConfigChangeRequest:(NSNotification *)notification;
@end

@interface MGSActionWindowController(Private)
//- (void)save;
@end


@implementation MGSActionWindowController

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super initWithWindowNibName:@"ActionWindow"])) {;
		self.toolbarStyle = MGSToolbarStyleAction;
		_sizeMode = kMGSMotherSizeModeNormal;
	}
	return self;
}

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	[[self.requestViewController inputViewController] setAllowDetach:YES];
	
	// set the run tab view
	_initialView = view;
	[[view superview] replaceSubview:view withViewFrameAsOld:[self.requestViewController view]];
	view = [self.requestViewController view];
	
	[[self window] addViewToTitleBar:pinButton xoffset:4.0f];
	
	// observe notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewConfigChangeRequest:) name:MGSNoteViewConfigChangeRequest object:[self window]];

	// min size for normal size window
	_normalMinSize = [[self window] minSize];
	_minimalMinSize = NSMakeSize(500, [[self window] minimalWindowHeight]+ [view frame].origin.y);
	_previousSize = _minimalMinSize;
	_topLeftPoint = NSZeroPoint;
	_styleMask = [[self window] styleMask];
	_previousMinimalFrame = NSZeroRect;
	_previousNormalFrame = NSZeroRect;
	_contentView = [[self window] contentView];
}

/*
 
 pin button click
 
 */
- (IBAction)pinButtonClick:(id)sender
{
	NSInteger windowLevel = NSNormalWindowLevel;
	if ([(NSButton *)sender state] == NSOnState) {
		windowLevel = NSFloatingWindowLevel;
	} 
	[[self window] setLevel:windowLevel];
}
/*
 
 set action
 
 */
- (void)setAction:(MGSTaskSpecifier *)anAction
{
	
	self.requestViewController.actionSpecifier = anAction;
	
	self.netClient = [anAction netClient];
	
	// action changed notification for this window
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteActionSelectionChanged object:[self window] 
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:anAction, MGSActionKey, nil]];
}

/*
 
 set delegate
 
 */

- (void)setDelegate:(id <MGSActionWindowDelegate>) object
{
	delegate = object;
}


/*
 
 commit pending edits in all views
 
 */
- (BOOL)commitPendingEdits
{
	if (![self.requestViewController commitEditing]) {
		return NO;
	}
	return YES;
}

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


#pragma mark - notifications

/*
 
 window will close
 
 */
- (void)windowWillClose:(NSNotification *)notification
{
	[super windowWillClose:notification];
	
	// NSWindowController will have registered us for this notification
	if (delegate && [delegate respondsToSelector:@selector(actionWindowWillClose:)]) {
		[delegate actionWindowWillClose:self];
	}
	
	// remove our request view controller from singleton handler
	[[MGSRequestViewManager sharedInstance] removeObject:self.requestViewController];
}

/*
 
 window did resign key
 
 */
- (void)windowDidResignKey:(NSNotification *)notification
{
	#pragma unused(notification)
	
	[[self window] endEditing:NO];
}

#pragma mark Menu handling
/*
 
 validate menu item
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	BOOL enabled = YES;
	SEL theAction = [menuItem action];
	
	// valiate super
	if (![super validateMenuItem:menuItem]) {
		return NO;
	}
	
	// mini view selected
	if (theAction == @selector(viewMenuMiniViewSelected:)) {
		NSString *title = @"";
		if (_sizeMode == kMGSMotherSizeModeNormal) {
			title = NSLocalizedString(@"Switch to Mini View", @"Mini view menu title");
		} else {
			title = NSLocalizedString(@"Switch from Mini View", @"Mini view menu title");
		}
		[menuItem setTitle: title];
	}
	
	return enabled;
}	
/*
 
 view menu mini view item selected
 
 */
- (IBAction)viewMenuMiniViewSelected:(id)sender
{
#pragma unused(sender)
	
	eMGSMotherViewConfig viewConfig = kMGSMotherViewConfigMinimal;
	eMGSViewState viewState;
	if (_sizeMode == kMGSMotherSizeModeNormal) {
		viewState = kMGSViewStateMinimalSize;
	} else {
		viewState = kMGSViewStateNormalSize;
	}
	
	// post view mode change request notification.
	// much of the view handling could have been dealt with MUCH more simply by using
	// the responder chain.
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInteger:viewConfig], MGSNoteViewConfigKey,
						  [NSNumber numberWithInteger:viewState], MGSNoteViewStateKey,
						  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:[self window] userInfo:dict];
	
	
}

#pragma mark NSWindow delegate messages

/*
 
 window should close
 
 */
- (BOOL)windowShouldClose:(id)window
{
	if (![super windowShouldClose:window]) {
		return NO;
	}
	
	// commit any edits
	if (![self commitPendingEdits]) {
		return NO;
	}
	

	return YES;
}

/*
 
 window will resize
 
 */
- (NSSize)windowWillResize:(NSWindow *) window toSize:(NSSize)newSize
{
	if (([window styleMask] & NSResizableWindowMask)) {
		return newSize; //resize happens
	} else {
		return [window frame].size; //no change
    }
}

/*
 
 window should zoom
 
 */
- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame
{
	#pragma unused(newFrame)
	
	// let the zoom happen if showsResizeIndicator is YES
    return ([window styleMask] & NSResizableWindowMask);
	//return [window showsResizeIndicator];
}
#pragma mark MGSRequestViewController delegate messages
/*
 
 request view action changed
 
 delegate message
 
 */
- (void)requestViewActionDidChange:(MGSRequestViewController *)requestController
{
	// bind status to request overview
	[_status bind:NSValueBinding toObject:[requestController actionSpecifier] withKeyPath:@"requestProgress.overviewString" options:nil];
	
	[super requestViewActionDidChange:requestController];	
}


/*
 
 request view action will change
 
 
 */
- (void)requestViewActionWillChange:(MGSRequestViewController *)requestController
{
	if (self.requestViewController.actionSpecifier) {
		[_status unbind:NSValueBinding];
	}
	
	[super requestViewActionWillChange:requestController];
}

#pragma mark notifications
/*
 
 action view mode changed
 
 */
- (void)viewConfigChangeRequest:(NSNotification *)notification
{
	// view ID
	NSNumber *number = [[notification userInfo] objectForKey:MGSNoteViewConfigKey];
	if (!number) return;
	eMGSMotherViewConfig viewConfig = [number intValue];
	
	// get view state
	number = [[notification userInfo] objectForKey:MGSNoteViewStateKey];
	if (!number) return;
	eMGSViewState viewState = [number integerValue];
		
	NSButton *zoomButton = [[self window] standardWindowButton:NSWindowZoomButton];

	switch (viewConfig) {
			
		// minimal view
		case kMGSMotherViewConfigMinimal:;
			NSSize minSize = NSZeroSize;
			NSRect frame = [[self window] frame];
			NSSize currentSize = frame.size;
			NSUInteger styleMask = [[self window] styleMask];
			
			NSRect screenFrame = [[[self window] screen] frame];
			_topLeftPoint = NSMakePoint(frame.origin.x, NSMaxY(frame));

			// toggle content view
			if ([_contentView superview] && viewState == kMGSViewStateMinimalSize) {

				// check if minimal size already imposed
				if (_sizeMode == kMGSMotherSizeModeMinimal) {
					return;
				}
				
				// show minimal window

				// mode changed
				[[NSNotificationCenter defaultCenter] 
					postNotificationName:MGSNoteWindowSizeModeChanged 
					object:[self window] 
					userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kMGSMotherSizeModeMinimal], MGSNoteModeKey,nil]];
				
				// unzoom window if zoomed
				if ([[self window] isZoomed]) {
					[[self window] zoom:self];
				}

				[[self window] setContentView:[_minimalView initWithFrame:[_contentView frame]]];
				
				
				minSize = _minimalMinSize;
				
				// if window has not been moved then restore to previous minimal frame.
				// this allows friendly positioning/resizing at screen edges
				if (NSEqualPoints(_previousNormalFrame.origin, frame.origin)) {
					frame = _previousMinimalFrame;
				} else {
					frame.size = _previousSize;
					frame.origin.y = _topLeftPoint.y - frame.size.height;
				}

				[zoomButton setEnabled:NO];
				[[self window] setShowsResizeIndicator:NO]; // ignored on 10.7
				[[self window] setMinSize:minSize];
				[[self window] setFrame:frame display:YES animate:NO];

                styleMask ^= NSResizableWindowMask;
                [[self window] setStyleMask:styleMask];
				
				_sizeMode = kMGSMotherSizeModeMinimal;
				
			} else if (![_contentView superview] && viewState == kMGSViewStateNormalSize) {

				// check if minimal size already imposed
				if (_sizeMode == kMGSMotherSizeModeNormal) {
					return;
				}
				
				_previousMinimalFrame = frame;
				
				// show normal window
				minSize = _normalMinSize;
				frame.size = _previousSize;
				frame.origin.y = _topLeftPoint.y - frame.size.height;

				// ensure all window is on screen
				if (NSMaxX(frame) > NSMaxX(screenFrame)) {
					frame.origin.x =  NSMaxX(_previousMinimalFrame) - frame.size.width;
				}
				if (frame.origin.y < screenFrame.origin.y) {
					frame.origin.y = _previousMinimalFrame.origin.y;
				}
				
				if (frame.origin.x < 0) {
					frame.origin.x = 0;
				}
				
                [[self window] setStyleMask:_styleMask];
				
				[zoomButton setEnabled:YES];
				[[self window] setShowsResizeIndicator:YES];    // ignored on 10.7
				[[self window] setFrame:frame display:YES animate:NO];
				[[self window] setMinSize:minSize];
				[[self window] setContentView:_contentView]; 

				// mode changed
				[[NSNotificationCenter defaultCenter] 
				 postNotificationName:MGSNoteWindowSizeModeChanged 
				 object:[self window] 
				 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kMGSMotherSizeModeNormal], MGSNoteModeKey,nil]];
				
				_previousNormalFrame = frame;
				
				_sizeMode = kMGSMotherSizeModeNormal;
			} else {
				NSAssert(NO, @"Invalid minimal view request");
				return;
			}
			
			_previousSize = currentSize;

			break;
			
		default:
			return;
	}

	// send out view config did change notification
	NSNotification *noteDone = [NSNotification notificationWithName:MGSNoteViewConfigDidChange 
															 object:[self window]
														   userInfo:[notification userInfo]];
	[[NSNotificationCenter defaultCenter] postNotification:noteDone];
	
}

@end

@implementation MGSActionWindowController(Private)

@end
