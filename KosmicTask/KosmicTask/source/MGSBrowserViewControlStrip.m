//
//  MGSBrowserViewControlStrip.m
//  Mother
//
//  Created by Jonathan on 04/12/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSBrowserViewControlStrip.h"
#import "MGSAppController.h"
#import "MGSNotifications.h"
#import "MGSMotherModes.h"
#import "MGSNetClient.h"
#import "MGSMainViewController.h";
#import "MGSPreferences.h";

@interface MGSBrowserViewControlStrip()
- (void)viewConfigDidChange:(NSNotification *)note;
@end

@implementation MGSBrowserViewControlStrip

/*
 
 - initWithFrame:
 
 */
- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewConfigDidChange:) name:MGSNoteViewConfigDidChange object:nil];
		
		_segmentToSelectWhenNotHidden = BROWSER_TASK_SEGMENT_INDEX;
		browserViewVisible = YES;	// all views are loaded initially
		
	}
	
	return self;
}

/*
 
 resize subviews
 
 */
- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
	#pragma unused(oldBoundsSize)
	
	NSWindow *window = [[NSApp delegate] applicationWindow];
	CGFloat windowWidth = [window frame].size.width;
	CGFloat viewWidth = [self frame].size.width;
	CGFloat centreViewX = (windowWidth - [_centreView frame].size.width)/2;
	
	centreViewX -= (windowWidth - viewWidth);
	CGFloat centreViewY = [_centreView frame].origin.y;
	
	if (centreViewX < [_leftView frame].size.width) {
		centreViewX = [_leftView frame].size.width;
	}
	
	[_centreView setFrameOrigin:NSMakePoint(centreViewX, centreViewY)];
	
	NSRect frame = [leftAttachedView frame];
	CGFloat attachedViewY = frame.origin.y;
	CGFloat attachedViewX = centreViewX - 5 - frame.size.width;
	[leftAttachedView setFrameOrigin:NSMakePoint(attachedViewX, attachedViewY)];
}


/*
 
 select segment and send action to target
 
 */
- (void)selectSegment:(NSInteger)idx
{
	NSAssert(idx >= BROWSER_MIN_SEGMENT_INDEX && idx <= BROWSER_MAX_SEGMENT_INDEX, @"invalid index");
	
	[_viewSelectorSegmentedControl setSelectedSegment:idx];
	[NSApp sendAction:[_viewSelectorSegmentedControl action] to:[_viewSelectorSegmentedControl target] from:_viewSelectorSegmentedControl];
}

#pragma mark -
#pragma mark Actions

/*
 
 segmented control click
 
 */
- (IBAction)segControlClicked:(id)sender
{
	eMGSViewState viewState = NSNotFound;
	
	int clickedSegment = [sender selectedSegment];
	
	switch (clickedSegment) {
			
			// close browser
		case BROWSER_CLOSE_SEGMENT_INDEX:
			if (browserViewVisible == NO) return;
			viewState = kMGSViewStateHide;
			break;
			
			// any other segment
		default:
			// if browser hidden then we require to show it
			if (browserViewVisible == NO) {
				viewState = kMGSViewStateShow;
			} 
			_segmentToSelectWhenNotHidden = clickedSegment;
			
			break;
	}
	BOOL hideToggle = (clickedSegment == BROWSER_TASK_SEGMENT_INDEX ? NO : YES);
	[groupToggle setHidden:hideToggle];
	
	// save default
	[[NSUserDefaults standardUserDefaults] setInteger:clickedSegment forKey:MGSTaskBrowserMode];
	
	// send click to delegate.
	// the delegate will select the required view.
	if (_delegate && [_delegate respondsToSelector:@selector(browserSegControlClicked:)]) {
		[_delegate browserSegControlClicked:sender];
	}
	
	// post view mode change request.
	// this is required only when we need to either hide or display the view
	if (viewState != NSNotFound) {
		browserViewVisible = viewState == kMGSViewStateShow ? YES : NO;
		
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInteger:kMGSMotherViewConfigBrowser], MGSNoteViewConfigKey,
							  [NSNumber numberWithInteger:viewState], MGSNoteViewStateKey,
							  nil];
		
		// the observer of this notification will actually display the required view
		[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:self userInfo:dict];
	}
}

/*
 
 - sidebarToggleAction:
 
 */
- (void)sidebarToggleAction:(id)sender
{
#pragma unused(sender)
	
	eMGSViewState viewState = NSNotFound;
	
	if ([sidebarToggle state] == NSOnState) {
		viewState = kMGSViewStateHide;
	} else {
		viewState = kMGSViewStateShow;
	}
	
	// post view mode change request
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInteger:kMGSMotherViewConfigSidebar], MGSNoteViewConfigKey,
						  [NSNumber numberWithInteger:viewState], MGSNoteViewStateKey,
						  nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:self userInfo:dict];
	
}

/*
 
 - groupToggleAction:
 
 */
- (void)groupToggleAction:(id)sender
{
#pragma unused(sender)
	
	eMGSViewState viewState = NSNotFound;
	
	if ([groupToggle state] == NSOnState) {
		viewState = kMGSViewStateShow;
	} else {
		viewState = kMGSViewStateHide;
	}
	
	// post view mode change request
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInteger:kMGSMotherViewConfigGroupList], MGSNoteViewConfigKey,
						  [NSNumber numberWithInteger:viewState], MGSNoteViewStateKey,
						  nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:self userInfo:dict];
	
}

#pragma mark NSNotificationCenter callbacks

/*
 
 view config did change 
 
 perhaps unneccessary
 
 */
- (void)viewConfigDidChange:(NSNotification *)notification
{
	// view config
	NSNumber *number = [[notification userInfo] objectForKey:MGSNoteViewConfigKey];
	if (!number) return;
	eMGSMotherViewConfig viewConfig = [number integerValue];

	// view state
	number = [[notification userInfo] objectForKey:MGSNoteViewStateKey];
	if (!number) return;
	eMGSViewState viewState = [number integerValue];

	int idx = -1;
	NSInteger state = NSOnState;

	// sync GUI to view state
	switch (viewConfig) {
			
		case kMGSMotherViewConfigBrowser:;
			switch (viewState) {
				case kMGSViewStateShow:
					idx = _segmentToSelectWhenNotHidden;
					browserViewVisible = YES;
					break;
					
				case kMGSViewStateHide:
					idx = BROWSER_CLOSE_SEGMENT_INDEX;
					browserViewVisible = NO;
					break;
					
				default:
					return;
			}
			[_viewSelectorSegmentedControl setSelectedSegment:idx];
			[groupToggle setHidden:(idx == BROWSER_TASK_SEGMENT_INDEX ? NO : YES)];
			
			break;

		case kMGSMotherViewConfigSidebar:;
			switch (viewState) {
				case kMGSViewStateShow:
					state = NSOffState;
					break;
					
				case kMGSViewStateHide:
					state = NSOnState;
					break;
					
				default:
					return;
			}
			[sidebarToggle setState:state];
			
			break;
		
		case kMGSMotherViewConfigGroupList:;
			switch (viewState) {
				case kMGSViewStateShow:
					state = NSOnState;
					break;
					
				case kMGSViewStateHide:
					state = NSOffState;
					break;
					
				default:
					return;
			}
			[groupToggle setState:state];
			
			break;
			
		default:
			break;
			
	}
}


@end
