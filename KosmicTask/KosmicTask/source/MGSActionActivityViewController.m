//
//  MGSActionActivityViewController.m
//  Mother
//
//  Created by Jonathan on 16/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionActivityViewController.h"
#import "MGSCapsuleTextCell.h"
#import "MGSNotifications.h"
#import "MLog.h"
#import "MGSMotherModes.h"
#import "MGSAppController.h"

// class extension 
@interface MGSActionActivityViewController()
- (void)updateActivityText;
- (void)viewDidMoveToWindow;
- (void)appRunModeChanged:(NSNotification *)notification;
@end

@implementation MGSActionActivityViewController

@synthesize activity = _activity;

/*
 
 init
 
 */
- (id)init 
{
	if ([super initWithNibName:@"ActionActivityView" bundle:nil]) {
		_activity = MGSUnavailableTaskActivity;

		
	}
	return self;
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	NSCell *cell = [_activityTextField cell];
	if ([cell isKindOfClass:[MGSCapsuleTextCell class]]) {
		
		// set capsule cell properties
		[(MGSCapsuleTextCell *)cell setCapsuleHasShadow:NO];
		
		// configure activity view
		_activityView.delegate = self;
		_activityView.respectRunMode = YES;
		[_activityView setActivity:_activity];
		[self updateActivityText];
		[_activityView setMenu:[(MGSAppController *)[NSApp delegate] taskMenu]];
		
		// observe app run mode
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appRunModeChanged:) name:MGSNoteAppRunModeChanged object:nil];
        
        // add action activity view as subview of NSTextView
        NSRect documentVisibleRect = [_scrollView documentVisibleRect];
        [_activityView setFrame:documentVisibleRect];
        [_textView addSubview:_activityView];
    }        
}

/*
 
 app run mode changed
 
 */
- (void)appRunModeChanged:(NSNotification *)notification
{
	NSInteger mode = [[[notification userInfo] objectForKey:MGSNoteModeKey] integerValue];
	[self setRunMode:mode];
}

/*
 
 set run mode
 
 */
- (void)setRunMode:(eMGSMotherRunMode)mode
{
	[self viewDidMoveToWindow];
	_activityView.runMode = mode;
	[self updateActivityText];
}
/*
 
 animate
 
 */
- (void)animate:(NSTimer *)aTimer
{	
	#pragma unused(aTimer)
	
	[self updateAnimation];
}


/*
 
 update animation
 
 */
- (void)updateAnimation
{
	double value = fmod(([_activityView doubleValue] + (5.0/60.0)), 1.0);
	[_activityView setDoubleValue:value];
	[_activityView updateAnimation];
}

/*
 
 set activity
 
 */
- (void)setActivity:(MGSTaskActivity)activity
{
	if (_activity == activity) return;
	
	_activity = activity;
	[_activityView setActivity:activity];
	
	[self updateActivityText];
	
	// animate graphic
	if (_activity == MGSProcessingTaskActivity || _activity == MGSPausedTaskActivity) {
		
		// start timer if not running
		if (!_animationTimer) {
			[_activityView setDoubleValue:0.0];
			[_activityView setSpinning:YES];
			_animationTimer = [NSTimer scheduledTimerWithTimeInterval:[_activityView animationDelay] target:self selector:@selector(animate:) userInfo:NULL repeats:YES];
		}
	} else {
		
		// stop animation
		if (_animationTimer) {
			[_activityView setSpinning:NO];
			[_animationTimer invalidate];
			_animationTimer = nil;
		}
	}
}

/*
 
 update activity view text
 
 */
- (void)updateActivityText
{
	// set activity text
	NSString *activityText = nil;
	
	// use run mode to determine text
	if (_activityView.respectRunMode) {
		switch (_activityView.runMode) {
				
			case kMGSMotherRunModeConfigure:
				activityText = NSLocalizedString(@"Admin", @"Admin: Task activity text beneath graphic");
				break;
				
			default:
				break;
		}
		
	}
	
	// use activity to determine text
	if (!activityText) {
		switch (_activity) {
			case MGSProcessingTaskActivity:
				activityText = NSLocalizedString(@"Running", @"Running: Task activity text beneath graphic");
				break;
				
			case MGSPausedTaskActivity:
				activityText = NSLocalizedString(@"Paused", @"Paused: Task activity text beneath graphic");
				break;
				
			case MGSTerminatedTaskActivity:
				activityText = NSLocalizedString(@"Stopped", @"Stopped: Task activity text beneath graphic");
				break;
				
			case MGSReadyTaskActivity:
				activityText = NSLocalizedString(@"Ready", @"Ready: Task activity text beneath graphic");
				break;
				
			case MGSUnavailableTaskActivity:
			default:
				activityText = NSLocalizedString(@"Unavailable", @"Unavailable: Task activity text beneath graphic");
				break;
				
		}
	}
	[_activityTextField setStringValue:activityText];
}
/*
 
 split view additional divider rect
 
 */
- (NSView *)splitViewAdditionalView
{
	return _dragThumbImage;
}

/*
 
 - addDisplayString:
 
 */
- (void)addDisplayString:(NSString *)value
{
    [_activityView appendText:value];
}
/*
 
 - clearDisplayString
 
 */
- (void)clearDisplayString
{
    [_activityView clearText];
}
#pragma mark MGSActionActivityViewDelegate methods

/*
 
 view did move to window
 
 */
- (void)viewDidMoveToWindow {
	
	// respectRunMode depends upon window
	if ( _activityView.window) {
		_activityView.respectRunMode = _activityView.window == [[NSApp delegate] applicationWindow];
	} 
}

@end
