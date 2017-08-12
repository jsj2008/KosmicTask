//
//  MGSActionEditViewController.m
//  Mother
//
//  Created by Jonathan on 01/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionEditViewController.h"
#import "MGSActionDetailEditViewController.h"
#import "NSView_Mugginsoft.h"
#import "MGSTaskSpecifier.h"
#import "MGSActionViewController.h"
#import "MGSFlippedView.h"
#import "NSSplitView_Mugginsoft.h"
#import "MGSActionView.h"

#define MIN_LEFT_SPLITVIEW_WIDTH 390
#define MIN_RIGHT_SPLITVIEW_WIDTH 390

@implementation MGSActionEditViewController

@synthesize action = _action;

/*
 
 init
 
 */
- (id)init
{
	_nibLoaded = NO;
	return [super initWithNibName:@"ActionEditView" bundle:nil];	// load another nib
}


/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{	
	if (_nibLoaded) {
		return;
	}
	
	_nibLoaded = YES;

	
	// assign the action
	if (_action) {
		self.action = _action;
	}
	
	// create action view controller
	_actionViewController = [[MGSActionViewController alloc] initWithMode:MGSParameterModeEdit];
	[_actionViewController view]; // initiate nib loading
	_actionViewController.allowHighlight = NO;
	_actionViewController.invertedLeftBannerImage = YES;
	
	// action view
	MGSActionView *actionView = [_actionViewController actionView];
	NSSize actionViewFrameSize = [actionView frame].size;

	//
	// insert action detail view into action middle view
	//
	
	// calc new size of middle view
	NSRect middleViewFrame = [_actionViewController middleView].frame;
	NSRect actionDetailFrame = [actionDetailController view].bounds;
	CGFloat heightDelta = actionDetailFrame.size.height - middleViewFrame.size.height;
	actionDetailFrame.origin = middleViewFrame.origin;	// same origin as middle view
	actionDetailFrame.size.width = middleViewFrame.size.width;	// same width as middle view

	// adjust view size
	actionViewFrameSize.height += heightDelta;
	[actionView setFrameSize:actionViewFrameSize];

	// replace middle view
	[actionView replaceSubview:[_actionViewController middleView] with:[actionDetailController view]];
	[_actionViewController setMiddleView:[actionDetailController view]];
	
	// set middle view frame size
	[[actionDetailController view] setFrame:actionDetailFrame];
	
	//
	// insert action detail info view into action bottom view
	//
	
	// calc height change reqd for new bottom view
	heightDelta = [[actionDetailController infoView] bounds].size.height -  [[_actionViewController bottomView] bounds].size.height;

	// resize the action view
	actionViewFrameSize.height += heightDelta;
	[actionView setFrameSize:actionViewFrameSize];
	
	// replace bottom view
	[actionView replaceSubview:[_actionViewController bottomView] withViewSizedAsOld:[actionDetailController infoView]];
	[_actionViewController setBottomView: [actionDetailController infoView]];
	
	// modify bottom view height
	[_actionViewController modifyBottomViewHeightBy:heightDelta];
	
	[actionView setNeedsDisplay:YES];
	
	// want flipped view to wrap action view.
	// this is similar to the way that NSSplitView behaves.
	// in this case it might be easier just to use a splitview rather than do all this manually.
	// it might assist with the resizing too.
	NSSize actionSize = [actionView frame].size;
	[actionFlippedView setFrameSize:actionSize];
	
	// wrap unflipped action view in flipped wrapper view so that the wrapper remains
	// at the top of the scrollview and the contents of action view remain unflipped.
	[actionFlippedView addSubview:(NSView *)actionView];
	[actionView setFrameOrigin:NSMakePoint(0,0)];
	
	// insert action flipped view into scroller
	// size action view to width of scroller content view
	actionSize.width = [actionDetailScrollView contentSize].width;
	[actionFlippedView setFrameSize:actionSize];
	[actionFlippedView setNeedsDisplay:YES];
	[actionDetailScrollView setDocumentView:actionFlippedView];
	
	// bind the action parameter count to banner right label.
	// note that there is probably a better place to do this.
	[[_actionViewController bannerRightLabel] bind:NSValueBinding toObject:actionParameterController withKeyPath:@"inputCount" options:nil];
		
	//
	// insert action parameter view into splitview
	//
	NSView *subview = [[splitView subviews] objectAtIndex:1];
	[subview replaceSubview:actionParameterEditView withViewSizedAsOld:[actionParameterController view]];
	actionParameterEditView = [actionParameterController view];
	
}

/*
 
 set action
 
 */
- (void)setAction:(MGSTaskSpecifier *)anAction
{
	_action = anAction;
	_actionViewController.action = _action;
	actionDetailController.action = _action;
	actionParameterController.action = _action; 
}


/*
 
 commit pending edits
 
 */
- (BOOL)commitPendingEdits
{
	return ([actionDetailController commitEditing] && [actionParameterController commitEditing]);
}

/*
 
 dispose
 
 */
- (void)dispose
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
 
 - parameterViewConfigurationFlags
 
 */
- (MGSParameterViewConfigurationFlags)parameterViewConfigurationFlags
{
    return actionParameterController.parameterViewConfigurationFlags;
}
/*
 
 - setParameterViewConfigurationFlags
 
 */
- (void)setParameterViewConfigurationFlags:(MGSParameterViewConfigurationFlags)flag
{
    actionParameterController.parameterViewConfigurationFlags = flag;
}
#pragma mark NSSplitView delegate messages
//
// splitview delegate
//
// the scrollview document will be manually sized to fit the clipview area
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	#pragma unused(aNotification)
	
	return;
	
#pragma mark warning may need to reinstate this
/*
	NSSplitView *splitView = [aNotification object];
	NSRect rect0 = [[[splitView subviews] objectAtIndex:0] frame];
	NSRect newFrame = [actionDetailView frame];
	newFrame.size.width = rect0.size.width;
	newFrame.size.width -= [[scrollView verticalScroller] frame].size.width;
	//newFrame.size.width = [scrollView contentSize].width;
	[actionDetailView setFrame:newFrame];
	
	NSView *subview = [[actionDetailView subviews] objectAtIndex:0];
	newFrame = [subview frame];
	newFrame.size.width = [actionDetailView frame].size.width;
	[subview setFrame:newFrame];
	
	[scrollView setDocumentView:actionDetailView];
*/
}

/*
 
 get additional drag rect for divider at index
 
 */
- (NSRect)splitView:(NSSplitView *)aSplitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
	#pragma unused(dividerIndex)
	
	//NSView *additionalView = [_resultViewController splitViewAdditionalView];
	return [aSplitView convertRect:[dragThumb bounds] fromView:dragThumb];
}

/*
 
 splitview resized
 
 */
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize
{	
	MGSSplitviewBehaviour behaviour;
	
	NSSize size = [sender frame].size;
	CGFloat delta = oldSize.width - size.width;
	CGFloat rightViewWidth = size.width + delta - [[[sender subviews] objectAtIndex:0] frame].size.width - [splitView dividerThickness];
	
	NSArray *minWidthArray = [NSArray arrayWithObjects:[NSNumber numberWithDouble:MIN_LEFT_SPLITVIEW_WIDTH], [NSNumber numberWithDouble:MIN_RIGHT_SPLITVIEW_WIDTH], nil];

	// if right view >= min size then resizing right view
	if (rightViewWidth >= MIN_RIGHT_SPLITVIEW_WIDTH) {
		behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;
	} else {
		// resize left view
		behaviour = MGSSplitviewBehaviourOf2ViewsSecondFixed;
	}
	
	// see the NSSplitView_Mugginsoft category
	[sender resizeSubviewsWithOldSize:oldSize withBehaviour:behaviour minSizes:minWidthArray];
}

/*
 
 splitview constrain max position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	#pragma unused(offset)
	
	proposedMax = [sender frame].size.width - MIN_LEFT_SPLITVIEW_WIDTH - [sender dividerThickness];
			
	return proposedMax;
}
/*
 
 splitview constrain min position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	#pragma unused(sender)
	#pragma unused(offset)
	
	proposedMin = MIN_RIGHT_SPLITVIEW_WIDTH;
	
	return proposedMin;
}
@end
